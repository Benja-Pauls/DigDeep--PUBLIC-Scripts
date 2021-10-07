--(Script)
--Responsible for autosaving (at bottom, will probably be moved), and purchase management (called buttons)
----------------------------------------------------------------------------------------------------------------------------------------
local PlayerStatManager = require(game.ServerScriptService:WaitForChild("PlayerStatManager"))
local AllResearchData = require(game.ServerStorage:WaitForChild("ResearchData"))

local TycoonsFolder = game.Workspace:WaitForChild("Tycoons")
local Tycoons = TycoonsFolder:GetChildren() --All teams in the game

local ServerStorage = game:GetService("ServerStorage")
local PlayerData = ServerStorage:WaitForChild("PlayerData")
local TycoonAssetsHandler = script:WaitForChild("TycoonAssetsHandler")
local players = game:GetService("Players")
local SpecialBuy = game.ServerScriptService:WaitForChild("TycoonSpecialBuys")
local GateControl = script:WaitForChild("GateControl")

local LoadTycoon = game:GetService("ReplicatedStorage").Events.Tycoon.LoadTycoon
local ClaimTycoon = game:GetService("ReplicatedStorage").Events.Tycoon.ClaimTycoon

------------<|Tycoon Setup and Reseting|>---------------------------------
local TycoonTable = {}

for _,tycoon in pairs (Tycoons) do
	if tycoon:IsA("Model") then
		Instance.new('Model',tycoon).Name = "TycoonDropStorage"
		TycoonTable[tycoon.Name] = tycoon:Clone()
	end
end

local TycoonPurchases = game.ReplicatedStorage:WaitForChild("TycoonPurchases")
local Droppers = TycoonPurchases:FindFirstChild("Dropper")
local DropperScript = script.DropperScript

for _,dropper in pairs (Droppers:GetChildren()) do
	if dropper:FindFirstChild("DropperScript") == nil then
		local DropScriptClone = DropperScript:Clone()
		DropScriptClone.Parent = dropper
		DropScriptClone.Disabled = false
	end
end

function getPlrTycoon(player)
	for _,tycoon in pairs(Tycoons) do
		if tycoon:IsA("Model") then
			if tycoon.Owner.Value == player then
				return tycoon
			end
		end
	end
end

--Destroy tycoon when player leaves
game.Players.PlayerRemoving:connect(function(player)
	
	--**Will likely expand to restart entire tycoon island, unless that is all encapsulated under tycoon
	
	--Remove the tycoon when the player leaves
	local tycoon = getPlrTycoon(player)
	if tycoon then
		local backup = TycoonTable[tycoon.Name]:Clone()
		tycoon:Destroy() --Destroy the player's tycoon when they leave
		wait()
		backup.Parent = Tycoons --put the default tycoon in the tycoons folder
	end
end)

--Hide buttons from previous games
local function HideButton(Name, Buttons)
	local item 
	for _,button in pairs (Buttons) do
		if button.Object.Value == Name then
			item = button
		end
	end

	if item ~= nil then 
		local buttonCheck = item:FindFirstChild("Object")
		if buttonCheck then 
			coroutine.resume(coroutine.create(function() --call and create a function
				local ButtonParts = item:FindFirstChild("ButtonModel"):GetChildren()
				for bp = 1,#ButtonParts,1 do
					ButtonParts[bp].Transparency = 1
					item.CanCollide = false
				end
			end))
			
			if item:FindFirstChild("Dependencies") ~= nil then
				wait(item.Visible.Value == true) --Wait for dependencies to declare visibility
			end
			item.Visible.Value = false
		else
			warn("Button (" .. tostring(item) .. ") doesn't have an affiliated object")
		end
	end
end

local function PositionPurchase(buttons, object)
	if object:FindFirstChild("Root") ~= nil then
		object.PrimaryPart = object.Root
												
		local ModelPosition = buttons:FindFirstChild("PrimaryPartPosition")
		object.PrimaryPart.Orientation = ModelPosition.Orientation
		object:SetPrimaryPartCFrame(CFrame.new(ModelPosition.Position))
	
		ModelPosition:Destroy()
		object.PrimaryPart:Destroy()
	end
end

