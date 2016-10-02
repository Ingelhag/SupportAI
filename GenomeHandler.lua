-- genome file --
-- en genome är ett helt nätverk med neuroner, länkar och nätverkshanterare --

local GenomeHandler = {}

local function newGenome()
    local genome = {}
    
    genome.links = {}           -- alla länkar mellan neuronerna
    genome.fitness = 0          -- värde på hur bra genomen är 
    genome.network = {}         -- nätverkHanterare för alla kopplingar mellan neuroner
    genome.maxNeuron = 0        -- max antal neuroner
    genome.globalRank = 0       -- en global rank över alla genomer för en generation
    genome.mutationRates = {}
    genome.mutationRates["mutateConnectionChance"]  = MUTATE_CONNECTIONS_CHANCE           -- sannolikhet för att vi skall försöka ändra vikten på en länk --
    genome.mutationRates["linkMutationChance"]      = LINK_MUTATION_CHANCE                -- sannolikhet för att en ny länk skall skapas mellan två noder -- 
    genome.mutationRates["biasMutationChance"]      = BIAS_MUTATION_CHANCE                -- sannolikhet för att en länk skall skapas mellan den sista input-noden och en random-nod -- 
    genome.mutationRates["nodeMutationChance"]      = NODE_MUTATION_CHANCE                -- sannolikhet för att en länk skall bli två med olika vikter --
    genome.mutationRates["disableMutationChance"]   = DISBALE_MUTATION_CHANCE             -- sannolikhet för att en länk skall blir inaktiv som är aktiv just nu och inte användas i simulationen --
    genome.mutationRates["enableMutationChance"]    = ENABLE_MUTATION_CHANCE 

    return genome
end

-- Skapar en basic ganom och muterar den. Anropas bara när vi skapar den nya poolen.
local function basicGenome()      
    local genome = newGenome()

    genome.maxNeuron = NUM_OF_INPUTS

    GenomeHandler.mutateGenome(genome) -- Muterar vår genome; ändrar länkar, vikter, om den är aktiv ..
   
    return genome
end

local function copyGenome(oldGenome)
    local genome = GenomeHandler.newGenome()

    for i = 1, #oldGenome.links do
        table.insert(genome.links, LinkHandler.copyLink(oldGenome.links[i]))
    end

    genome.mutationRates["mutateConnectionChance"]  = oldGenome.mutationRates["mutateConnectionChance"]  
    genome.mutationRates["linkMutationChance"]      = oldGenome.mutationRates["linkMutationChance"]      
    genome.mutationRates["biasMutationChance"]      = oldGenome.mutationRates["biasMutationChance"]      
    genome.mutationRates["nodeMutationChance"]      = oldGenome.mutationRates["nodeMutationChance"]      
    genome.mutationRates["disableMutationChance"]   = oldGenome.mutationRates["disableMutationChance"]   
    genome.mutationRates["enableMutationChance"]    = oldGenome.mutationRates["enableMutationChance"]    

    return genome
end

local function copyFullGenome(oldGenome)
       -- GenomeHandler.printClass(oldGenome)
    local genome = GenomeHandler.newGenome()

    for i = 1, #oldGenome.links do
        table.insert(genome.links, LinkHandler.copyLink(oldGenome.links[i]))
    end
