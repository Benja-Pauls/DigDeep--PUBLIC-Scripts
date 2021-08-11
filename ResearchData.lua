--(Module Script)
--Use as a safe space to store any research data, referred to only by PurchaseHandler and PlayerStatManager
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local RS = game.ReplicatedStorage

local experienceData = require(game.ServerStorage.ExperienceData)
local utility = require(game.ServerScriptService.Utility)

--Hour: 3600
--4 Hours: 14400
--6 Hours: 21600
--12 Hours: 43200
--1 Day: 86400

local ResearchData = {
	
	["Max Researchers"] = 5,
	
	["Research"] = {
		
		["Shop Improvements"] = {
			["Research Type Name"] = "Shop Research",
			
			[1] = {
				["Research Name"] = "Bio-Glow Pickaxe",
				["Research Image"] = "",
				["Rarity"] = "Rare",
				["Description"] = "If you find some Glow Shrooms, our scientists may be able to analyze their structure and form alloys from the glowing cells",
				
				["Research Length"] = 2700,
				["Material Cost"] = {
					{RS.InventoryItems.Foraging["Glow Shroom"], 5},
				},
				["Experience Cost"] = {
					{experienceData["Skills"]["Mining Skill"], 5, "Skill"},
					{experienceData["Skills"]["Foraging Skill"], 2, "Skill"}
				},
				["Dependencies"] = {},
				
				
				
			},
			
			[2] = {
				["Research Name"] = "ACOG Rifle Sight",
				["Research Image"] = "",
				["Rarity"] = "Rare",
				["Description"] = "Using some more advanced components, we can alter the reflex sight to see farther than normal.",

				["Research Length"] = 3600,
				["Material Cost"] = {
					{RS.InventoryItems.Foraging["Glow Shroom"], 5},
				},
				["Experience Cost"] = {
					{experienceData["Skills"]["Mining Skill"], 5, "Skill"},
					{experienceData["Skills"]["Foraging Skill"], 2, "Skill"}
				},
				["Dependencies"] = {}

			}
				
		},

		["Tycoon Improvements"] = {
			["Research Type Name"] = "Tycoon Research",
			
			[1] = {
				["Research Name"] = "Room Temperature Superconductors",
				["Research Image"] = "rbxassetid://7236558599",
				["Rarity"] = "Legendary",
				["Description"] = "After extensive testing, our researchers believe they can create a superconductor that can operate at room temperature. It will take some time, but the results will be worth it.",
				
				["Research Length"] = 43200,
				["Material Cost"] = {
					{RS.InventoryItems.Mining.Stone, 5},
				},
				["Experience Cost"] = {
					{experienceData["Skills"]["Mining Skill"], 3}
				},
				["Dependencies"] = {
					"Better Fuel Cells",
					"Fuel Cells",
					"Fuel Cells2",
					"Fuel Cells3",
					"4th Tier Fuel Cell"
				}
			},
			
			[2] = {
				["Research Name"] = "Better Fuel Cells",
				["Research Image"] = "",
				["Rarity"] = "Uncommon",
				["Description"] = "This is a placeholder description for this research",
				
				["Research Length"] = 15,
				["Material Cost"] = {
					{RS.InventoryItems.Mining.Stone, 1},
					{RS.InventoryItems.Mining.Coal, 1}
				},
				["Experience Cost"] = {
					{experienceData["Skills"]["Mining Skill"], 3, "Skill"}
				},
				["Dependencies"] = {"Fuel Cells7"}
			},
			
			[3] = {
				["Research Name"] = "Fuel Cells",
				["Research Image"] = "",
				["Rarity"] = "Common",
				["Description"] = "This is a placeholder description for this research",
				
				["Research Length"] = 10,
				["Material Cost"] = {
					{RS.InventoryItems.Mining.Stone, 5},
					{RS.InventoryItems.Mining["Scrap Metal"], 5}
				},
				["Experience Cost"] = {
					{experienceData["Skills"]["Mining Skill"], 3, "Skill"}
				},
				["Dependencies"] = {}
			},
			
			[4] = {
				["Research Name"] = "Fuel Cells2",
				["Research Image"] = "",
				["Rarity"] = "Common",
				["Description"] = "This is a placeholder description for this research",
				
				["Research Length"] = 120,
				["Material Cost"] = {
					{RS.InventoryItems.Mining.Stone, 5}
				},
				["Experience Cost"] = {
					{experienceData["Skills"]["Mining Skill"], 3}
				},
				["Dependencies"] = {}
			},
			
			[5] = {
				["Research Name"] = "Fuel Cells3",
				["Research Image"] = "",
				["Rarity"] = "Common",
				["Description"] = "This is a placeholder description for this research",
				
				["Research Length"] = 600,
				["Material Cost"] = {
					{RS.InventoryItems.Mining.Stone, 5}
				},
				["Experience Cost"] = {
					{experienceData["Skills"]["Mining Skill"], 3}
				},
				["Dependencies"] = {}
			},
			
			[6] = {
				["Research Name"] = "4th Tier Fuel Cell",
				["Research Image"] = "rbxassetid://6708256984",
				["Rarity"] = "Uncommon",
				["Description"] = "This is a placeholder description for this research",
				
				["Research Length"] = 1980,
				["Material Cost"] = {
					{RS.InventoryItems.Mining.Stone, 5}
				},
				["Experience Cost"] = {
					{experienceData["Skills"]["Mining Skill"], 3}
				},
				["Dependencies"] = {}
			},
			
			[7] = {
				["Research Name"] = "Fixed-Up Televator",
				["Research Image"] = "",
				["Rarity"] = "Common",
				["Description"] = "Your found a televator exit! Some stone and a small power source would get it running so you can start deeper in the mines.",
				
				["Research Length"] = 900,
				["Material Cost"] = {
					{RS.InventoryItems.Mining.Stone, 5},
					{RS.InventoryItems.Mining.Coal, 2}
				},
				["Experience Cost"] = {
					{experienceData["Skills"]["Mining Skill"], 3}
				},
				["Dependencies"] = {}
			},
			
			[8] = {
				["Research Name"] = "Tuned Conveyors",
				["Research Image"] = "rbxassetid://6708071453",
				["Rarity"] = "Uncommon",
				["Description"] = "Fixing the support walls and using a better lubricant will surely increase our conveyor speed!",
				
				["Research Length"] = 1800,
				["Material Cost"] = {
					{RS.InventoryItems.Mining.Stone, 5}
				},
				["Experience Cost"] = {
					{experienceData["Skills"]["Mining Skill"], 3}
				},
				["Dependencies"] = {}
			},
			
			[9] = {
				["Research Name"] = "Fuel Cells7",
				["Research Image"] = "rbxassetid://6708161904",
				["Rarity"] = "Legendary",
				["Description"] = "This is a placeholder description for this research",
				
				["Research Length"] = 300,
				["Material Cost"] = {
					{RS.InventoryItems.Mining.Stone, 5}
				},
				["Experience Cost"] = {
					{experienceData["Skills"]["Mining Skill"], 3}
				},
				["Dependencies"] = {}
			},

		},

		["Town Improvements"] = {
			["Research Type Name"] = "Town Research"
			
			
			
			
		},
		

	}
	
	
	

	
}

