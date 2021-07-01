local RS = game.ReplicatedStorage

local NPCData = {
	
	["Test Man"] = {
		
		["Shop Name"] = "Test Man's Test Shop",
		["Shop Type"] = "Mining Supplies",
		
		["ShopTheme"] = {
			["Primary Color"] = {R=179,G=179,B=179},
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
			{RS.Equippable.Bags.MaterialBags["Beginner Bag"], 55, "Coins"},
			{RS.Equippable.Bags.MaterialBags["Advanced Bag"], 100, "Coins"},
			--{RS.Equippable.Bags.PlantBags["Beginner Plant Bag"], 4},
			--{RS.Equippable.Bags.PlantBags["Advanced Plant Bag"], 10},
			{RS.Equippable.Tools.Pickaxes.Pickaxe, 5, "Coins"},
			{RS.Equippable.Tools.Pickaxes["Orange Pickaxe"], 15, "Coins"},
			{RS.Equippable.Tools.Pickaxes["Glow Pickaxe"], 1200, "Coins"}
		}	
	}	
	
	
	
	
}

--grab items directly from replicated storage so shop item inserter does not have the find them, it will only have
--to go through each element of this table to get item info to be displayed

return NPCData
