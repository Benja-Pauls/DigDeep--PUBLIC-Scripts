--(Module Script)
--Use as a safe space to store any research data, referred to only by PurchaseHandler and PlayerStatManager
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local RS = game.ReplicatedStorage

--Hour: 3600
--4 Hours: 14400
--6 Hours: 21600
--12 Hours: 43200
--1 Day: 86400

local ResearchData = {
	
	["Max Researchers"] = 5,
	
	["Research"] = {
		
		["Equipment Improvements"] = {
			["Research Type Name"] = "Equipment Research"
			
			--Shop keepers could check player every time they interact if they have completed research
			--for any of their items requiring research...
			
			--However, that could be inefficient, especially in local script, so possibly have server script handle
			--these changes every time and send out UpdateStoreFront event?
			
			
		},

		["Tycoon Improvements"] = {
			["Research Type Name"] = "Tycoon Research",
			
			[1] = {
				["Research Name"] = "Room Temperature Superconductors",
				["Research Image"] = "rbxassetid://6708071453",
				["Rarity"] = "Legendary",
				["Description"] = "After extensive testing, our researchers believe they can create a superconductor that can operate at room temperature. It will take some time, but the results will be worth it.",
				
				["Research Length"] = 60,
				["Material Cost"] = {
					{RS.ItemLocations.Mineshaft.Stone, 5},
				},
				["Experience Cost"] = {
					{RS.Skills.MiningSkill, 3}
				},
				["Dependencies"] = {"More Efficient Fuel Cells"}
			},
			
			[2] = {
				["Research Name"] = "More Efficient Fuel Cells",
				["Research Image"] = "",
				["Rarity"] = "Uncommon",
				["Description"] = "",
				
				["Research Length"] = 15,
				["Material Cost"] = {
					{RS.ItemLocations.Mineshaft.Stone, 1},
					{RS.ItemLocations.Mineshaft.Coal, 1}
				},
				["Experience Cost"] = {
					{RS.Skills.MiningSkill, 3}
				},
				["Dependencies"] = {"Fuel Cells7"}
			},
			
			[3] = {
				["Research Name"] = "Fuel Cells",
				["Research Image"] = "",
				["Rarity"] = "Common",
				["Description"] = "",
				
				["Research Length"] = 108000,
				["Material Cost"] = {
					{RS.ItemLocations.Mineshaft.Stone, 5},
					{RS.ItemLocations.Mineshaft["Scrap Metal"], 5}
				},
				["Experience Cost"] = {
					{RS.Skills.MiningSkill, 3}
				},
				["Dependencies"] = {}
			},
			
			[4] = {
				["Research Name"] = "Fuel Cells2",
				["Research Image"] = "",
				["Rarity"] = "Rare",
				["Description"] = "",
				
				["Research Length"] = 4500,
				["Material Cost"] = {
					{RS.ItemLocations.Mineshaft.Stone, 5}
				},
				["Experience Cost"] = {
					{RS.Skills.MiningSkill, 3}
				},
				["Dependencies"] = {}
			},
			
			[5] = {
				["Research Name"] = "Fuel Cells3",
				["Research Image"] = "",
				["Rarity"] = "Common",
				["Description"] = "",
				
				["Research Length"] = 30,
				["Material Cost"] = {
					{RS.ItemLocations.Mineshaft.Stone, 5}
				},
				["Experience Cost"] = {
					{RS.Skills.MiningSkill, 3}
				},
				["Dependencies"] = {}
			},
			
			[6] = {
				["Research Name"] = "Fuel Cells4",
				["Research Image"] = "",
				["Rarity"] = "Common",
				["Description"] = "",
				
				["Research Length"] = 60,
				["Material Cost"] = {
					{RS.ItemLocations.Mineshaft.Stone, 5}
				},
				["Experience Cost"] = {
					{RS.Skills.MiningSkill, 3}
				},
				["Dependencies"] = {}
			},
			
			[7] = {
				["Research Name"] = "Fuel Cells5",
				["Research Image"] = "",
				["Rarity"] = "Common",
				["Description"] = "",
				
				["Research Length"] = 120,
				["Material Cost"] = {
					{RS.ItemLocations.Mineshaft.Stone, 5}
				},
				["Experience Cost"] = {
					{RS.Skills.MiningSkill, 3}
				},
				["Dependencies"] = {}
			},
			
			[8] = {
				["Research Name"] = "Fuel Cells6",
				["Research Image"] = "",
				["Rarity"] = "Uncommon",
				["Description"] = "",
				
				["Research Length"] = 300,
				["Material Cost"] = {
					{RS.ItemLocations.Mineshaft.Stone, 5}
				},
				["Experience Cost"] = {
					{RS.Skills.MiningSkill, 3}
				},
				["Dependencies"] = {}
			},
			
			[9] = {
				["Research Name"] = "Fuel Cells7",
				["Research Image"] = "",
				["Rarity"] = "Legendary",
				["Description"] = "",
				
				["Research Length"] = 300,
				["Material Cost"] = {
					{RS.ItemLocations.Mineshaft.Stone, 5}
				},
				["Experience Cost"] = {
					{RS.Skills.MiningSkill, 3}
				},
				["Dependencies"] = {}
			},
			
			[10] = {
				["Research Name"] = "Fuel Cells8",
				["Research Image"] = "",
				["Rarity"] = "Rare",
				["Description"] = "",
				
				["Research Length"] = 300,
				["Material Cost"] = {
					{RS.ItemLocations.Mineshaft.Stone, 5}
				},
				["Experience Cost"] = {
					{RS.Skills.MiningSkill, 3}
				},
				["Dependencies"] = {}
			},
			
			[11] = {
				["Research Name"] = "Fuel Cells9",
				["Research Image"] = "",
				["Rarity"] = "Uncommon",
				["Description"] = "",
				
				["Research Length"] = 300,
				["Material Cost"] = {
					{RS.ItemLocations.Mineshaft.Stone, 5}
				},
				["Experience Cost"] = {
					{RS.Skills.MiningSkill, 3}
				},
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

--Quest items? Player must have a quest item? (like a blueprint provided by an NPC?)


--Firing types: Saved value is read by another script or models are inserted by local script
--PlayerStatManager:checkResearch() (Checked by UI when opened)

--Event received in TycoonComputerHandler puts model in workspace for player
--Should a list of all research be kept in ReplicatedStorage, or should it only be research that need models

--Research Saves = Bool:Purchased, Integer:Tick When Bought, Bool:Completed

--With tick value, PlayerStatManager will start a timer on load when it updates each research tile, and it will calculate
--the finished tick value by comparing ResearchData's timer and the tick value, then subtract final w/ current
--and simplify into hrs, mins, and secs
return ResearchData

