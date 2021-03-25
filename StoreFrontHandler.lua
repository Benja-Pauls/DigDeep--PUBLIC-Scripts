--(Local Script)
--Handles Shop Keeper NPC data to fill player's StoreFrontGui once they interact with an NPC
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local UpdateStoreFront = game.ReplicatedStorage.Events.GUI:WaitForChild("UpdateStoreFront")
local StoreFrontGui = script.Parent

UpdateStoreFront.OnClientEvent:Connect(function(NPC, npcData)
	--Interacted with Shop Keeper NPC, grabbed NPC data from PurchaseHandler, now display shop info
	
	--Continue to hide players that are nearby until the player exits the store front
	
	--Prevent player from moving
	
	--Move camera into position, use transition screen to hide GUI being updated
	
	local Items = npcData["Items"]
	
	--Show all storefront basic information like NPC name, store name, etc.
	
	for item = 1,#Items,1 do
		local Item = Items[item][1]
		local Price = Items[item][2]
		
		print(Item,Price)
			
			
			
	end
		
	--Show items in frames
	--Page system? (horizontal long boxes like paint file, or tiles?)
	
	--This function will be used to show the storefront information for the NPC that was interacted with, using
	--the npc data (and therefore item data) to fill the tiles of the StoreFront GUI
	
	--NPC will be used to physical change his face, produce sounds, and play animations while shopping
end)

--Display the selected item's 3D Model rotating in the middle








