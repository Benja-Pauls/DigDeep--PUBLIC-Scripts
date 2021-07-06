--(Script)
--Script (Server-sided) so exploiters don't have access to sensitive information in this script: player location relative to block.
-----------------------------------------------------------------------------------------------------------------------------------------------
local Tool = script.Parent
local Player = script.Parent.Parent.Parent --Maybe set this more accordingly? SetTarget may mess up?

local ReplicatedStorage = game.ReplicatedStorage
local MineOre = ReplicatedStorage.Events.Utility:WaitForChild("MineOre")
local GetBagCount = ReplicatedStorage.Events.Utility:WaitForChild("GetBagCount")
local UpdateItemCount = ReplicatedStorage.Events.GUI:WaitForChild("UpdateItemCount")

--When the player barely hovers over the UI, the pickaxe mines continuously... mouse.target check must be getting confused

function Tool.SetTarget.OnServerInvoke(player,Selection)
	Tool.Target.Value = Selection
end

local equipType = Tool["GUI Info"].EquipType.Value
local itemType = Tool["GUI Info"].ItemType.Value
local itemName = Tool.Name
local equipmentData = require(game.ServerStorage.EquipmentData)
local ToolStats = equipmentData[equipType][itemType][itemName]

local MouseDown = false
local Debounce = true

local function FindStatValue(Table, StatName)
	for item = 1,#Table,1 do
		if Table[item][1] == StatName then
			return Table[item][2]
		end
	end
end

local function FindItemInfo(itemName)
	for _,itemType in pairs (ReplicatedStorage.InventoryItems:GetChildren()) do
		if itemType:FindFirstChild(itemName) then
			return itemType:FindFirstChild(itemName)
		end
	end	
end

--Start mining process, check player for any preventive measure before actually mining ore
local function StartMining()
	
	local Target = Tool.Target.Value
	if Debounce then
		repeat wait() until Player ~= nil
		if Target then --If player hasn't stopped mining/looking at an ore

			local itemName
			if Target.Name == "Target" then --Model represents object, not Part
				if Target.Parent then
					itemName = Target.Parent.Name
				end
			else
				itemName = Target.Name
			end
			
			if itemName then
				local ItemInfo = FindItemInfo(itemName)
				if ItemInfo then
					local ItemCount,BagCapacity,BagType = GetBagCount:Invoke(Player, ItemInfo)
					
					if ItemCount and BagCapacity then
						if ItemCount < BagCapacity then --If Bag is not full
							MouseDown = true
							Tool.IsMining.Value = true

							local TimeToMine = (ItemInfo.Strength.Value / FindStatValue(ToolStats["Stats"], "Dig Power"))
							local WaitTime = 0
							
							Debounce = false --Prevents mining to happen again until this block has been mined
							coroutine.resume(coroutine.create(function()
								wait(TimeToMine + FindStatValue(ToolStats["Stats"], "Mining Speed"))
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

							wait(FindStatValue(ToolStats["Stats"], "Mining Speed"))
							Debounce = true
							if MouseDown then --keep mining if mouse is still down
								StartMining()
							else
								Tool.IsMining.Value = false
							end
						else
							UpdateItemCount:FireClient(Player, ItemCount, BagCapacity, BagType)
						end
					else
						print("Player does not have a bag equipped!", Player, ItemCount, 0, BagType)
						UpdateItemCount:FireClient(Player, ItemCount, 0, BagType)
					end
				end
			else
				Tool.IsMining.Value = false
			end
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

