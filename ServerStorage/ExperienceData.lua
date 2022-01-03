local RS = game.ReplicatedStorage

local ExperienceData = {
	
	["Skills"] = {
		["StatTypeName"] = "Skills",
		
		["Mining Skill"] = {
			["StatName"] = "Mining Skill",
			["StatType"] = "Skills",
			["Description"] = "",
			["StatImage"] = "rbxassetid://7112102140",
			["PrimaryColor"] = Color3.fromRGB(108, 108, 108),
			["SecondaryColor"] = Color3.fromRGB(175, 175, 175),
			["ThirdColor"] = Color3.fromRGB(57, 57, 57),
			
			["Levels"] = {
				[1] = {
					["Level Name"] = "Newcomer",
					["Exp Requirement"] = 0,
					["Rewards"] = {}
				},
				[2] = {
					["Level Name"] = "Learner",
					["Exp Requirement"] = 5,
					["Rewards"] = {}
				},
				[3] = {
					["Level Name"] = "Apprentice",
					["Exp Requirement"] = 25,
					["Rewards"] = {
						[1] = {"Item", RS.InventoryItems.Mining.Coal, 20}
					}
				},
				[4] = {	
					["Level Name"] = "Miner",
					["Exp Requirement"] = 100,
					["Rewards"] = {}
				},
				[5] = {
					["Level Name"] = "Geologist",
					["Exp Requirement"] = 250,
					["Rewards"] = {
						[1] = {"Item", RS.InventoryItems.Foraging["Glow Shroom"], 10},
						[2] = {"Equipment", RS.Equippable.Tools.Pickaxes["Exp Reward Pickaxe"]},
					}
				},
				[6] = {	
					["Level Name"] = "",
					["Exp Requirement"] = 500,
					["Rewards"] = {}
				},
				[7] = {	
					["Level Name"] = "",
					["Exp Requirement"] = 1000,
					["Rewards"] = {}
				},
				[8] = {
					["Level Name"] = "HellDiver",
					["Exp Requirement"] = 2000,
					["Rewards"] = {}
				},
				[9] = {	
					["Level Name"] = "",
					["Exp Requirement"] = 5000,
					["Rewards"] = {}
				},
				[10] = {
					["Level Name"] = "",
					["Exp Requirement"] = 10000,
					["Rewards"] = {}
				}
			},	
		},
		
		["Foraging Skill"] = {
			["StatName"] = "Foraging Skill",
			["StatType"] = "Skills",
			["Description"] = "",
			["StatImage"] = "",
			["PrimaryColor"] = Color3.fromRGB(108, 108, 108),
			["SecondaryColor"] = Color3.fromRGB(175, 175, 175),
			["ThirdColor"] = Color3.fromRGB(57, 57, 57),
			
			["Levels"] = {
				[1] = {
					["Level Name"] = "Newcomer",
					["Exp Requirement"] = 0,
					["Rewards"] = {}
				},
				[2] = {
					["Level Name"] = "Learner",
					["Exp Requirement"] = 5,
					["Rewards"] = {}
				},
				[3] = {
					["Level Name"] = "Greenhorn",
					["Exp Requirement"] = 25,
					["Rewards"] = {}
				},
				[4] = {	
					["Level Name"] = "Forager",
					["Exp Requirement"] = 100,
					["Rewards"] = {}
				},
				[5] = {
					["Level Name"] = "Botanist",
					["Exp Requirement"] = 250,
					["Rewards"] = {}
				},
				[6] = {	
					["Level Name"] = "",
					["Exp Requirement"] = 500,
					["Rewards"] = {}
				},
				[7] = {	
					["Level Name"] = "",
					["Exp Requirement"] = 1000,
					["Rewards"] = {}
				},
				[8] = {
					["Level Name"] = "",
					["Exp Requirement"] = 2000,
					["Rewards"] = {}
				},
				[9] = {	
					["Level Name"] = "",
					["Exp Requirement"] = 5000,
					["Rewards"] = {}
				},
				[10] = {
					["Level Name"] = "",
					["Exp Requirement"] = 10000,
					["Rewards"] = {}
				}
			},
		},	
	},
	
	
	["Arcade Levels"] = {
		["StatTypeName"] = "Arcade Levels",
		
		
		
		
		
		
		
	},
	
	["Reputation"] = {
		["StatTypeName"] = "Reputation",
		
		
		
		--Possibly put reputation in a later update?
		--It may be too many things to think about when interacting with NPCs (they already have 2 exp types to worry about)
		
		
		
	},
	
	
}





return ExperienceData

