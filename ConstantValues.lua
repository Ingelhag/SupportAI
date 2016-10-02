SAVE_STATE = "superMario1-1.state"                   -- vi sparar ett state i början på spelet så vi kan ladda om från start hela tiden --
BUTTON_NAMES = {                             -- vilka möjliga outputs vi har --
    "A",
    "B",
    "Up",
    "Down",
    "Left",
    "Right",
}
    
BOX_RADIUS = 6                               -- hur stor hitbox för en tile --      
INPUT_SIZE = (BOX_RADIUS*2+1)*(BOX_RADIUS*2+1) -- 

NUM_OF_INPUTS = INPUT_SIZE+1           	        -- hur många inputs vi har från världen --
NUM_OF_OUTPUTS = #BUTTON_NAMES                  -- hur många outputs vi har (beror på kontrollen)

POPULATION = 200--300                            	-- hur många genomer som får finnas för varje generation --

DELTA_DISJOINT 	= 2.0                         	-- används för att bestämma hur stor skillnad det får vara mellan genomer för att de ska tillhöra samma ras (2.0)--
DELTA_EXCESS 	= 2.0 
DELTA_WEIGHTS 	= 0.4                          	-- används för att bestämma hur stor skillnad det får vara mellan genomer för att de ska tillhöra samma ras --
DELTA_THRESHOLD = 1.0                        	-- används för att bestämma hur stor skillnad det får vara mellan genomer för att de ska tillhöra samma ras (1.0)--
                                            	-- deltadisjoints*SkillnadenILänkar + deltaWeights*skillnadenIVikter < Deltathreshold == samma ras --

STALE_SPECIES = 15                           	-- Hur många generationer en ras inte behöver förbättra sitt maxFitness, över detta antal så tas rasen bort -- 

MUTATE_CONNECTIONS_CHANCE = 0.25            	-- sannolikhet för att vi skall försöka ändra vikten på en länk (0.25)--
LINK_MUTATION_CHANCE= 2.0                    	-- sannolikhet för att en ny länk skall skapas mellan två noder (2.0)-- 
BIAS_MUTATION_CHANCE= 0.40                   	-- sannolikhet för att en länk skall skapas mellan den sista input-noden och en random-nod -- 
NODE_MUTATION_CHANCE =  0.4                   	-- sannolikhet för att en länk skall bli två med olika vikter (0.4)--
DISBALE_MUTATION_CHANCE = 0.4                 	-- sannolikhet för att en länk skall blir inaktiv som är aktiv just nu och inte användas i simulationen --
ENABLE_MUTATION_CHANCE = 0.2                  	-- sannolikhet för att en länk skall bli aktiv från inaktiv och användas i simulationen --

PETURB_CHANCE = 0.90                            -- sannolikhet för att vikten skall modifiera nuvarande vikt eller slumpa helt ny vikt (används efter mutateconnectionschance) -- 
CROSSOVER_CHANCE = 0.75                         -- sannolikhet för att ett barn skall skapas av två genomer, annars kopieras bara en genom till barnet -- 

STEP_SIZE = 0.1                              	-- används när vi MODIFIERAR gamla vikter i pointMutate -- 
TIMEOUT_CONSTANT = 70                        	-- hur länge mario får stå still innan vi avbryter nuvarande simulation -- 

MAX_NODES = 2000                          	-- hur många noder som max får finnas i en Genome --