local function PrepareTycoon(tycoon)
	local PurchasedObjects = tycoon:WaitForChild("PurchasedObjects")
	local owner = tycoon:WaitForChild("Owner")
		
	local touchToClaimHead = tycoon.Entrance:WaitForChild("Touch to Begin Construction!").Head
	if touchToClaimHead.Parent:FindFirstChild("GateControl") == nil then
		local GateControlClone = GateControl:Clone()
		GateControlClone.Parent = touchToClaimHead.Parent
		GateControlClone.Disabled = false
	end
	if tycoon:FindFirstChild("TycoonAssetsHandler") == nil then
		TycoonAssetsHandler:Clone().Parent = tycoon
	end	
	if tycoon:FindFirstChild("TycoonSpecialBuys") == nil then
		SpecialBuy:Clone().Parent = tycoon
	end
	local TycoonAssetsHandler = require(tycoon.TycoonAssetsHandler) --Tycoon's possible purchases (table)
		
	for _,destroyModel in pairs (tycoon.DemolishedObjects:GetChildren()) do
		destroyModel.Transparency = 0
	end
	
	--Load data
	local TycoonPurchased = false
	touchToClaimHead.Touched:Connect(function(hit)
		local HitPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
		
		LoadTycoon.OnServerEvent:Connect(function(player, tycoon)
			if tycoon == tycoon and not TycoonPurchased then --Check to make sure repeat isnt happening because of this
				if owner.Value == player and HitPlayer == player then
					local PlayerClaimHead = tycoon.Entrance:FindFirstChild("Touch to Begin Construction!").Head
					local PlayerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
					local OwnsTycoon = PlayerDataFile:FindFirstChild("OwnsTycoon")

					if OwnsTycoon ~= nil and OwnsTycoon.Value == tycoon then
						PlayerClaimHead.Transparency = 1
						TycoonPurchased = true
						
						if player ~= nil and PlayerClaimHead ~= nil then
							local Data = PlayerStatManager:getPlayerData(player)
							
							for key,rType in pairs (AllResearchData["Research"]) do --Load previously completed research
								for i,r in pairs (rType) do
									if rType[i] then
										local Research = rType[i]
										if PlayerStatManager:getStat(player, Research["Research Name"]) == true then
											local ResearchReference = Instance.new("Model", tycoon.CompletedResearch)
											ResearchReference.Name = Research["Research Name"]
										end
									end
								end
							end
							
							local Buttons = tycoon.Buttons:GetChildren()
							for key, object in pairs (TycoonAssetsHandler) do --Load previously purchased objects
								if Data[key] == true then --Looking through sessionData if object bought
									local ObjectName = key
									for _,v in pairs(Buttons) do
										if v.Object.Value == ObjectName then
											PositionPurchase(v, object)
											object.Parent = PurchasedObjects
										else
											wait()
										end
									end
									HideButton(ObjectName, Buttons)
									--print(key, " has been bought in a previous game session because data = " .. tostring(Data[key]))
								--else
									--print(tostring(object).." hasn't been bought for " .. tostring(tycoon) .. " because data = " .. tostring(Data[key]))
								end
							end
							
							wait(2) --"Pressing" previously purchased 
							print(tostring(player) .. " is now the owner of " .. tostring(tycoon))
						end
					else
						warn(tostring(player) .. " already owns a tycoon! (" .. tostring(tycoon) .. ")")
					end
				else
					warn("Player == nil or " .. tostring(tycoon) .. " has already been purchased")
				end
			end
			print("TYCOON DATA LOADED FOR: " .. tostring(owner.Value))
		end)
	end)
	
	--Save Pressed Buttons
	if PurchasedObjects ~= nil and owner ~= nil then
		PurchasedObjects.ChildAdded:Connect(function(instance)
			local player = tostring(owner.Value)
			
			if player ~= nil then
				local bought = PlayerStatManager:getStat(player, instance.Name)
				if bought == false then --if not already bought
					--print("Button (" .. tostring(instance) .. ") will be saved")
					PlayerStatManager:ChangeStat(player, instance.Name, true)
				end
			end
		end)
	else
		error("PurchasedObjects or Tycoon Owner are nil")
	end
end

for _,tycoon in pairs (Tycoons) do
	PrepareTycoon(tycoon)
end

TycoonsFolder.ChildAdded:Connect(function(Tycoon)
	PrepareTycoon(Tycoon)	
end)

--Autosave every ~60 seconds
while wait(59) do
	pcall(function()
		print("AutoSaving All Player Progress...")
		for _,player in pairs (players:GetChildren()) do
			if player ~= nil then --if still in game
				local playerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
				local playerMoney = playerDataFile:FindFirstChild("Currencies"):FindFirstChild("UniversalCurrencies"):FindFirstChild("Coins")
				
				if playerMoney then 
					PlayerStatManager:initiateSaving(player, "Coins", playerMoney.Value)
				end
			end
		end
	end)
end

