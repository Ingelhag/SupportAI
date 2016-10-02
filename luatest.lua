-- MarI/O by SethBling
-- Feel free to use this code, but please do not redistribute it.
-- Intended for use with the BizHawk emulator and Super Mario World or Super Mario Bros. ROM.
-- For SMW, make sure you have a save state named "DP1.state" at the beginning of a level,
-- and put a copy in both the Lua folder and the root directory of BizHawk.

-- definera möjliga outputs
if gameinfo.getromname() == "Super Mario World (USA)" then
    Filename = "DP1.state"
    ButtonNames = {
        "A",
        "B",
        "X",
        "Y",
        "Up",
        "Down",
        "Left",
        "Right",
    }
elseif gameinfo.getromname() == "Super Mario Bros." then
    Filename = "SMB1-1.state"
    ButtonNames = {
        "A",
        "B",
        "Up",
        "Down",
        "Left",
        "Right",
    }
end


BoxRadius = 6
InputSize = (BoxRadius*2+1)*(BoxRadius*2+1)

Inputs = InputSize+1
Outputs = #ButtonNames

Population = 300
DeltaDisjoint = 2.0
DeltaWeights = 0.4
DeltaThreshold = 1.0

StaleSpecies = 15

MutateConnectionsChance = 0.25
PerturbChance = 0.90
CrossoverChance = 0.75
LinkMutationChance = 2.0
NodeMutationChance = 0.50
BiasMutationChance = 0.40
StepSize = 0.1
DisableMutationChance = 0.4
EnableMutationChance = 0.2

TimeoutConstant = 20

MaxNodes = 1000000

function getPositions()
    if gameinfo.getromname() == "Super Mario World (USA)" then
        marioX = memory.read_s16_le(0x94)
        marioY = memory.read_s16_le(0x96)
        
        local layer1x = memory.read_s16_le(0x1A);
        local layer1y = memory.read_s16_le(0x1C);
        
        screenX = marioX-layer1x
        screenY = marioY-layer1y
    elseif gameinfo.getromname() == "Super Mario Bros." then
        marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
        marioY = memory.readbyte(0x03B8)+16
    
        screenX = memory.readbyte(0x03AD)
        screenY = memory.readbyte(0x03B8)
    end
end
-- kan vi interagera med tilen eller ej? 1 för ja 0 för nej
function getTile(dx, dy)
    if gameinfo.getromname() == "Super Mario World (USA)" then
        x = math.floor((marioX+dx+8)/16)
        y = math.floor((marioY+dy)/16)
        
        return memory.readbyte(0x1C800 + math.floor(x/0x10)*0x1B0 + y*0x10 + x%0x10)
    elseif gameinfo.getromname() == "Super Mario Bros." then
        local x = marioX + dx + 8                         -- vi får position där mario är 
        local y = marioY + dy - 16                        -- vi position 
        local page = math.floor(x/256)%2

        local subx = math.floor((x%256)/16)
        local suby = math.floor((y - 32)/16)
        local addr = 0x500 + page*13*16+suby*16+subx
        
        if suby >= 13 or suby < 0 then
            return 0
        end
        
        if memory.readbyte(addr) ~= 0 then
            return 1
        else
            return 0
        end
    end
end

