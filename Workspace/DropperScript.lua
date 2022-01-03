--(Script)
--"Droppers" are responsible for building passive wealth (they "drop" something that is collected, usually at the end of a conveyor belt like
--a factory)
----------------------------------------------------------------------------------------------------------------------------------------------
wait(2)
script.Parent.Parent.Parent:WaitForChild("TycoonDropStorage")

local dropperName = script.Parent.Name
local startValue = script.Parent:WaitForChild("StartValue")
local TycoonDropStorage = script.Parent.Parent.Parent:FindFirstChild("TycoonDropStorage")
	
while true do --Change to Levels.Changed or something, needs to be here for dropping

	local Levels = script.Parent.Upgrades:GetChildren()
	local currentUpgrade
	if #Levels ~= 0 then
		currentUpgrade = script.Parent.Upgrades:FindFirstChild("Upgrade"..#Levels)
	end
	
	--No Upgrades
	if currentUpgrade == nil then
		local part = game.ReplicatedStorage.Drops:FindFirstChild(dropperName).Default:Clone()
		local cash = Instance.new("IntValue",part)
		local drop = Instance.new("IntValue",part)
		part.Parent = TycoonDropStorage
		part.Name = "Part"
		cash.Name = "Cash"
		cash.Value = startValue.Value
		
		part.CFrame = script.Parent.Drop.CFrame - Vector3.new(0,1.1,0)
		game.Debris:AddItem(part,20)
		wait(tonumber(startValue.TimeInterval.Value)) -- How long in between drop
		
	else
		local Upgrade = "Upgrade" .. tostring(#Levels)
		local part = game.ReplicatedStorage.Drops:FindFirstChild(dropperName):FindFirstChild(Upgrade):Clone()
		local cash = Instance.new("IntValue",part)
		local drop = Instance.new("IntValue",part)
		part.Parent = TycoonDropStorage
		part.Name = "Part"
		cash.Name = "Cash"
		cash.Value = startValue.value * tonumber(currentUpgrade.Value)
		
		part.CFrame = script.Parent.Drop.CFrame - Vector3.new(0,1.1,0)
		game.Debris:AddItem(part,20)
		wait(tonumber(currentUpgrade.TimeInterval.Value))
	end

end

