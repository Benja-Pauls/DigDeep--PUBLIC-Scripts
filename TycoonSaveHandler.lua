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
local Players = game:GetService("Players")
local SpecialBuy = game.ServerScriptService:WaitForChild("TycoonSpecialBuys")
local GateControl = script:WaitForChild("GateControl")

local LoadTycoon = game:GetService("ReplicatedStorage").Events.Tycoon.LoadTycoon
local ClaimTycoon = game:GetService("ReplicatedStorage").Events.Tycoon.ClaimTycoon

local allObjects = {}

--Hide buttons from previous games
local function HideButton(Name, Buttons)
	local Item 
	for i,button in pairs (Buttons) do
		if button.Object.Value == Name then
			Item = button
		end
	end

	if Item ~= nil then 
		local buttonCheck = Item:FindFirstChild("Object")
		if buttonCheck then 
			coroutine.resume(coroutine.create(function() --call and create a function
				local ButtonParts = Item:FindFirstChild("ButtonModel"):GetChildren()
				for bp = 1,#ButtonParts,1 do
					ButtonParts[bp].Transparency = 1
					Item.CanCollide = false
				end
			end))
			
			if Item:FindFirstChild("Dependencies") ~= nil then
				wait(Item.Visible.Value == true) --Wait for dependencies to declare visibility
			end
			Item.Visible.Value = false
		else
			warn("Button (" .. tostring(Item) .. ") doesn't have an affiliated object")
		end
	end
end

local function PositionPurchase(Buttons, Object)
	if Object:FindFirstChild("Root") ~= nil then
		Object.PrimaryPart = Object.Root
												
		local ModelPosition = Buttons:FindFirstChild("PrimaryPartPosition")
		Object.PrimaryPart.Orientation = ModelPosition.Orientation
		Object:SetPrimaryPartCFrame(CFrame.new(ModelPosition.Position))
	
		ModelPosition:Destroy()
		Object.PrimaryPart:Destroy()
	end
end

local function PrepareTycoon(Tycoon)
	local PurchasedObjects = Tycoon:WaitForChild("PurchasedObjects")
	local Owner = Tycoon:WaitForChild("Owner")
		
	local touchToClaimHead = Tycoon.Entrance:WaitForChild("Touch to Begin Construction!").Head
	if touchToClaimHead.Parent:FindFirstChild("GateControl") == nil then
		local GateControlClone = GateControl:Clone()
		GateControlClone.Parent = touchToClaimHead.Parent
		GateControlClone.Disabled = false
	end
	if Tycoon:FindFirstChild("TycoonAssetsHandler") == nil then
		TycoonAssetsHandler:Clone().Parent = Tycoon
	end	
	if Tycoon:FindFirstChild("TycoonSpecialBuys") == nil then
		SpecialBuy:Clone().Parent = Tycoon
	end
	local TycoonAssetsHandler = require(Tycoon.TycoonAssetsHandler) --Tycoon's possible purchases (table)
		
	for i,destroyModel in pairs (Tycoon.DemolishedObjects:GetChildren()) do
		destroyModel.Transparency = 0
	end
	
	--Load data
	local TycoonPurchased = false
	touchToClaimHead.Touched:Connect(function(hit)
		local HitPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
		
		LoadTycoon.OnServerEvent:Connect(function(player, tycoon)
			if tycoon == Tycoon and not TycoonPurchased then --Check to make sure repeat isnt happening because of this
				if tycoon.Owner.Value == player and HitPlayer == player then
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
											local ResearchReference = Instance.new("Model", Tycoon.CompletedResearch)
											ResearchReference.Name = Research["Research Name"]
										end
									end
								end
							end
							
							local Buttons = Tycoon.Buttons:GetChildren()
							for key, object in pairs (TycoonAssetsHandler) do --Load previously purchased objects
								if Data[key] == true then --Looking through sessionData if object bought
									local ObjectName = key
									for i,v in pairs(Buttons) do
										if v.Object.Value == ObjectName then
											PositionPurchase(v, object)
											object.Parent = PurchasedObjects
										else
											wait()
										end
									end
									HideButton(ObjectName, Buttons)
									--print(key, " has been bought in a previous game session because data = " .. tostring(Data[key]))
								else
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
			print("TYCOON DATA LOADED FOR: " .. tostring(Owner.Value))
		end)
	end)
	
	--Save Pressed Buttons
	if PurchasedObjects ~= nil and Owner ~= nil then
		PurchasedObjects.ChildAdded:Connect(function(instance)
			local player = tostring(Owner.Value)
			
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

for i,tycoon in pairs (Tycoons) do
	--print("Preparing",tycoon)
	PrepareTycoon(tycoon)
end

TycoonsFolder.ChildAdded:Connect(function(Tycoon)
	PrepareTycoon(Tycoon)	
end)

--Autosave every ~60 seconds
while wait(59) do
	pcall(function()
		print("AutoSaving All Player Progress...")
		local allPlayers = Players:GetChildren()
		for i,player in pairs (Players:GetChildren()) do
			if player ~= nil then
				local PlayerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
				local PlayerMoney = PlayerDataFile:FindFirstChild("Currencies"):FindFirstChild("UniversalCurrencies"):FindFirstChild("Currency")
				if PlayerMoney then 
					PlayerStatManager:initiateSaving(player, "Currency", PlayerMoney.Value)
					 --Initiate saving process by saving player money, then save other player data
				end
			end
		end
	end)
end

