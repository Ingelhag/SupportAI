-- POOL FILE --
-- huvudhållakollare, håller koll på generationspoolen --

local PoolHandler = {}
lastInnovation = 6         -- vilket innvoationstal som vi är på, om de skapas en ny länk används detta tal --

local function newPool() 
    local pool = {}
    pool.species = {}           -- alla species för denna generation --
    pool.generation = 1         -- vilken generation vi är på för nuvarande --
    pool.currentSpecies = 1     -- nuvarande ras som testas --
    pool.currentGenome = 1      -- nuvarande genom som testas --
    pool.currentFrame = 0       -- vilken frame vi är på i emulationen --
    pool.maxFitness = 0         -- bästa värdet vi nånsin uppnåt -- 
    pool.maxGenerationFitness = 0
    return pool
end

local function copyPool(oldPool)

    local newPool = {}

    newPool.generation             = oldPool.generation
    newPool.currentSpecies         = oldPool.currentSpecies
    newPool.currentGenome          = oldPool.currentGenome
    newPool.currentFrame           = oldPool.currentFrame
    newPool.maxFitness             = oldPool.maxFitness
    newPool.maxGenerationFitness   = maxGenerationFitness

    newPool.species = {} 
    for i=1, #oldPool.species do 
        table.insert(newPool.species, SpeciesHandler.copySpecies(oldPool.species[i]))
    end

    return newPool
end

local function copyFullPool(oldPool)

    local newPool = {}

    newPool.generation             = oldPool.generation
    newPool.currentSpecies         = oldPool.currentSpecies
    newPool.currentGenome          = oldPool.currentGenome
    newPool.currentFrame           = oldPool.currentFrame
    newPool.maxFitness             = oldPool.maxFitness
    newPool.maxGenerationFitness   = maxGenerationFitness

    newPool.species = {} 
    for i=1, #oldPool.species do 
        table.insert(newPool.species, SpeciesHandler.copyFullSpecies(oldPool.species[i]))
    end

    return newPool
end



    -- Lägger massa startgenomer till raser som sedan läggs till i poolen --
local function generateStartPool(species)
    
    for i=1, POPULATION do
        local newGenome = GenomeHandler.basicGenome()
        SpeciesHandler.addGenomeToSpecies(species, newGenome)
    end

    -- Starta igång hela simulation
end

local function generateInnovationNumber()
    lastInnovation = lastInnovation + 1
    return lastInnovation
end

local function findNextGenome(pool)

    local currentSpecies = pool.species[pool.currentSpecies]
    local currentGenome = currentSpecies.genomes[pool.currentGenome+1]

    if currentGenome ~= nil then
        pool.currentGenome = pool.currentGenome+1
        return
    else
        currentSpecies = pool.species[pool.currentSpecies+1]
        if currentSpecies ~= nil then
            pool.currentGenome = 1
            pool.currentSpecies = pool.currentSpecies+1
            return
        else
            UtilHandler.writeJsonToFile(pool)
            print("skapa ny generations")
            pool.currentGenome = 1
            pool.currentSpecies = 1
            PoolHandler.createNewGeneration(pool)
        end
    end
end 

local function createNewGeneration(pool)

    local newChildren = {}

    GenomeHandler.removeWeakGenomes(pool.species, false)            -- skicka in false för att vi ska behålla hälften av alla genomer i varje ras

    PoolHandler.rankGenomesGlobally(pool)

    SpeciesHandler.removeStaleSpecies(pool)                         -- tar bort raser som inte förbättrat sig (riktiga)
    
    PoolHandler.rankGenomesGlobally(pool)                           -- ranka genomer globalt över hela generationen

    SpeciesHandler.removeWeakSpecies(pool)                          -- ta bort raser som inte är över medelfittness

    SpeciesHandler.createNewChildren(pool, newChildren)

   -- print("newchildren efter createNewChildren: " .. #newChildren)

    GenomeHandler.removeWeakGenomes(pool.species, true)             -- ta bort alla genomer förutom bästa genomen i rasen.

    GenomeHandler.fillUpNewChildren(pool.species, newChildren)      -- fyller upp new children med barn så att vi maxxar populationen i nästa generation

    --print("newchildren efter fillUpNewChildren: " .. #newChildren)

    for i = 1, #newChildren do
        SpeciesHandler.addGenomeToSpecies(pool.species, newChildren[i])
    end

    pool.generation = pool.generation + 1

-- rank genomes globally
-- remove stale species() -- ta bort raser som inte förbätttrats på X antal generationer
-- rank globally igen -- 
-- räkna ut avg fitness för varje ras
-- remove weakspecies()
-- börjar skapa barn 
-- breed children ()
-- lägg till nya barn


end

local function rankGenomesGlobally(pool)

    local ranked = {}

    for i = 1, #pool.species do
        for j = 1, #pool.species[i].genomes do
            table.insert(ranked, pool.species[i].genomes[j])
        end
    end

    table.sort(ranked, function(a, b) 
                    return a.fitness < b.fitness
                end)

    for i = 1, #ranked do
        ranked[i].globalRank = i
    end

end

local function printClass(pool) 
    print("")
    print("--- POOL ---- ")
    print("number of species: " .. #pool.species)
    print("current generation: " .. pool.generation)
    print("current species: " .. pool.currentSpecies)
    print("current genome: " .. pool.currentGenome)
    print("max fitness: " .. pool.maxFitness)
    print("innovation: " .. lastInnovation)
end

PoolHandler.newPool = newPool
PoolHandler.copyPool = copyPool
PoolHandler.copyFullPool = copyFullPool
PoolHandler.generateStartPool = generateStartPool
PoolHandler.generateInnovationNumber = generateInnovationNumber
PoolHandler.findNextGenome = findNextGenome
PoolHandler.createNewGeneration = createNewGeneration
PoolHandler.rankGenomesGlobally = rankGenomesGlobally
PoolHandler.printClass = printClass

return PoolHandler;
