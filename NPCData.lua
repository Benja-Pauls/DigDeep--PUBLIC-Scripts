--(Module Script)
--Provides an overall table with nested tables of every NPC's important data. Stored in ServerStorage, accessed by PurchaseHandler
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local RS = game.ReplicatedStorage

local NPCData = {
	
	["Test Man"] = {
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
			["Dialogue1"] = {[1]="Hello, I am Test Man!", [2]="Happy"},
			["Dialogue2"] = {[1]="Hi There Stranger!", [2]="Neutral"},
			["Dialogue3"] = {[1]="Goodbye!", [2]="Neutral"}
			--Does Lua use Table[-1]? Could have final index be goodbye statement string
		},
		
		["Conversations"] = {
			["Dialogue1"] = {[1]="Hi There", [2]="I'm Test Man"}
		}, 
		
		["Items"] = {
			RS.Equippable.Bags.OreBags["Advanced Bag"],
			RS.Equippable.Bags.PlantBags["Advanced Bag"]
			
		}	
	}	
	
	
	
	
}




--grab items directly from replicated storage so shop item inserter does not have the find them, it will only have
--to go through each element of this table to get item info to be displayed

return NPCData