--Input research that have exp requirements as rewards in experience data
for _,researchType in pairs (ResearchData["Research"]) do
	local researchTypeName = researchType["Research Type Name"]
	
	for r = 1,#researchType,1 do
		if researchType[r] then
			local researchInfo = researchType[r]
			local expCostCount = #researchInfo["Experience Cost"]

			if expCostCount > 0 then
				for e = 1,expCostCount,1 do
					local statInfo = researchInfo["Experience Cost"][e][1]
					local levelRequired = researchInfo["Experience Cost"][e][2]

					local levelInfo = statInfo["Levels"][levelRequired]
					local expRewardTable = levelInfo["Rewards"]
					
					if #expRewardTable > 0 then
						local newRewardNumber = #expRewardTable+1
						if expRewardTable[#expRewardTable]["Research List"] == nil then
							expRewardTable[newRewardNumber] = {}
							expRewardTable[newRewardNumber]["Research List"] = {}
						else
							newRewardNumber -= 1
						end
						
						local researchList = expRewardTable[newRewardNumber]["Research List"]
						researchList[#researchList+1] = {
								["Research Image"] = researchInfo["Research Image"],
								["Research Name"] = researchInfo["Research Name"],
								["Research Type"] = researchTypeName
							}
					else
						expRewardTable[1] = {}
						expRewardTable[1]["Research List"] = {}
						
						local researchList = expRewardTable[1]["Research List"]
						researchList[1] = {
							["Research Image"] = researchInfo["Research Image"],
							["Research Name"] = researchInfo["Research Name"],
							["Research Type"] = researchTypeName
						}
					end
					
					--**Cloning the researchInfo tables directly to exp appears to slow the client down a lot
					--**TycoonStorage reached >20% Activity! Why?
				end
			end
		end
	end	
end
--print("Done putting all information from researchData into experienceData")
--print(experienceData)
--print(ResearchData)



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