--[[
    for i = 1, #oldGenome.network do
        table.insert(genome.network, NetworkHandler.copyNetwork(oldGenome.network))
    end
]]--
    genome.network = NetworkHandler.copyNetwork(oldGenome.network)
    --print("size of newGenome network: " .. #genome.network)
   -- NetworkHandler.printClass(oldGenome.network)

    genome.mutationRates["mutateConnectionChance"]  = oldGenome.mutationRates["mutateConnectionChance"]  
    genome.mutationRates["linkMutationChance"]      = oldGenome.mutationRates["linkMutationChance"]      
    genome.mutationRates["biasMutationChance"]      = oldGenome.mutationRates["biasMutationChance"]      
    genome.mutationRates["nodeMutationChance"]      = oldGenome.mutationRates["nodeMutationChance"]      
    genome.mutationRates["disableMutationChance"]   = oldGenome.mutationRates["disableMutationChance"]   
    genome.mutationRates["enableMutationChance"]    = oldGenome.mutationRates["enableMutationChance"]    

    return genome
end 

local function mutateGenome(genome)
    -- Ändrar alla mutateRates med +/- 5%
    for mutation, rate in pairs(genome.mutationRates) do 
        if math.random() > 0.5 then
            genome.mutationRates[mutation] =  1.05 * rate; 
        else 
            genome.mutationRates[mutation] =  0.95 * rate; 
        end
    end

    -- Whilelooparna gör så om konstanterna är högre än ett är det garanterat att dessa görs minst en gång --

    local connectionChanceRate = genome.mutationRates["mutateConnectionChance"]
    while connectionChanceRate > 0 do
        if math.random() < connectionChanceRate then
            GenomeHandler.linkWeightMutate(genome, false)
        end
        connectionChanceRate = connectionChanceRate - 1
    end 

    local linkRate = genome.mutationRates["linkMutationChance"]
    while linkRate > 0 do
        if math.random() < linkRate then
            GenomeHandler.linkMutate(genome, false)
        end
        linkRate = linkRate - 1
    end 

    local biasRate = genome.mutationRates["biasMutationChance"]
    while biasRate > 0 do
        if math.random() < biasRate then
            GenomeHandler.linkMutate(genome, true)
        end
        biasRate = biasRate - 1
    end 

    local nodeRate = genome.mutationRates["nodeMutationChance"]
    while nodeRate > 0 do
        if math.random() < nodeRate then
            LinkHandler.addNodeMutate(genome)
        end
        nodeRate = nodeRate - 1
    end

    local enableRate = genome.mutationRates["enableMutationChance"]
    while enableRate > 0 do
        if math.random() < enableRate then
            LinkHandler.EnableDisableMutate(genome.links, true);
        end
        enableRate = enableRate - 1
    end

    local disableRate = genome.mutationRates["disableMutationChance"]
    while disableRate > 0 do 
        if math.random() < disableRate then
            LinkHandler.EnableDisableMutate(genome.links, false)
        end
        disableRate = disableRate - 1
    end
end

local function linkWeightMutate(genome)
    for i=1, #genome.links do
        if math.random() < PETURB_CHANCE then
            genome.links[i].weight = genome.links[i].weight + math.random() * STEP_SIZE * 2 - STEP_SIZE  --- ÄNDRA DENNA KANSKE? LÄS ARTIKEL
        else
            genome.links[i].weight = math.random() * 4 - 2
        end
    end
end

local function linkMutate(genome, setLastInputAsInput)
    local neuronPosition1 = LinkHandler.getRandomNeuron(genome.links, true)      -- Kan vara en input
    local neuronPosition2 = LinkHandler.getRandomNeuron(genome.links, false)     -- Kan inte vara en en input

    local newLink = LinkHandler.newLink()
    newLink.into = neuronPosition1                                              -- sätt den nya länkens into till den första randomNeuronen 
    newLink.out = neuronPosition2                                               -- sätt den nya länkens out till den andra neuronen (ej inputnod)

    if setLastInputAsInput then                                                 -- om bias sätt into till sista input noden
        newLink.into = NUM_OF_INPUTS
    end

    -- Kolla så att inte den nya länken redan existerar bland de andra
    if LinkHandler.linkAllreadyExists(genome.links, newLink) then
        return
    end

    newLink.innovation = PoolHandler.generateInnovationNumber()             -- generera ett nytt innovationsnummer för länken
    newLink.weight = math.random()*4-2

    table.insert(genome.links, newLink)                                     -- lägg in länken
end


-- Kollar om genom1 och genom2 kan klassas som samma ras
local function compareGenomeSameSpecies(genome1, genome2)

    local deltaDisjointAndExcessLinks = GenomeHandler.findDisjointsAndExcess(genome1, genome2)
    local deltaWeight = DELTA_WEIGHTS*GenomeHandler.weightDifference(genome1, genome2)


    return deltaDisjointAndExcessLinks + deltaWeight < DELTA_THRESHOLD
end

-- Hittar disjoints mellan de olika genomernas länkar
local function findDisjointsAndExcess(genome1, genome2)
    local links1 = {}           -- Länkarna för genome1
    local links2 = {}           -- Länkarna för genome2
    local disjoints = 0         -- Antalet disjoints
    local excess = 0         -- Antalet disjoints



    -- Loppa igenom genomes 1 länkar och sätter att det finns en länk med indexet - innovationsnumret
    for i=1, #genome1.links do
        links1[genome1.links[i].innovation] = true
    end

    -- Loppa igenom genomes 2 länkar och sätter att det finns en länk med indexet - innovationsnumret
    for i=1, #genome2.links do
        links2[genome2.links[i].innovation] = true
    end

    -- Loopa igenom genomes1 länkar och kollar om det finns en med samma innovationsnummer bland genomes 2 länkar, om inte inkrementera disjoints
    for i=1, #genome1.links do
        if links2[genome1.links[i].innovation] ~= true then
            if genome1.links[i].innovation > #links2 then
                excess = excess + 1
            else
                disjoints = disjoints + 1
            end
        end 
    end

    -- Loopa igenom genomes1 länkar och kollar om det finns en med samma innovationsnummer bland genomes 2 länkar, om inte inkrementera disjoints
    for i=1, #genome2.links do
        if links1[genome2.links[i].innovation] ~= true then
            if genome2.links[i].innovation > #links1 then
                excess = excess + 1
            else
                disjoints = disjoints + 1
            end
        end
    end

    -- Retunera en procentuell likhet bland genomernas länkar.
    return (DELTA_DISJOINT*disjoints / math.max(#genome1.links, #genome2.links)) + (DELTA_EXCESS*excess/ math.max(#genome1.links, #genome2.links))
end

-- Jämnför genome1 och genome2s länkars vikter
local function weightDifference(genome1, genome2)
    local links2 = {}
    local weightDifference = 0.0
    local counter = 0

    -- Loopa igenom genomes2s länkar och kopiera in länken med index innovation
    for i=1, #genome2.links do
        links2[genome2.links[i].innovation] = genome2.links[i]
    end

    -- Loopa igenom genome1:s länkar och kolla om samma innovationstal finns bland genomes2:s länkar
    for i=1, #genome1.links do
        local link1 = genome1.links[i]

        -- Om det finns motsvarande så ta ut skillanden i vikter och addera weightDifference samt inkremetera countern
        if links2[link1.innovation] ~= nil then 
            weightDifference = weightDifference + math.abs(link1.weight - links2[link1.innovation].weight)
            counter = counter + 1 
        end
    end

    -- Skicka tillbaka någonslags skillnad mellan viktskillanden och antal fall så det finns samma innovationstal.
    return weightDifference / counter

end

local function generateNetwork(genome)
   -- local newNetwork = NetworkHandler.newNetwork()
    local newNetwork = {}
    newNetwork.neurons = {}
    -- Lägger till inputnoder --
    for i=1, NUM_OF_INPUTS do
        newNetwork.neurons[i] = NeuronHandler.newNeuron()
    end

    -- Lägger till outputnoder --
    for i=1, NUM_OF_OUTPUTS do
        newNetwork.neurons[i+MAX_NODES] = NeuronHandler.newNeuron()
    end
   -- NeuronHandler.printClass(newNetwork.neurons[6+MAX_NODES])
   
    -- Sortera våra gener 
    table.sort(genome.links, function (a,b)
        return (a.out < b.out)
    end)

    -- Fylla upp genomen med neuroner till alla kopplingar(länkar)
    for i=1, #genome.links do
        if genome.links[i].enabled then
            -- Fyller så att länkarna har en ut neuron
            if newNetwork.neurons[genome.links[i].out] == nil then
                newNetwork.neurons[genome.links[i].out] = NeuronHandler.newNeuron()
            end

            local neuron = newNetwork.neurons[genome.links[i].out]
           table.insert(neuron.incommingLinks, genome.links[i]) -- Lägger till länken bland våra incommings

            -- Fyller på närverket med neuroner för ingående
            if newNetwork.neurons[genome.links[i].into] == nil then
                newNetwork.neurons[genome.links[i].into] = NeuronHandler.newNeuron()
            end
        end
    end
    genome.network = newNetwork
end

local function removeWeakGenomes(species, onlyKeepBestGenome)
    local genomesToKeep

    for i=1, #species do
        if onlyKeepBestGenome == true then
            genomesToKeep = 1
        else
            genomesToKeep = math.ceil(#species[i].genomes / 2)
        end

        table.sort(species[i].genomes, function(a, b)
                    return a.fitness > b.fitness
                    end)
        
        while #species[i].genomes > genomesToKeep do
            table.remove(species[i].genomes)
        end
    end
end

local function createNewChild(genomes)
        
    local child = {}
    local random1 = 0
    local random2 = 0

   -- GenomeHandler.printClass(genomes[1])

    if #genomes == 1 then
        random1 = 1
        random2 = 1
    else
        random1 = math.random(1, #genomes)
        random2 = math.random(1, #genomes)
    end

    if math.random() < CROSSOVER_CHANCE then
        local mom = genomes[random1]
        local dad = genomes[random2]
        child = GenomeHandler.initializeLoveMaking(mom, dad)
    else
        local dad = genomes[random1]
        child = GenomeHandler.copyGenome(dad)
    end

    GenomeHandler.mutateGenome(child)

    return child
    
end

local function initializeLoveMaking(mom, dad)

    local newGenome = newGenome()

    if mom.fitness > dad.fitness then
        local temp = mom
        mom = dad
        dad = temp
    end

    local momInnovations = {}
    for i = 1, #mom.links do
        momInnovations[mom.links[i].innovation] = mom.links[i]
    end

    for i = 1, #dad.links do
        local dadLink = dad.links[i]
        local momLink = momInnovations[dadLink.innovation]

        if momLink ~= nil and math.random() < 0.5 and momLink.enabled then
            table.insert(newGenome.links, LinkHandler.copyLink(momLink))
        else 
            table.insert(newGenome.links, LinkHandler.copyLink(dadLink))
        end
    end

    newGenome.maxNeuron = math.max(dad.maxNeuron, mom.maxNeuron)

    for mutation, rate in pairs(dad.mutationRates) do
        newGenome.mutationRates[mutation] = rate
    end

    return newGenome
end

local function fillUpNewChildren(species, newChildren)
    while #species + #newChildren < POPULATION do
        table.insert(newChildren, GenomeHandler.createNewChild(species[math.random(1, #species)].genomes))
        
    end
end

local function printClass(genome) 
    print("        ---- Genome ---- ")
    print("        Number of links: " .. #genome.links)
    print("        Fitness: " .. genome.fitness)
    print("        Global Rank: " .. genome.globalRank)
    print("        Max neurons: " .. genome.maxNeuron)
    if #genome.network.neurons > 0 then
        print("        Network: Exists")
    else 
        print("        Network: NOPE")
    end
end


-- bind functions
GenomeHandler.newGenome = newGenome
GenomeHandler.basicGenome = basicGenome
GenomeHandler.copyGenome = copyGenome
GenomeHandler.copyFullGenome = copyFullGenome

GenomeHandler.mutateGenome = mutateGenome
GenomeHandler.linkWeightMutate = linkWeightMutate
GenomeHandler.linkMutate = linkMutate

GenomeHandler.compareGenomeSameSpecies = compareGenomeSameSpecies
GenomeHandler.findDisjointsAndExcess = findDisjointsAndExcess
GenomeHandler.weightDifference = weightDifference

GenomeHandler.generateNetwork = generateNetwork

GenomeHandler.removeWeakGenomes = removeWeakGenomes
GenomeHandler.createNewChild = createNewChild
GenomeHandler.initializeLoveMaking = initializeLoveMaking
GenomeHandler.fillUpNewChildren = fillUpNewChildren

GenomeHandler.printClass = printClass

return GenomeHandler