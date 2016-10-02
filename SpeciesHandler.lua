-- species file -- 
-- en specifik ras, har hand om genomer som tillhör samma ras --
local SpeciesHandler = {}

local function newSpecies()
    local species = {}
    
    species.topFitness = 0          -- bästa fitness för denna ras --
    species.staleness = 0           -- ett värde på om rasen inte har förbättrats från tidigare generationer 0 = bra--
    species.genomes = {}             -- alla genomer för denna ras, alla olika sorts "hjärnor" i rasen --
    species.averageRank = 0      -- average fitness för rasen --

    return species
end

local function copySpecies(oldSpecies)
    local newSpecies = {}
    newSpecies.topFitness  = oldSpecies.topFitness
    newSpecies.staleness   = oldSpecies.staleness
    newSpecies.averageRank = oldSpecies.averageRank
    newSpecies.genomes     = {}

    for i=1, #oldSpecies.genomes do 
        table.insert(newSpecies.genomes, GenomeHandler.copyGenome(oldSpecies.genomes[i]))   
    end

    return newSpecies 
end

local function copyFullSpecies(oldSpecies)
    local newSpecies = {}
    newSpecies.topFitness  = oldSpecies.topFitness
    newSpecies.staleness   = oldSpecies.staleness
    newSpecies.averageRank = oldSpecies.averageRank
    newSpecies.genomes     = {}

    for i=1, #oldSpecies.genomes do 
        table.insert(newSpecies.genomes, GenomeHandler.copyFullGenome(oldSpecies.genomes[i]))   
    end

    return newSpecies 
end

-- Ska lägga till en genom till en ras
local function addGenomeToSpecies(species, genomeToAdd)
    local foundSpecies = false                          -- En boolean som kollar om vi lagt till den till en ras eller ej

    -- Loopa igenom alla raser för att finna om den nya genomen passar till någon
    for i=1, #species do
       -- local speciesGenome = species[i].genomes[1]                                                                     -- Hämtar hem första genomen i rasen, för jämnförelse                                                                                                                        
        if foundSpecies == false and GenomeHandler.compareGenomeSameSpecies(species[i].genomes[1], genomeToAdd)then    -- Om vi inte har hittat en ras och om genomen passar till denna rasen så lägg till den
            table.insert(species[i].genomes, genomeToAdd)
            foundSpecies = true;
        end
    end

    -- Om genomen inte passade till någon ras, skapa ny ras och lägga till genomen.
    if foundSpecies == false then
        local newSpecies = SpeciesHandler.newSpecies()
        table.insert(newSpecies.genomes, genomeToAdd)
        table.insert(species, newSpecies)
    end

end

local function removeStaleSpecies(pool)
    local keptSpecies = {}

    for i = 1, #pool.species do
        local currentSpecies = pool.species[i]

        table.sort(currentSpecies.genomes, function(a,b)
                        return a.fitness > b.fitness
                        end)
        --SpeciesHandler.printClass(currentSpecies)
        if currentSpecies.genomes[1].fitness > currentSpecies.topFitness then 
            currentSpecies.topFitness = currentSpecies.genomes[1].fitness
            currentSpecies.staleness = 0
        else 
            currentSpecies.staleness = currentSpecies.staleness + 1
        end

        if currentSpecies.staleness < STALE_SPECIES or currentSpecies.topFitness >= pool.maxFitness then
            table.insert(keptSpecies, currentSpecies)
        end
    end
    pool.species = keptSpecies
    --return keptSpecies
end

local function removeWeakSpecies(pool)
    
    local totalAvgRank = 0
    local keptSpecies = {}

    for i=1, #pool.species do
        pool.species[i].averageRank = SpeciesHandler.calculateAverageSpeciesRank(pool.species[i])
        totalAvgRank = totalAvgRank + pool.species[i].averageRank
    end

    --totalAvgRank = totalAvgRank / #pool.species

    --print(totalAvgRank)
    for i=1, #pool.species do 
        if (pool.species[i].averageRank / totalAvgRank * POPULATION) >= 1 then
            table.insert(keptSpecies, pool.species[i])
        end
    end

    pool.species = keptSpecies
    --return keptSpecies
end

local function createNewChildren(pool, newChildren)

    local summedAvgRank = 0
    --local children = {}

    for i = 1, #pool.species do
        summedAvgRank = summedAvgRank + pool.species[i].averageRank
    end

    for i = 1, #pool.species do
        local currentSpecies = pool.species[i]
        local numberOfNewChilds = math.floor(currentSpecies.averageRank / summedAvgRank * POPULATION) - 1
      --  print("number of childs for spieces " .. i .. ": " .. numberOfNewChilds)
        for j = 1, numberOfNewChilds do
            table.insert(newChildren, GenomeHandler.createNewChild(currentSpecies.genomes))
        end
    end

   --print("newChildren i slutet på createnewchildren " .. #newChildren)
    
    --return children
end


local function calculateAverageSpeciesRank(species)
    local sum = 0

    for i = 1, #species.genomes do
        sum = sum + species.genomes[i].globalRank
    end

    sum = sum / #species.genomes
    return sum
end

local function printClass(species) 
    print("    ---- Species ---- ")
    print("    number of genomes: " .. #species.genomes)
    print("    top fitness: " .. species.topFitness)
    print("    average fitness: " .. species.averageRank)
    print("    staleness: " .. species.staleness)
   -- GenomeHandler.printClass(genome)
end

-- binda functioner
SpeciesHandler.newSpecies = newSpecies
SpeciesHandler.copySpecies = copySpecies
SpeciesHandler.copyFullSpecies = copyFullSpecies
SpeciesHandler.addGenomeToSpecies = addGenomeToSpecies
SpeciesHandler.removeStaleSpecies = removeStaleSpecies
SpeciesHandler.removeWeakSpecies = removeWeakSpecies
SpeciesHandler.createNewChildren = createNewChildren
SpeciesHandler.calculateAverageSpeciesRank = calculateAverageSpeciesRank
SpeciesHandler.printClass = printClass

return SpeciesHandler