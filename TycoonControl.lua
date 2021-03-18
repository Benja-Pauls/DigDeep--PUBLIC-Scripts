--(Script)
--Initial set-up and model managment for leaving and joining players (updating "plots" with model data)

----------------------------------------------------------------------------------------------------------------------------------------------
local TycoonTable = {}
local TeamService = game:GetService('Teams')

local Tycoons = script.Parent.Tycoons:GetChildren()

local PlayerData = game:GetService("ServerStorage"):FindFirstChild("PlayerData")
local PlayerStatManager = require(game.ServerScriptService:WaitForChild("PlayerStatManager"))

for i,tycoon in pairs (workspace["Tycoon Game"]:WaitForChild("Tycoons"):GetChildren()) do
	if tycoon:IsA("Model") then
		Instance.new('Model',tycoon).Name = "TycoonDropStorage"
	end
end

--Initial Team
local teamHire = Instance.new('Team', TeamService)
teamHire.TeamColor = BrickColor.new('White')
teamHire.Name = "Prospectors"


for i,v in pairs(script.Parent:WaitForChild('Tycoons'):GetChildren()) do
	TycoonTable[v.Name] = v:Clone()

	local tycoonTeam = Instance.new('Team',TeamService)
	tycoonTeam.Name = v.Name 
	tycoonTeam.TeamColor = v.TeamColor.Value 
	tycoonTeam.AutoAssignable = false
end

local TycoonPurchases = game.ReplicatedStorage:WaitForChild("TycoonPurchases")
local Droppers = TycoonPurchases:FindFirstChild("Dropper")
local DropperScript = script.Parent:WaitForChild("TycoonSaveHandler").DropperScript
for i, dropper in pairs (Droppers:GetChildren()) do
	if dropper:FindFirstChild("DropperScript") == nil then
		local DropScriptClone = DropperScript:Clone()
		DropScriptClone.Parent = dropper
		DropScriptClone.Disabled = false
	end
end

function getPlrTycoon(player)
	for i,v in pairs(script.Parent.Tycoons:GetChildren()) do
		if v:IsA("Model") then
			if v.Owner.Value == player then
				return v
			end
		end
	end
	--return nil 
end

--When player leaves
game.Players.PlayerRemoving:connect(function(player)

	--Remove the tycoon when the player leaves
	local tycoon = getPlrTycoon(player)
	if tycoon then
		local backup = TycoonTable[tycoon.Name]:Clone()
		tycoon:Destroy() --Destroy the player's tycoon when they leave
		wait()
		backup.Parent=script.Parent.Tycoons --put the default tycoon in the tycoons folder
	end

end)
