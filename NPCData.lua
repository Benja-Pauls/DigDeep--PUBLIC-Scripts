--(Module Script)
--Provides an overall table with nested tables of every NPC's important data. Stored in ServerStorage, accessed by PurchaseHandler
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local RS = game.ReplicatedStorage

local NPCData = {
	
	["Test Man"] = {
		
		["Shop Name"] = "Test Man's Test Shop",
		
		["ShopTheme"] = {
			["Primary Color"] = "PrimaryColorValue",
			["Secondary Color"] = "SecondaryColorValue"
			
		},
		
		["Voice"] = {
			--Do not include angry voice, kids playing may get scared
			
			--["Happy"] = #######,
			--["Sad"] = ######,
			["Neutral"] = 6467449877
		},
		
		["Face"] = {
			--["Happy"] = ImageId,
			--["Sad"] = ImageId,
			--["Neutral"] = ImageId			
		},
		
		["Dialogue"] = { --Does [index] need to be present?
			["Starters"] = {"Hello, I am Test Man!", "Hi There PLAYER!", "How can I help you?"},
			["Goodbyes"] = {"Goodbye!", "See you later PLAYER"},
			["Cannot Afford Item"] = {"Sorry, you need MISSINGFUNDS more to purchase the ITEM"},
			["Item Already Purchased"] = {"You already have the ITEM!"},
			["Thank You For Purchase"] = {"Thank you for your purchase!"},
			["Dialogue1"] = {"Hi There PLAYER! How are you doing today?", "I'm Test Man, welcome to my shop!", "I set up shop not too long ago"}
			
			
			--Player responses with shop keeper? (label as conversations?)
		},
		
		["Items"] = { --Sort by type (Rarity = ItemType)
			{RS.Equippable.Bags.OreBags["Beginner Ore Bag"], 4},
			{RS.Equippable.Bags.OreBags["Advanced Ore Bag"], 10},
			{RS.Equippable.Bags.PlantBags["Beginner Plant Bag"], 4},
			{RS.Equippable.Bags.PlantBags["Advanced Plant Bag"], 10},
			{RS.Equippable.Tools.Pickaxes.Pickaxe, 5},
			{RS.Equippable.Tools.Pickaxes["Orange Pickaxe"], 15}
			
		}	
	}	
	
	
	
	
}

--grab items directly from replicated storage so shop item inserter does not have the find them, it will only have
--to go through each element of this table to get item info to be displayed

return NPCData

