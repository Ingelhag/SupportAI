-- MAIN FILE --- 

---------- include files --------------
PoolHandler 	= require("PoolHandler")
SpeciesHandler 	= require("SpeciesHandler")
GenomeHandler 	= require("GenomeHandler")
LinkHandler 	= require("LinkHandler")
NeuronHandler 	= require("NeuronHandler")
NetworkHandler 	= require("NetworkHandler")
UtilHandler		= require("UtilHandler")
ConstantValues 	= require("ConstantValues")
---------------------------------------
local main = {}								-- För att kunna skriva funktioner där vi vill ha dom
inputCompanies = {}
local fitness = 0

---------------------------------------


------------ Funktioner ---------------

-- Sätter startvärden är simulationen
local function startRun(pool)	
																-- Clear controller
	local currentSpecies = pool.species[pool.currentSpecies]
	local currentGenome = currentSpecies.genomes[pool.currentGenome] 	-- Hämta nuvarande genome
	GenomeHandler.generateNetwork(currentGenome)	
end


local function setControllerInput(genome)

	

end

local function findNextGenome(pool)

end

main.startRun = startRun
main.clearController = clearController
main.setControllerInput = setControllerInput
main.findNextGenome = findNextGenome

--------------------PROGRAM ----------------------------

-- Skapa en ny genpool
 local pool = PoolHandler.newPool()

-- IFALL DU VILL LÄSA IN EN GAMMAL! saved/lastgeneration.json--
-- pool = UtilHandler.readFromFile(pool)

-- IFALL DU VILL STARTA EN NY! -- 
PoolHandler.generateStartPool(pool.species);

-- Opens a file in read mode
local fromFile = UtilHandler.readFromFile()



for i = 1, #fromFile do 
	if (UtilHandler.has_value(inputCompanies, fromFile[i].Name) == nil) then
		table.insert(inputCompanies, fromFile[i].Name);
	end
end

local go = true

while go do 
	main.startRun(pool)


	local sFitness
	local currentGenome = pool.species[pool.currentSpecies].genomes[pool.currentGenome]	

	for i = 1, #fromFile do
		local responsibleOutput = NetworkHandler.evaluateNetworkForOutput(currentGenome.network, fromFile[i])

		if (i == 1) then
			sFitness = UtilHandler.calcFitness(responsibleOutput, fromFile[i].UserName);
		else
			sFitness = fitness + UtilHandler.calcFitness(responsibleOutput, fromFile[i].UserName);
		end
	end

	currentGenome.fitness = sFitness 													-- set the genomes fitness to the current fitness


	print("fitness: " .. sFitness)
	print("pool.maxFitness: " .. pool.maxFitness)
	if (sFitness > pool.maxFitness) then 													-- update the pools maxfitness if needed
		print("SET MAXFITNESS")
		pool.maxFitness = fitness 												
	end

	if fitness > pool.species[pool.currentSpecies].topFitness then
		pool.species[pool.currentSpecies].topFitness = sFitness
	end

	print("Gen: " ..  pool.generation .. " - Species - " .. pool.currentSpecies .. " - Genome: " .. pool.currentGenome .. " - fitness: " .. currentGenome.fitness .. " - maxF: " .. pool.maxFitness)

	if(pool.generation == 20) then
		go = false
	else
		PoolHandler.findNextGenome(pool)
	end
end

local resultatGenome = pool.species[1].genomes[1]

local countCorr = 0
for i = 1, #fromFile do 
	local resultatOutput = NetworkHandler.evaluateNetworkForOutput(resultatGenome.network, fromFile[i])	


	print(fromFile[i].Name .. " - Ansvarig - " .. fromFile[i].UserName)

	for j=1, NUM_OF_OUTPUTS do
	    local responsible = RESPONSIBLES[j]
        if resultatOutput[responsible] then
            if responsible == fromFile[i].UserName then
            	countCorr = countCorr + 1
                print("Vår ai tyckte lika också det! :D :D")
            end
        else
	    end
	end
	for j=1, NUM_OF_OUTPUTS do
	    local responsible = RESPONSIBLES[j]
        if resultatOutput[responsible] then
        	print("Skickas till: " .. responsible)
        else
	    end
	end
	print("-----------------------------")
end

print((countCorr / #fromFile)*100 .. "% skickades till rätt person!")

-- while true do
-- 	local currentGenome = pool.species[pool.currentSpecies].genomes[pool.currentGenome]	

-- 	if pool.currentFrame % 5 then
-- 		main.setControllerInput(currentGenome) 									-- calculate new output values every 5th frame			
-- 		--print(string.format("Outputs -  A: %t, B: %t, Up: %t, Down: %t, Left: %t, Right: %t",	outputs["A"], outputs["B"], outputs["Up"], outputs["Down"], outputs["Left"], outputs["Right"]))
-- 	end
	
-- 	--joypad = outputs
-- 	local marioPositions = UtilHandler.getPositions()

-- 	if lastPosition ~= marioPositions.marioX then											-- check if mario is standing still or not
-- 																	-- if he moves reset the timeout timer
-- 		lastPosition = marioPositions.marioX
-- 	end

-- 	if marioPositions.marioX > rightMost then 	
-- 		timeout = TIMEOUT_CONSTANT 											-- if mario is further to the right than before then update rightmost
-- 		rightMost = marioPositions.marioX
-- 	end

-- 	timeout = timeout - 1 																	-- tick down the timeout timer
 	
-- 	if timeout <= 0 then 	

-- 																							-- if mario has been standing still for to long
-- 		local fitness = math.floor(rightMost - pool.currentFrame / 4.0) 								-- calculate the fitnesss
-- 		if rightMost > 3186 then  															-- if mario finish the level give him a fuckingMILLION FITNESS POINTS
-- 			fitness = fitness + 1000000
-- 		end

-- 		if fitness == 0 then 																-- if fitness zero set it to -1 
-- 			fitness = -1
-- 		end																						-- should remove this 

-- 		currentGenome.fitness = fitness 													-- set the genomes fitness to the current fitness

-- 		if fitness > pool.maxFitness then 													-- update the pools maxfitness if needed
-- 			pool.maxFitness = fitness 												
-- 		end

-- 		if fitness > pool.species[pool.currentSpecies].topFitness then
-- 			pool.species[pool.currentSpecies].topFitness = fitness
-- 		end

-- 		--print("Gen: " ..  pool.generation .. " - Species - " .. pool.currentSpecies .. " - Genome: " .. pool.currentGenome .. " - fitness: " .. currentGenome.fitness .. " - maxF: " .. pool.maxFitness)
	
-- 		PoolHandler.findNextGenome(pool) 																-- search for the next genome to simulate, will change the current species and current genome of the pool.
		
-- 		main.startRun(pool) 																			-- start a run with the next genome
		
-- 	end

-- 	pool.currentFrame = pool.currentFrame + 1
-- 	emu.frameadvance();
-- end



