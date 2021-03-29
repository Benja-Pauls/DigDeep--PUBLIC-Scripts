--(Module Script)
--Provides an overall table with nested tables of every NPC's important data. Stored in ServerStorage, accessed by PurchaseHandler
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local RS = game.ReplicatedStorage

local NPCData = {
	
	["Test Man"] = {
		
		["Shop Name"] = "Test Man's Test Shop",
		
		["Cannot Afford Item"] = ".......", --Table? Where indexes are next speech bubbles in dialogue?
		
		["Item Already Purchased"] = ".......", --Possibly put cannot afford and already purchased in basic dialogue
		
		["ShopTheme"] = {
			["Primary Color"] = "PrimaryColorValue",
			["Secondary Color"] = "SecondaryColorValue"
			
		},
		
		["Voice"] = {
			--Do not include angry voice, kids playing may get scared
			
			--["Happy"] = #######,
			--["Sad"] = ######,
			--["Neutral"] = ######
		},
		
		["Face"] = {
			--["Happy"] = ImageId,
			--["Sad"] = ImageId,
			--["Neutral"] = ImageId			
		},
		
		["Basic Dialogue"] = { --Does [index] need to be present?
			["Dialogue1"] = {"Hello, I am Test Man!", "Happy"},
			["Dialogue2"] = {"Hi There Stranger!", "Neutral"},
			["Dialogue3"] = {"Goodbye!", "Neutral"}
			--Does Lua use Table[-1]? Could have final index be goodbye statement string
		},
		
		["Conversations"] = {
			["Dialogue1"] = {"Hi There", "I'm Test Man"}
		}, 
		
		["Items"] = { --Sort by type (Rarity = ItemType)
			{RS.Equippable.Bags.OreBags["Beginner Bag"], 4},
			{RS.Equippable.Bags.OreBags["Beginner Bag"], 4},
			{RS.Equippable.Bags.OreBags["Advanced Bag"], 10},
			{RS.Equippable.Bags.PlantBags["Beginner Bag"], 4},
			{RS.Equippable.Bags.PlantBags["Advanced Bag"], 10},
			{RS.Equippable.Tools.Pickaxes.Pickaxe, 5}
			
		}	
	}	
	
	
	
	
}

--grab items directly from replicated storage so shop item inserter does not have the find them, it will only have
--to go through each element of this table to get item info to be displayed

return NPCData

