--(Module Script)
--Use as a safe space to store any research data, referred to only by PurchaseHandler and PlayerStatManager
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local ResearchData = {
	
	["Max Researchers"] = 4,
	
	["Research"] = {
		
		["PlayerItem Improvements"] = {
			["Research Type Name"] = "PlayerItem Research"
			
			
			
			
		},

		["Tycoon Improvements"] = {
			["Research Type Name"] = "Tycoon Research",
			
			[1] = {
				["Research Name"] = "Room Temperature Superconductors",
				["Rarity"] = "Legendary",
				["Research Length"] = 5,
				["Material Cost"] = {},
				["ExperienceCost"] = {},
				["Dependencies"] = {}
				
			}
		},

		["Town Improvements"] = {
			["Research Type Name"] = "Town Research"
			
			
			
			
		},
		

	}
	
	
	

	
}

--Research must have...
--What it does, Trigger, Time, Next (multiple dependencies), material cost, lvl cost

--Maybe have event folder named research?

--With shops selling new things, maybe have shops check, when they're displaying their shop tiles, what the player
--has all unlocked?

--After Dinner: lay out research data to be sorted throughout PlayerDataFile; Folders: ResearchTypes, Files: Research
--Research file name will be research name, number value will be tick count (research length), then 
--massively checked values like Purchased, FinishTime, and Completed



--Firing types: Saved value is read by another script or models are inserted by local script
--PlayerStatManager:checkResearch() (Checked by UI when opened)

--Event received in TycoonComputerHandler puts model in workspace for player
--Should a list of all research be kept in ReplicatedStorage, or should it only be research that need models

--Research Saves = Bool:Purchased, Integer:Tick When Bought, Bool:Completed

--With tick value, PlayerStatManager will start a timer on load when it updates each research tile, and it will calculate
--the finished tick value by comparing ResearchData's timer and the tick value, then subtract final w/ current
--and simplify into hrs, mins, and secs
return ResearchData

