-- network file --
local NetworkHandler = {}

local function newNetwork()
    local network = {}
   
    network.neurons = {}
   
    return network
end

local function copyNetwork(oldNetwork)
    local newNetwork = NetworkHandler.newNetwork()
    
    newNetwork.neurons = NeuronHandler.copyNeuron(oldNetwork.neurons)

    return newNetwork

end

local function evaluateNetworkForOutput(network, input)

    local inputs = {}
    table.insert(inputs, UtilHandler.has_value(inputCompanies, input.Name))


    for i=1, NUM_OF_INPUTS do                                                   -- set the values of all the input nodes in the network
        network.neurons[i].value = inputs[i]
    end

 
    for _,neuron in pairs(network.neurons) do                                                -- here we calculate the value for all the hidden nodes + output nodes
        local sum = 0

        for j=1, #neuron.incommingLinks do                               -- for all the links given a neuron 
            local incLink = neuron.incommingLinks[j]                             
            sum = sum + network.neurons[incLink.into].value*incLink.weight      -- calculated a sumation of all the incoming neurons value weighted with the link weight
        end

        if #neuron.incommingLinks > 0 then                               -- check so we dont send a input node through the sigmoidfunction
            neuron.value = NetworkHandler.sigmoidFunction(sum)           -- send it to the sigmoidfunction
        end

    end

    -- Check if the email came to the right person!
    local outputs = {}                                                             -- set if the outputs should be pressed or not
    for i=1, NUM_OF_OUTPUTS do
        local responsible = RESPONSIBLES[i]
        if network.neurons[i+MAX_NODES].value > 0  then                                   -- the sigmoid function returns a value between -0.5 to 0.5
            outputs[responsible] = true                                                        -- if the value is > 0 = send mail
        else
            outputs[responsible] = false
        end
    end

    return outputs                                                               -- return the outputs

end

local function sigmoidFunction(sum) 
    return (2.0 / (1.0 + math.exp(-4.9*sum))) -1   -- detta ger ett intervall från -0.5 till 0.5 där x=0 => y = 0
end

local function printClass(network) 
    print("            ---- Network ----")
    print("            Number of neurons: " .. #network.neurons)
end

NetworkHandler.newNetwork = newNetwork
NetworkHandler.copyNetwork = copyNetwork
NetworkHandler.evaluateNetworkForOutput = evaluateNetworkForOutput
NetworkHandler.sigmoidFunction = sigmoidFunction
NetworkHandler.printClass = printClass

return NetworkHandler;