--(Script)
--Script (Server-sided) so exploiters don't have access to sensitive information in this script: player location relative to block.
-----------------------------------------------------------------------------------------------------------------------------------------------
local Tool = script.Parent
local Player = script.Parent.Parent.Parent --Maybe set this more accordingly? SetTarget may mess up?

local ReplicatedStorage = game.ReplicatedStorage
local MineshaftItems = ReplicatedStorage.ItemLocations.Mineshaft
local MineOre = ReplicatedStorage.Events.Utility:WaitForChild("MineOre")
local GetBagCount = ReplicatedStorage.Events.Utility:WaitForChild("GetBagCount")
local WarnBagCapacity = ReplicatedStorage.Events.GUI:WaitForChild("WarnBagCapacity")

--When the player barely hovers over the UI, the pickaxe mines continuously... mouse.target check must be getting confused

function Tool.SetTarget.OnServerInvoke(player,Selection)
	Tool.Target.Value = Selection
end

local ToolStats = require(Tool:WaitForChild(tostring(Tool) .. "Stats"))

local MouseDown = false
local Debounce = true

local function FindStatValue(Table, StatName)
	for item = 1,#Table,1 do
		if Table[item][1] == StatName then
			return Table[item][2]
		end
	end
end

local function FindItemInfo(ItemName)
	local ItemInformation
	for i,location in pairs (ReplicatedStorage.ItemLocations:GetChildren()) do
		if location:FindFirstChild(ItemName) then
			ItemInformation = location:FindFirstChild(ItemName)
		end
	end	
	return ItemInformation
end

--Start mining process, check player for any preventive measure before actually mining ore
local function StartMining()
	
	local Target = Tool.Target.Value
	if Debounce then
		repeat wait() until Player ~= nil
		if Target then --If player hasn't stopped mining/looking at an ore

			local ItemName
			if Target.Name == "Target" then --Model represents object, not Part
				ItemName = Target.Parent.Name
			else
				ItemName = Target.Name
			end
			
			local ItemInfo = FindItemInfo(ItemName)
			if ItemInfo then
				local ItemCount,BagCapacity = GetBagCount:Invoke(Player, ItemInfo)
				
				if ItemCount and BagCapacity then
					if ItemCount < BagCapacity then --If Bag is not full
						MouseDown = true
						Tool.IsMining.Value = true

						local TimeToMine = (ItemInfo.Strength.Value / FindStatValue(ToolStats["Stats"], "PickaxeEfficiency"))
						local WaitTime = 0
						
						Debounce = false --Prevents mining to happen again until this block has been mined
						coroutine.resume(coroutine.create(function()
							wait(TimeToMine + FindStatValue(ToolStats["Stats"], "PickaxeDelay"))
							Debounce = true
						end))
						
						repeat
							wait(0.01)
							WaitTime = WaitTime + 0.01
							
							Target.Reflectance = WaitTime/TimeToMine --use target's reflectance as reference across scripts
							--print("Progress: " .. tostring(Target.Reflectance))
						until WaitTime >= TimeToMine or not MouseDown or Target ~= Tool.Target.Value
						
						local mined = true
						if WaitTime >= TimeToMine and mined then
							MineOre:Fire(Player, Target)
							mined = false
						else
							Target.Reflectance = 0
						end

						wait(FindStatValue(ToolStats["Stats"], "PickaxeDelay"))
						Debounce = true
						if MouseDown then --keep mining if mouse is still down
							StartMining()
						else
							Tool.IsMining.Value = false
						end
					else
						WarnBagCapacity:FireClient(Player)
					end
				else
					print("Player does not have a bag equipped!")
				end
			end
		else
			Tool.IsMining.Value = false
		end
	end
end

Tool.Activation.OnServerEvent:Connect(function(player, State)
	if player == Player then
		if State and not MouseDown then --if state sent is true and player isn't already mining, start mining
			MouseDown = true
			StartMining()
		else
			MouseDown = false
			Tool.IsMining.Value = false
		end
	end
end)

Tool.Unequipped:Connect(function()
	MouseDown = false
	Tool.IsMining.Value = false
end)

