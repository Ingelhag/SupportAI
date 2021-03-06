-- neuron file --
-- en nod i genomen (hjärnan) -- 
local NeuronHandler = {}

local function newNeuron()
    local neuron = {}
    neuron.incommingLinks = {}      -- alla inkommande länkar från andra noder -- 
    neuron.value = 0.0              -- värdet på denna nod --

    return neuron
end

local function copyNeuron(oldNeurons)
    local newNeurons = {}

    for i = 1, MAX_NODES + NUM_OF_OUTPUTS do 

        if oldNeurons[tostring(i)] ~= nil then
            newNeurons[i] = NeuronHandler.newNeuron()
            newNeurons[i].value = oldNeurons[tostring(i)].value

            for j =1, #oldNeurons[tostring(i)].incommingLinks do
                table.insert(newNeurons[i].incommingLinks, LinkHandler.copyLink(oldNeurons[tostring(i)].incommingLinks[j]))
            end

        end 
    end

    NeuronHandler.printClass(newNeurons)

    return newNeurons

end

local function printClass(neuron)
    print("                ---- Neuron ----")
    print("                Number of incomming links: " ..  #neuron.incommingLinks)
    print("                Value of neuron: " .. neuron.value)
end

-- binda functioner --
NeuronHandler.newNeuron = newNeuron
NeuronHandler.copyNeuron = copyNeuron
NeuronHandler.printClass = printClass

return NeuronHandler