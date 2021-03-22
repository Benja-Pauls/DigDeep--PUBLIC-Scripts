--(Local Script)
--Handles Shop Keeper NPC data to fill player's StoreFrontGui once they interact with an NPC
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local UpdateStoreFront = game.ReplicatedStorage.Events.GUI:WaitForChild("UpdateStoreFront")
local StoreFrontGui = script.Parent

UpdateStoreFront.OnClientEvent:Connect(function(NPC, npcData)
	local Items = npcData["Items"]
	print(tostring(NPC))
	
	for i = 1,#Items,1 do
		print(Items[i])
	end
	
	--This function will be used to show the storefront information for the NPC that was interacted with, using
	--the npc data (and therefore item data) to fill the tiles of the StoreFront GUI
	
	--NPC will be used to physical change his face, produce sounds, and play animations while shopping
end)