function getSprites()
    if gameinfo.getromname() == "Super Mario World (USA)" then
        local sprites = {}
        for slot=0,11 do
            local status = memory.readbyte(0x14C8+slot)
            if status ~= 0 then
                spritex = memory.readbyte(0xE4+slot) + memory.readbyte(0x14E0+slot)*256
                spritey = memory.readbyte(0xD8+slot) + memory.readbyte(0x14D4+slot)*256
                sprites[#sprites+1] = {["x"]=spritex, ["y"]=spritey}
            end
        end     
        
        return sprites
    elseif gameinfo.getromname() == "Super Mario Bros." then
        local sprites = {}
        for slot=0,4 do
            local enemy = memory.readbyte(0xF+slot)
            if enemy ~= 0 then
                local ex = memory.readbyte(0x6E + slot)*0x100 + memory.readbyte(0x87+slot) -- 
                local ey = memory.readbyte(0xCF + slot)+24
                sprites[#sprites+1] = {["x"]=ex,["y"]=ey}
            end
        end
        
        return sprites
    end
end

function getExtendedSprites()
    if gameinfo.getromname() == "Super Mario World (USA)" then
        local extended = {}
        for slot=0,11 do
            local number = memory.readbyte(0x170B+slot)
            if number ~= 0 then
                spritex = memory.readbyte(0x171F+slot) + memory.readbyte(0x1733+slot)*256
                spritey = memory.readbyte(0x1715+slot) + memory.readbyte(0x1729+slot)*256
                extended[#extended+1] = {["x"]=spritex, ["y"]=spritey}
            end
        end     
        
        return extended
    elseif gameinfo.getromname() == "Super Mario Bros." then
        return {}
    end
end

function getInputs()  -- kallas ifrån evalutecurrent
    getPositions()
    
    sprites = getSprites()                -- hämta positioner för fiendesprites och lägg i array
    extended = getExtendedSprites()       -- Gör inget för oss atm
    
    local inputs = {}                      -- 
    
    for dy=-BoxRadius*16,BoxRadius*16,16 do        -- loopa från -boxradius*16 till boxradius*16, med 16hopp
        for dx=-BoxRadius*16,BoxRadius*16,16 do     -- loopa från -boxradius till boxradies*16 med 16steg
            inputs[#inputs+1] = 0                   -- LUA RÄKNAR FRÅN 1!!!!!!! skapa nytt element och sätt de till 0
            
            tile = getTile(dx, dy)                    --  kolla om current tile går att interagera med om det är 1 så går det
            if tile == 1 and marioY+dy < 0x1B0 then   -- om tilen är 1 dvs går interagera emd 
                inputs[#inputs] = 1                  -- sätt input till 1
            end
            
            for i = 1,#sprites do
                distx = math.abs(sprites[i]["x"] - (marioX+dx))
                disty = math.abs(sprites[i]["y"] - (marioY+dy))
                if distx <= 8 and disty <= 8 then
                    inputs[#inputs] = -1                        -- sätt input till -1 ifall det ä en fiende
                end
            end

            for i = 1,#extended do
                distx = math.abs(extended[i]["x"] - (marioX+dx))
                disty = math.abs(extended[i]["y"] - (marioY+dy))
                if distx < 8 and disty < 8 then
                    inputs[#inputs] = -1
                end
            end
        end
    end
    
    --mariovx = memory.read_s8(0x7B)
    --mariovy = memory.read_s8(0x7D)
    
    return inputs
end

function sigmoid(x)
    return 2/(1+math.exp(-4.9*x))-1
end

function newInnovation()
    pool.innovation = pool.innovation + 1
    return pool.innovation
end

function newPool()
    local pool = {}
    pool.species = {}
    pool.generation = 0
    pool.innovation = Outputs
    pool.currentSpecies = 1
    pool.currentGenome = 1
    pool.currentFrame = 0
    pool.maxFitness = 0
    
    return pool
end

function newSpecies()
    local species = {}
    species.topFitness = 0
    species.staleness = 0
    species.genomes = {}
    species.averageFitness = 0
    
    return species
end

function newGenome()
    local genome = {}
    genome.genes = {}
    genome.fitness = 0
    genome.adjustedFitness = 0
    genome.network = {}
    genome.maxneuron = 0
    genome.globalRank = 0
    genome.mutationRates = {}
    genome.mutationRates["connections"] = MutateConnectionsChance
    genome.mutationRates["link"] = LinkMutationChance
    genome.mutationRates["bias"] = BiasMutationChance
    genome.mutationRates["node"] = NodeMutationChance
    genome.mutationRates["enable"] = EnableMutationChance
    genome.mutationRates["disable"] = DisableMutationChance
    genome.mutationRates["step"] = StepSize
    
    return genome
end

function copyGenome(genome)
    local genome2 = newGenome()
    for g=1,#genome.genes do
        table.insert(genome2.genes, copyGene(genome.genes[g]))
    end
    genome2.maxneuron = genome.maxneuron
    genome2.mutationRates["connections"] = genome.mutationRates["connections"]
    genome2.mutationRates["link"] = genome.mutationRates["link"]
    genome2.mutationRates["bias"] = genome.mutationRates["bias"]
    genome2.mutationRates["node"] = genome.mutationRates["node"]
    genome2.mutationRates["enable"] = genome.mutationRates["enable"]
    genome2.mutationRates["disable"] = genome.mutationRates["disable"]
    
    return genome2
end

function basicGenome()
    local genome = newGenome()
    local innovation = 1

    genome.maxneuron = Inputs
    mutate(genome)
    
    return genome
end

function newGene()
    local gene = {}
    gene.into = 0
    gene.out = 0
    gene.weight = 0.0
    gene.enabled = true
    gene.innovation = 0
    
    return gene
end

function copyGene(gene)
    local gene2 = newGene()
    gene2.into = gene.into
    gene2.out = gene.out
    gene2.weight = gene.weight
    gene2.enabled = gene.enabled
    gene2.innovation = gene.innovation
    
    return gene2
end

function newNeuron()
    local neuron = {}
    neuron.incoming = {}
    neuron.value = 0.0
    
    return neuron
end

function generateNetwork(genome)
    local network = {}
    network.neurons = {}
    
    for i=1,Inputs do                       -- sätt de första neuronerna i nätverket som inputs
        network.neurons[i] = newNeuron()
    end
    
    for o=1,Outputs do                          -- de sista neurorna i nätverket = outputs
        network.neurons[MaxNodes+o] = newNeuron()
    end
    
    table.sort(genome.genes, function (a,b)
        return (a.out < b.out)
    end)
    for i=1,#genome.genes do
        local gene = genome.genes[i]
        if gene.enabled then
            if network.neurons[gene.out] == nil then
                network.neurons[gene.out] = newNeuron()
            end
            local neuron = network.neurons[gene.out]
            table.insert(neuron.incoming, gene)
            if network.neurons[gene.into] == nil then
                network.neurons[gene.into] = newNeuron()
            end
        end
    end
    
    genome.network = network
end

function evaluateNetwork(network, inputs)
    table.insert(inputs, 1)
    if #inputs ~= Inputs then
        console.writeline("Incorrect number of neural network inputs.")
        return {}
    end
    
    ----------------------------------------------------
    for i=1,Inputs do
        network.neurons[i].value = inputs[i] -- Sätter inputvärdet"
    end
    

    ----------------------------------------------------

    for _,neuron in pairs(network.neurons) do
        local sum = 0
        for j = 1,#neuron.incoming do
            local incoming = neuron.incoming[j]                 -- Hämta alla incommings för en neuron (gener)
            local other = network.neurons[incoming.into]        -- Hämta rätt neuron 
            sum = sum + incoming.weight * other.value           -- Summera ihop med vikten
        end
        
        if #neuron.incoming > 0 then
            neuron.value = sigmoid(sum)                         -- Loopa igenom alla neuroner och gör en sigmoid funktion
        end
    end
    
    ----------------------------------------------------
    -- GÅr igenom alla outports
    local outputs = {}
    for o=1,Outputs do
        local button = "P1 " .. ButtonNames[o]
        if network.neurons[MaxNodes+o].value > 0 then           -- Om värdet på neuronen är större än noll -> tryck på knappen!
            outputs[button] = true
        else
            outputs[button] = false                             -- Annars så ska knappen inte trycka!
        end
    end
    

    ----------------------------------------------------

    return Outputs                                              -- Skicka tillbaka antalet outpus!
end

function crossover(g1, g2)
    -- Make sure g1 is the higher fitness genome
    if g2.fitness > g1.fitness then             -- om g2 har bättre fitness än g1 make a swap g1 och g2
        tempg = g1
        g1 = g2
        g2 = tempg
    end

    local child = newGenome()                   -- skapar nyd genome som ska bli vårt nya barn
    
    local innovations2 = {}                     
    for i=1,#g2.genes do                        -- loopa igenom alla g2:S gener
        local gene = g2.genes[i]                -- 
        innovations2[gene.innovation] = gene    -- lägger in generna från g2 med indexet som är innovation
    end
    
    for i=1,#g1.genes do                                                -- Loppa igenom g1:S gener
        local gene1 = g1.genes[i]                                       -- Plocka ut gen från g1
        local gene2 = innovations2[gene1.innovation]                    -- PLocka ut samma innovationstal som den genen i g1
        if gene2 ~= nil and math.random(2) == 1 and gene2.enabled then  -- Om genen med samma innovationstal finns, och chans på 50% och och att genen äraktiv
            table.insert(child.genes, copyGene(gene2))                  -- LÄgg till den genen i vårat barn
        else
            table.insert(child.genes, copyGene(gene1))                  -- Annars lägger vi till gen ett i vårt barn
        end
    end
    
    child.maxneuron = math.max(g1.maxneuron,g2.maxneuron)               -- Får ut inten maxantaletneuronere, lägger till i vårt barn
    
    for mutation,rate in pairs(g1.mutationRates) do                     -- loopar igenom vår g1:s mutationrates
        child.mutationRates[mutation] = rate                            -- VÅrt barn får då samma rates som g1
    end
    
    return child                                                        -- Retunerar den nya barnet!
end

function randomNeuron(genes, nonInput) -- nonInput - false (inputnod)
    local neurons = {}                                      -- Skapa ett tomt rable med neuroner
    if not nonInput then                                    -- Om det är en inputnod
        for i=1,Inputs do                                   -- Loopar igenpm antalet inputs
            neurons[i] = true                               -- Sätte dessa platese till true
        end
    end
    for o=1,Outputs do                                      -- Loopar igenom alla outputs
        neurons[MaxNodes+o] = true                          -- Sätter alla outputsplatser till true
    end
    for i=1,#genes do                                       -- Loopa igenom alla gener
        if (not nonInput) or genes[i].into > Inputs then    -- Om det är en inputnod eller är en hiddenlayer nod 
            neurons[genes[i].into] = true                   -- neuronen med index med genens into finns
        end
        if (not nonInput) or genes[i].out > Inputs then     -- om de är inputnod eller hiddenlayer nod
            neurons[genes[i].out] = true                    -- så finns det en mottagnde nod på denna plats
        end
    end

    local count = 0                     -- Kolla hur många nueroner som finns i den nyskapade neurons
    for _,_ in pairs(neurons) do
        count = count + 1
    end
    
    local n = math.random(1, count)     -- Ta ut en randompoisition mellan 1 - antal neuroner
    
    for k,v in pairs(neurons) do        -- Hämta neuronen på denna position och skicka tillbaka
        n = n-1
        if n == 0 then
            return k
        end
    end
    
    return 0
end

function containsLink(genes, link)                                      -- Tar en genen och länken
    for i=1,#genes do                                                   -- Går igenom alla länkar, den nya länken redan existerar ...
        local gene = genes[i]
        if gene.into == link.into and gene.out == link.out then
            return true
        end
    end
end

function pointMutate(genome)
    local step = genome.mutationRates["step"]                           -- Tar ut stepSize
    
    for i=1,#genome.genes do                                            -- Loopa igenom alla gener för genomen
        local gene = genome.genes[i]
        if math.random() < PerturbChance then                           -- Kolla random mot rubbningskonstanten (90% chans)
            gene.weight = gene.weight + math.random() * step*2 - step   -- Ändrar genens vikt (Vikten) * random * step * 2 - step
        else
            gene.weight = math.random()*4-2                             -- Slumpar en helt ny vikt
        end
    end
end

function linkMutate(genome, forceBias)
    local neuron1 = randomNeuron(genome.genes, false)       -- Fram två randomNeuroner, Denna kam vara en input-nod
    local neuron2 = randomNeuron(genome.genes, true)        -- Denna är garanterad att nte vara en input
     
    local newLink = newGene()                               -- Skapar en ny Gen

    if neuron1 <= Inputs and neuron2 <= Inputs then         -- Gör en check så att det inte är två input, viket inte borde ha hänt
        --Both input nodes
        return
    end

    if neuron2 <= Inputs then                               -- Om neuron två är input, som inte borde kunna ske, swapa med neuron 1
        -- Swap output and input
        local temp = neuron1
        neuron1 = neuron2
        neuron2 = temp
    end

    newLink.into = neuron1                                  -- Nya länkens into är neuron1
    newLink.out = neuron2                                   -- Nya länkens out är neuron2
    if forceBias then                                       -- Om vi kör BIAS
        newLink.into = Inputs                               -- Sätter den nya länkes into till dden sista Inputnoden
    end
    
    if containsLink(genome.genes, newLink) then             -- Om den redan exisrerar - retunera från linkMutate
        return
    end

    newLink.innovation = newInnovation()                    -- SÄtte en ny innovation till länken(genen)
    newLink.weight = math.random()*4-2                      -- Sätter en ny vikt som är randomtal*4 - 2
    
    table.insert(genome.genes, newLink)                     -- LÄgger till den nya länken bland våra gener(länkar)
end

function nodeMutate(genome)
    if #genome.genes == 0 then                              -- Kollar så vi har gener, om inte så return!
        return
    end

    genome.maxneuron = genome.maxneuron + 1                 -- Adderar ett till maxneuronerna

    local gene = genome.genes[math.random(1,#genome.genes)] -- tar en randomgen bland exsterande
    if not gene.enabled then                                -- Om genen är disable - > retuerna
        return
    end
    gene.enabled = false                                     -- Sätter enable till false
    
    local gene1 = copyGene(gene)                             -- Kopiera genen tll en ny gen
    gene1.out = genome.maxneuron                             -- Sätter out till maxneuroner
    gene1.weight = 1.0                                       -- Sätter vikt, innovation och enable
    gene1.innovation = newInnovation()
    gene1.enabled = true
    table.insert(genome.genes, gene1)                        -- Lägger till genen
    
    local gene2 = copyGene(gene)                             -- Kopierar genen igen
    gene2.into = genome.maxneuron                            -- Ändrar into till maxneuron
    gene2.innovation = newInnovation()                       -- Sätter en ny innova5ion
    gene2.enabled = true
    table.insert(genome.genes, gene2)                        -- Lägger till genen(länken)
end

function enableDisableMutate(genome, enable)                -- 
    local candidates = {}                                   -- Skapa tom table candidates
    for _,gene in pairs(genome.genes) do                    -- Får igenom alla gener för genomen
        if gene.enabled == not enable then                  -- Om de skiljer sig
            table.insert(candidates, gene)                  -- LÄgg till genen bland våra kanidater
        end
    end
    
    if #candidates == 0 then                                -- Om kanidaterna är tom så avslutar vi
        return
    end
    
    local gene = candidates[math.random(1,#candidates)]     -- Plockar en randomgen från våra kandidater
    gene.enabled = not gene.enabled                         -- Tar byter enable value
end

function mutate(genome)
    for mutation,rate in pairs(genome.mutationRates) do         -- Loopar igenom alla mutationsrates
        if math.random(1,2) == 1 then                           -- Ändrar i bland våra mutationrates med +/- 5%
            genome.mutationRates[mutation] = 0.95*rate
        else
            genome.mutationRates[mutation] = 1.05263*rate
        end
    end

    if math.random() < genome.mutationRates["connections"] then     -- Om ett randomtal än mindre än genomens mutationsrastes:connection
        pointMutate(genome)                                         -- Kör en pointMutate med genomen
    end
    
    local p = genome.mutationRates["link"]                          -- Hämtar LINK-raten
    while p > 0 do                                                  -- Så länge linkraten är större än noll
        if math.random() < p then                                   -- om random är mindre än vår linkrate
            linkMutate(genome, false) 
        end
        p = p - 1
    end

    p = genome.mutationRates["bias"]
    while p > 0 do
        if math.random() < p then
            linkMutate(genome, true)
        end
        p = p - 1
    end
    
    p = genome.mutationRates["node"]
    while p > 0 do
        if math.random() < p then
            nodeMutate(genome)
        end
        p = p - 1
    end
    
    p = genome.mutationRates["enable"]
    while p > 0 do
        if math.random() < p then
            enableDisableMutate(genome, true)
        end
        p = p - 1
    end

    p = genome.mutationRates["disable"]
    while p > 0 do
        if math.random() < p then
            enableDisableMutate(genome, false)
        end
        p = p - 1
    end
end

function disjoint(genes1, genes2)
    local i1 = {}                       -- En tom array
    for i = 1,#genes1 do                -- Loopar igenom gen 1
        local gene = genes1[i]          -- Hämtar en gen
        i1[gene.innovation] = true      -- Lägger in genen i i1 med index innovatonsnumret och sätter denna till true
    end

    local i2 = {}                       -- En tom array
    for i = 1,#genes2 do                -- Går igenom alla gen 2
        local gene = genes2[i]          -- Hämtar en specifik gen
        i2[gene.innovation] = true      -- Lägger in denna genen i i2 med indexet inovationsnummret, sätter denna till true
    end
    
    local disjointGenes = 0                 -- 
    for i = 1,#genes1 do                    -- Går igneom alla gener i gen1
        local gene = genes1[i]              -- Hämtar en specifik gen
        if not i2[gene.innovation] then     -- Om dess generation inte finns i i2. pluss på disjoinGenes med ett
            disjointGenes = disjointGenes+1
        end
    end
    
    for i = 1,#genes2 do                    -- Går igneom alla gener i gen2
        local gene = genes2[i]              -- Hämtar specifik gen
        if not i1[gene.innovation] then     -- kollar i i1 om genens innovationstal finns, om inte addera 1 till disjointGenes-
            disjointGenes = disjointGenes+1
        end
    end
    
    local n = math.max(#genes1, #genes2)    -- Kollar antal maxgener från Gene1 och Gene2
    
    return disjointGenes / n                -- Returerar disJoints/antal maxgener. Procentsats hur lika de är
end

function weights(genes1, genes2)
    local i2 = {}                       -- 
    for i = 1,#genes2 do                -- Går igenom alla gener i gene2
        local gene = genes2[i]          -- hämtar specifik gen
        i2[gene.innovation] = gene      -- Sätter genen i i2 med innovationstalet som index
    end

    local sum = 0               --
    local coincident = 0        --
    for i = 1,#genes1 do                                        -- Går igenom alla gener i genes1
        local gene = genes1[i]                                  -- Hämtar specifik gen
        if i2[gene.innovation] ~= nil then                      -- Kollar om genens innovationstal finns i i2, om ..
            local gene2 = i2[gene.innovation]                   -- Hämtar den gen med samma innovationstal från i2
            sum = sum + math.abs(gene.weight - gene2.weight)    -- summan adderas med skillnaden mellan gen1 och gen2:S vikter.
            coincident = coincident + 1                         -- Adderar coincident med 1
        end
    end
    
    return sum / coincident     -- Reutnerar summan / hur många gånger de stämmer överens =)
end
    
function sameSpecies(genome1, genome2)
    local dd = DeltaDisjoint*disjoint(genome1.genes, genome2.genes) -- Konstant * (Returerar disJoints/antal maxgener. Procentsats hur olika de är)
    local dw = DeltaWeights*weights(genome1.genes, genome2.genes)   -- Konstant * (Reutnerar summan / hur många gånger de stämmer överens)
    return dd + dw < DeltaThreshold                                 -- Retunerar en boolean om de är jävligt lika
end

function rankGlobally()
    local global = {}
    for s = 1,#pool.species do
        local species = pool.species[s]
        for g = 1,#species.genomes do
            table.insert(global, species.genomes[g])
        end
    end
    table.sort(global, function (a,b)
        return (a.fitness < b.fitness)
    end)
    
    for g=1,#global do
        global[g].globalRank = g
    end
end

function calculateAverageFitness(species)
    local total = 0
    
    for g=1,#species.genomes do                 -- Går genom alla geomer i en ras
        local genome = species.genomes[g]
        total = total + genome.globalRank       -- Summerar globalRank för att geomer
    end
    
    species.averageFitness = total / #species.genomes   -- Delar på antal geomer och sparar i rasens averageFitness
end

function totalAverageFitness()
    local total = 0
    for s = 1,#pool.species do
        local species = pool.species[s]
        total = total + species.averageFitness
    end

    return total
end

function cullSpecies(cutToOne)
    for s = 1,#pool.species do
        local species = pool.species[s]
        
        table.sort(species.genomes, function (a,b)
            return (a.fitness > b.fitness)
        end)
        
        local remaining = math.ceil(#species.genomes/2)
        if cutToOne then
            remaining = 1
        end
        while #species.genomes > remaining do
            table.remove(species.genomes)
        end
    end
end

function breedChild(species)
    local child = {}                                            -- Skapar ett nytt barn
    if math.random() < CrossoverChance then                     -- En viss procentsats så kommer vi in här
        g1 = species.genomes[math.random(1, #species.genomes)]  -- Tar en genom ur rasen
        g2 = species.genomes[math.random(1, #species.genomes)]  -- Tar en ny random genom ut rasen
        child = crossover(g1, g2)                               -- FÅr ett nytt barn med mixade gener från de två genomnerna
    else                                                        -- Annars tar den en slumpad genom och barnet får dess gener.
        g = species.genomes[math.random(1, #species.genomes)]
        child = copyGenome(g)
    end
    
    mutate(child) 
    
    return child
end

function removeStaleSpecies()
    local survived = {}

    for s = 1,#pool.species do
        local species = pool.species[s]                             -- Ta ut en ras
        
        table.sort(species.genomes, function (a,b)                  -- Sortera rasen
            return (a.fitness > b.fitness)
        end)
        
        if species.genomes[1].fitness > species.topFitness then     -- Om den bästa genomens fitness är bättre än topFitness, uppdatera
            species.topFitness = species.genomes[1].fitness
            species.staleness = 0
        else                                                        -- Annars så plussar vi på staleness
            species.staleness = species.staleness + 1
        end
        if species.staleness < StaleSpecies or species.topFitness >= pool.maxFitness then       -- Om staleness är lägre än ett tröskelvärde,
            table.insert(survived, species)                                                     -- Eller om topfitness är den bästa fitnessen, lägg till!
        end
    end

    pool.species = survived                                         -- Sparar över de raserna som är har klarat sig!
end

function removeWeakSpecies()
    local survived = {}

    local sum = totalAverageFitness()           -- Summerar alla rasers averagefitness
    for s = 1,#pool.species do                  -- Itererar igenom alla raser
        local species = pool.species[s]
        breed = math.floor(species.averageFitness / sum * Population) -- Skapar något najs värde med hjälp av averageFitness rasen, beronde på population och alla andra
        if breed >= 1 then                      -- Om rasen är tillräckligt bra så får den fortsätta att leva!
            table.insert(survived, species)
        end
    end

    pool.species = survived                     -- Sparar över de sparade raserna
end


function addToSpecies(child)
    local foundSpecies = false                                              
    for s=1,#pool.species do                                                    -- Loopar igenom alla raser
        local species = pool.species[s]                                         -- Tar en ras
        if not foundSpecies and sameSpecies(child, species.genomes[1]) then     -- Om vi inte har hittat vilken ras den ska till och om det är samma ras -> lägg till till denna rasen
            table.insert(species.genomes, child)                
            foundSpecies = true
        end
    end
    
    if not foundSpecies then                        -- OM vi inte har hittat  vilken ras som barnet tillhör
        local childSpecies = newSpecies()           -- Då skapar vi en ny Species
        table.insert(childSpecies.genomes, child)   -- LÄgger till barnet i den nya rasens genomer
        table.insert(pool.species, childSpecies)    -- Lägger till rasen bland raserna i pooolen
    end
end

function newGeneration()
    cullSpecies(false)                      -- Tar bort de sämsta geomerna
    rankGlobally()                          -- Skapar en ranking för geomerna i en generation
    removeStaleSpecies()                    -- Jämnför nya generationens bästa fintness med gamla, behålla rasen?
    rankGlobally()                          -- Skapar en ranking för geomerna i en generation
    
    for s = 1,#pool.species do              -- Går igenom alla raser
        local species = pool.species[s]
        calculateAverageFitness(species)    -- Räknar ut en averageRanken som sparar en rasens averagefitness
    end

    removeWeakSpecies()                     -- Tar bort dåiga raser från världen!

    local sum = totalAverageFitness()       -- Summering av alla rasers averageFitness
    local children = {}                     -- Tom array som heter children och består av genomer
    for s = 1,#pool.species do              -- Loopa igenom alla raser
        local species = pool.species[s]
        breed = math.floor(species.averageFitness / sum * Population) - 1 -- Samma godtyckliga breed
        for i=1,breed do                                -- Loopa 1 till breed ..
            table.insert(children, breedChild(species)) -- Lägg till breedChild(species)
        end
    end

    cullSpecies(true) -- Cull all but the top member of each species

    while #children + #pool.species < Population do                     -- Loopa så länge som antalet children(ny ras) + antalet raser(innehåller bara en genom var) < Populationen
        local species = pool.species[math.random(1, #pool.species)]     -- Hämtar en randomras
        table.insert(children, breedChild(species))                     -- lägger till genomer till children
    end

    for c=1,#children do                -- Går igenom alla children
        local child = children[c]       
        addToSpecies(child)             -- LÄgger till barnet i rätt ras
    end
    
    pool.generation = pool.generation + 1 -- Öka generationsantalet
    
    writeFile("backup." .. pool.generation .. "." .. forms.gettext(saveLoadFile)) -- Skriver till filen
end
    
function initializePool()
    pool = newPool()

    for i=1,Population do
        basic = basicGenome()
        addToSpecies(basic)
    end

    initializeRun()
end

function clearJoypad()
    controller = {}
    for b = 1,#ButtonNames do
        controller["P1 " .. ButtonNames[b]] = false
    end
    joypad.set(controller)
end

function initializeRun()
    savestate.load(Filename);
    rightmost = 0                   -- Hur lång mario har tagit sig
    pool.currentFrame = 0          
    timeout = TimeoutConstant       -- Sätt vår timeout
    clearJoypad()                   -- INga knappar har trycks på!
    
    local species = pool.species[pool.currentSpecies]
    local genome = species.genomes[pool.currentGenome]
    generateNetwork(genome)
    evaluateCurrent()
end

function evaluateCurrent()
    local species = pool.species[pool.currentSpecies] -- sätt species rån specie poolen
    local genome = species.genomes[pool.currentGenome] -- sätt genome frå ngenome pool

    inputs = getInputs()                                    -- hämta all input från världen
    controller = evaluateNetwork(genome.network, inputs)    -- Räknar ut vilka knappar som ska tryckas på!
    
    if controller["P1 Left"] and controller["P1 Right"] then    -- Om man trycker på båda knapparna -> trycker int epå någon
        controller["P1 Left"] = false
        controller["P1 Right"] = false
    end
    if controller["P1 Up"] and controller["P1 Down"] then       -- Samma för upp och ner!
        controller["P1 Up"] = false
        controller["P1 Down"] = false
    end

    joypad.set(controller)                                      -- Skickar till joybanden vad som ska klickas på!
end

if pool == nil then
    initializePool()
end


function nextGenome()
    pool.currentGenome = pool.currentGenome + 1                                 -- Tar nästa genome
    if pool.currentGenome > #pool.species[pool.currentSpecies].genomes then     -- Kollar om det finns några mer i den ras!
        pool.currentGenome = 1                                                  -- Då blir nuvarande genome ett
        pool.currentSpecies = pool.currentSpecies+1                             -- Vi lägger till en ny ras
        if pool.currentSpecies > #pool.species then                             -- Om det inte finns någon mer ras, gör en ny generation
            newGeneration()                                                     -- (MASSA SAKER HÄNDER HÄR)
            pool.currentSpecies = 1                                             -- Sätter currentSpecies till 1
        end
    end
end

function fitnessAlreadyMeasured()
    local species = pool.species[pool.currentSpecies]
    local genome = species.genomes[pool.currentGenome]
    
    return genome.fitness ~= 0
end

function displayGenome(genome)
    local network = genome.network
    local cells = {}
    local i = 1
    local cell = {}
    for dy=-BoxRadius,BoxRadius do
        for dx=-BoxRadius,BoxRadius do
            cell = {}
            cell.x = 50+5*dx
            cell.y = 70+5*dy
            cell.value = network.neurons[i].value
            cells[i] = cell
            i = i + 1
        end
    end
    local biasCell = {}
    biasCell.x = 80
    biasCell.y = 110
    biasCell.value = network.neurons[Inputs].value
    cells[Inputs] = biasCell
    
    for o = 1,Outputs do
        cell = {}
        cell.x = 220
        cell.y = 30 + 8 * o
        cell.value = network.neurons[MaxNodes + o].value
        cells[MaxNodes+o] = cell
        local color
        if cell.value > 0 then
            color = 0xFF0000FF
        else
            color = 0xFF000000
        end
        gui.drawText(223, 24+8*o, ButtonNames[o], color, 9)
    end
    
    for n,neuron in pairs(network.neurons) do
        cell = {}
        if n > Inputs and n <= MaxNodes then
            cell.x = 140
            cell.y = 40
            cell.value = neuron.value
            cells[n] = cell
        end
    end
    
    for n=1,4 do
        for _,gene in pairs(genome.genes) do
            if gene.enabled then
                local c1 = cells[gene.into]
                local c2 = cells[gene.out]
                if gene.into > Inputs and gene.into <= MaxNodes then
                    c1.x = 0.75*c1.x + 0.25*c2.x
                    if c1.x >= c2.x then
                        c1.x = c1.x - 40
                    end
                    if c1.x < 90 then
                        c1.x = 90
                    end
                    
                    if c1.x > 220 then
                        c1.x = 220
                    end
                    c1.y = 0.75*c1.y + 0.25*c2.y
                    
                end
                if gene.out > Inputs and gene.out <= MaxNodes then
                    c2.x = 0.25*c1.x + 0.75*c2.x
                    if c1.x >= c2.x then
                        c2.x = c2.x + 40
                    end
                    if c2.x < 90 then
                        c2.x = 90
                    end
                    if c2.x > 220 then
                        c2.x = 220
                    end
                    c2.y = 0.25*c1.y + 0.75*c2.y
                end
            end
        end
    end
    
    gui.drawBox(50-BoxRadius*5-3,70-BoxRadius*5-3,50+BoxRadius*5+2,70+BoxRadius*5+2,0xFF000000, 0x80808080)
    for n,cell in pairs(cells) do
        if n > Inputs or cell.value ~= 0 then
            local color = math.floor((cell.value+1)/2*256)
            if color > 255 then color = 255 end
            if color < 0 then color = 0 end
            local opacity = 0xFF000000
            if cell.value == 0 then
                opacity = 0x50000000
            end
            color = opacity + color*0x10000 + color*0x100 + color
            gui.drawBox(cell.x-2,cell.y-2,cell.x+2,cell.y+2,opacity,color)
        end
    end
    for _,gene in pairs(genome.genes) do
        if gene.enabled then
            local c1 = cells[gene.into]
            local c2 = cells[gene.out]
            local opacity = 0xA0000000
            if c1.value == 0 then
                opacity = 0x20000000
            end
            
            local color = 0x80-math.floor(math.abs(sigmoid(gene.weight))*0x80)
            if gene.weight > 0 then 
                color = opacity + 0x8000 + 0x10000*color
            else
                color = opacity + 0x800000 + 0x100*color
            end
            gui.drawLine(c1.x+1, c1.y, c2.x-3, c2.y, color)
        end
    end
    
    gui.drawBox(49,71,51,78,0x00000000,0x80FF0000)
    
    if forms.ischecked(showMutationRates) then
        local pos = 100
        for mutation,rate in pairs(genome.mutationRates) do
            gui.drawText(100, pos, mutation .. ": " .. rate, 0xFF000000, 10)
            pos = pos + 8
        end
    end
end

function writeFile(filename)
        local file = io.open(filename, "w")
    file:write(pool.generation .. "\n")
    file:write(pool.maxFitness .. "\n")
    file:write(#pool.species .. "\n")
        for n,species in pairs(pool.species) do
        file:write(species.topFitness .. "\n")
        file:write(species.staleness .. "\n")
        file:write(#species.genomes .. "\n")
        for m,genome in pairs(species.genomes) do
            file:write(genome.fitness .. "\n")
            file:write(genome.maxneuron .. "\n")
            for mutation,rate in pairs(genome.mutationRates) do
                file:write(mutation .. "\n")
                file:write(rate .. "\n")
            end
            file:write("done\n")
            
            file:write(#genome.genes .. "\n")
            for l,gene in pairs(genome.genes) do
                file:write(gene.into .. " ")
                file:write(gene.out .. " ")
                file:write(gene.weight .. " ")
                file:write(gene.innovation .. " ")
                if(gene.enabled) then
                    file:write("1\n")
                else
                    file:write("0\n")
                end
            end
        end
        end
        file:close()
end

function savePool()
    local filename = forms.gettext(saveLoadFile)
    writeFile(filename)
end

function loadFile(filename)
        local file = io.open(filename, "r")
    pool = newPool()
    pool.generation = file:read("*number")
    pool.maxFitness = file:read("*number")
    forms.settext(maxFitnessLabel, "Max Fitness: " .. math.floor(pool.maxFitness))
        local numSpecies = file:read("*number")
        for s=1,numSpecies do
        local species = newSpecies()
        table.insert(pool.species, species)
        species.topFitness = file:read("*number")
        species.staleness = file:read("*number")
        local numGenomes = file:read("*number")
        for g=1,numGenomes do
            local genome = newGenome()
            table.insert(species.genomes, genome)
            genome.fitness = file:read("*number")
            genome.maxneuron = file:read("*number")
            local line = file:read("*line")
            while line ~= "done" do
                genome.mutationRates[line] = file:read("*number")
                line = file:read("*line")
            end
            local numGenes = file:read("*number")
            for n=1,numGenes do
                local gene = newGene()
                table.insert(genome.genes, gene)
                local enabled
                gene.into, gene.out, gene.weight, gene.innovation, enabled = file:read("*number", "*number", "*number", "*number", "*number")
                if enabled == 0 then
                    gene.enabled = false
                else
                    gene.enabled = true
                end
                
            end
        end
    end
        file:close()
    
    while fitnessAlreadyMeasured() do
        nextGenome()
    end
    initializeRun()
    pool.currentFrame = pool.currentFrame + 1
end
 
function loadPool()
    local filename = forms.gettext(saveLoadFile)
    loadFile(filename)
end

function playTop()
    local maxfitness = 0
    local maxs, maxg
    for s,species in pairs(pool.species) do
        for g,genome in pairs(species.genomes) do
            if genome.fitness > maxfitness then
                maxfitness = genome.fitness
                maxs = s
                maxg = g
            end
        end
    end
    
    pool.currentSpecies = maxs
    pool.currentGenome = maxg
    pool.maxFitness = maxfitness
    forms.settext(maxFitnessLabel, "Max Fitness: " .. math.floor(pool.maxFitness))
    initializeRun()
    pool.currentFrame = pool.currentFrame + 1
    return
end

function onExit()
    forms.destroy(form)
end

writeFile("temp.pool")

event.onexit(onExit)

form                = forms.newform(200, 260, "Fitness")
maxFitnessLabel     = forms.label(form, "Max Fitness: " .. math.floor(pool.maxFitness), 5, 8)
showNetwork         = forms.checkbox(form, "Show Map", 5, 30)
showMutationRates   = forms.checkbox(form, "Show M-Rates", 5, 52)
restartButton       = forms.button(form, "Restart", initializePool, 5, 77)
saveButton          = forms.button(form, "Save", savePool, 5, 102)
loadButton          = forms.button(form, "Load", loadPool, 80, 102)
saveLoadFile        = forms.textbox(form, Filename .. ".pool", 170, 25, nil, 5, 148)
saveLoadLabel       = forms.label(form, "Save/Load:", 5, 129)
playTopButton       = forms.button(form, "Play Top", playTop, 5, 170)
hideBanner          = forms.checkbox(form, "Hide Banner", 5, 190)


while true do
    local backgroundColor = 0xD0FFFFFF                                      -- sätt bakgrundsfärg till ganska vitt
    if not forms.ischecked(hideBanner) then                                 -- kolla ifall vi ska visa banner med information
        gui.drawBox(0, 0, 300, 26, backgroundColor, backgroundColor)        -- måla upp en box 
    end

    local species = pool.species[pool.currentSpecies]                       -- sätt species till current species
    local genome = species.genomes[pool.currentGenome]                      -- sätt genome "mängden dna från föregående" till current genome
    
    if forms.ischecked(showNetwork) then
        displayGenome(genome)           -- display genom ifall de är ikryssat
    end
    
    if pool.currentFrame%5 == 0 then
        evaluateCurrent()               -- kalla på evaluate current -> Vilka knappar som ska tryckas på!
    end

    joypad.set(controller)              -- Säger till bizhawk vilka knappar som ska tryckas på!

    getPositions()                      -- Hämtar postition på mario
    if marioX > rightmost then          -- Uppdaterar marios position, har han rört sig?
        rightmost = marioX
        timeout = TimeoutConstant       -- 
    end
    
    timeout = timeout - 1               --  Tickar ner timeoiten(om mario skulle stå stilla för länge)
    
    
    local timeoutBonus = pool.currentFrame / 4 
    if timeout + timeoutBonus <= 0 then                                                     -- Om mario har stått stilla förlänge!
        local fitness = rightmost - pool.currentFrame / 2                                   -- Uppdaterar vår fitness!
        if gameinfo.getromname() == "Super Mario World (USA)" and rightmost > 4816 then
            fitness = fitness + 1000
        end
        if gameinfo.getromname() == "Super Mario Bros." and rightmost > 3186 then           -- Om Mario ´har kommit i mål
            fitness = fitness + 1000                                                        -- Yeah, BONUS!
        end
        if fitness == 0 then                                                                -- ?!
            fitness = -1
        end
        genome.fitness = fitness                                                            -- Sätter fitnesset på genomet!
        
        if fitness > pool.maxFitness then                                                   -- Om det är den bästa fitnessen
            pool.maxFitness = fitness                                                       -- Uppdaterar MAXfitness
            forms.settext(maxFitnessLabel, "Max Fitness: " .. math.floor(pool.maxFitness))  -- Uppdaterar texten!
            writeFile("backup." .. pool.generation .. "." .. forms.gettext(saveLoadFile))   -- Sparar ner bästa genomen i en generation
        end
        
        console.writeline("Gen " .. pool.generation .. " species " .. pool.currentSpecies .. " genome " .. pool.currentGenome .. " fitness: " .. fitness)
        pool.currentSpecies = 1
        pool.currentGenome = 1


        while fitnessAlreadyMeasured() do   -- Kollar om fintess har ändrats currentGenom
            nextGenome()                    -- Har den gjort det så tar vi nästa genom, kan vara så att vi skapar en helt ny generation
        end
        initializeRun() -- Resetar allt
    end

    local measured = 0
    local total = 0
    for _,species in pairs(pool.species) do         -- Går ingeom alla species
        for _,genome in pairs(species.genomes) do   -- GÅr igenom alla genomer i den speices
            total = total + 1                       -- Adderar ett till total
            if genome.fitness ~= 0 then             -- Om fitnessen för genmen inte är  == 0 sååå...
                measured = measured + 1             -- Då adderar vi ett till measured ... ? VARFÖR?
            end
        end
    end
    if not forms.ischecked(hideBanner) then
        gui.drawText(0, 0, "Gen " .. pool.generation .. " species " .. pool.currentSpecies .. " genome " .. pool.currentGenome .. " (" .. math.floor(measured/total*100) .. "%)", 0xFF000000, 11)
        gui.drawText(0, 12, "Fitness: " .. math.floor(rightmost - (pool.currentFrame) / 2 - (timeout + timeoutBonus)*2/3), 0xFF000000, 11)
        gui.drawText(100, 12, "Max Fitness: " .. math.floor(pool.maxFitness), 0xFF000000, 11)
    end
        
    pool.currentFrame = pool.currentFrame + 1

    emu.frameadvance();
end