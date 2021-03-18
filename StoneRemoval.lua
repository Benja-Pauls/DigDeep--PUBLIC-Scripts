--(Script)
--Simple dev test script that removes all stone the player has in their inventory
-----------------------------------------------------------------------------------------------------------------------------------------------

local StoneRemovalButton = game.Workspace:WaitForChild("StoneRemoval")
local UpdateInventory = game.ReplicatedStorage.Events.GUI:FindFirstChild("UpdateInventory")
local PlayerStatManager = require(game.ServerScriptService:FindFirstChild("PlayerStatManager"))

local debounce = false
StoneRemovalButton.Touched:Connect(function(hit)
	if debounce == false then
		debounce = true
		local PlayerName = hit.Parent
		local Player = game.Players:FindFirstChild(tostring(hit.Parent))
		local PlayerFile = game.ServerStorage.PlayerData:FindFirstChild(Player.UserId)
		local OreMenu = PlayerFile.Inventory.Ores
		
		OreMenu.Stone.Value = 0
		UpdateInventory:FireClient(Player, "Stone", "Ores", 0)
		PlayerStatManager:ChangeStat(Player, "Stone", 0, "Inventory","Zero")
		wait(.5)
		debounce = false
	end
end)

