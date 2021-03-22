--(Script)
--Responsible for autosaving (at bottom, will probably be moved), and purchase management (called buttons)
----------------------------------------------------------------------------------------------------------------------------------------
local PlayerStatManager = require(game.ServerScriptService:WaitForChild("PlayerStatManager"))

local tycoonsFolder = game.Workspace:WaitForChild("Tycoons")
local tycoons = tycoonsFolder:GetChildren() --All teams in the game

local serverStorage = game:GetService("ServerStorage")
local PlayerData = serverStorage:WaitForChild("PlayerData")
local tycoonAssetsHandler = script:WaitForChild("TycoonAssetsHandler")
local players = game:GetService("Players")
local specialBuy = game.ServerScriptService:WaitForChild("TycoonSpecialBuys")
local GateControl = script:WaitForChild("GateControl")

local LoadTycoon = game:GetService("ReplicatedStorage").Events.Tycoon.LoadTycoon
local ClaimTycoon = game:GetService("ReplicatedStorage").Events.Tycoon.ClaimTycoon

local allObjects = {}

--Hide buttons from previous games
local function hideButton(name,buttons)
	local allButtons = buttons:GetChildren() 
	
	local item 
	for i = 1,#allButtons,1 do 
		if allButtons[i].Object.Value == name then 
			item = allButtons[i] --item = button name (Example: Buy Dropper1 - [$70])
		end
	end
	
	if item ~= nil then 
		local buttonCheck = item:FindFirstChild("Object")
		if buttonCheck ~= nil then 
			coroutine.resume(coroutine.create(function() --call and create a function
				local ButtonParts = item.Model:GetChildren()
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
			print("Button: " .. tostring(item) .. " doesn't have an affiliated object")
		end
	end
end

local function PositionPurchase(Buttons, Object, PurchasedObjects)
	if Object:FindFirstChild("Root") ~= nil then
		Object.PrimaryPart = Object.Root
												
		local ModelPosition = Buttons:FindFirstChild("PrimaryPartPosition")
		Object.PrimaryPart.Orientation = ModelPosition.Orientation
		Object:SetPrimaryPartCFrame(CFrame.new(ModelPosition.Position))
	
		ModelPosition:Destroy()
		Object.PrimaryPart:Destroy()
	end
	Object.Parent = PurchasedObjects
end

local function PrepareTycoon(Tycoon)
	local purchasedObjects = Tycoon:WaitForChild("PurchasedObjects")
	local owner = Tycoon:WaitForChild("Owner")
		
	local touchToClaimHead = Tycoon.Entrance:FindFirstChild("Touch to Begin Construction!").Head
	if touchToClaimHead.Parent:FindFirstChild("GateControl") == nil then
		local GateControlClone = GateControl:Clone()
		GateControlClone.Parent = touchToClaimHead.Parent
		GateControlClone.Disabled = false
	end
		
	local DestroyableModel = Tycoon.DemolishedObjects:GetChildren()
	for d = 1,#DestroyableModel,1 do
		DestroyableModel[d].Transparency = 0
	end
		
	if Tycoon:FindFirstChild("TycoonAssetsHandler") == nil then
		tycoonAssetsHandler:Clone().Parent = Tycoon
	end
		
	if Tycoon:FindFirstChild("TycoonSpecialBuys") == nil then
		specialBuy:Clone().Parent = Tycoon
	end
	
	local TycoonAssetsHandler = require(Tycoon.TycoonAssetsHandler) --Tycoon's possible purchases (table)
		
	--Load data
	local debounce = true
	touchToClaimHead.Touched:Connect(function(hit)
		local HitPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
		LoadTycoon.OnServerEvent:Connect(function(player,tycoon)
			--print("First LoadTycoon Remote Event Called") --Should be called only for original tycoons
			if debounce == true then
				if tycoon.Owner.Value == player and HitPlayer == player then
					local PlayerClaimHead = tycoon.Entrance:FindFirstChild("Touch to Begin Construction!").Head
					local PlayerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
					local ownsTycoon = PlayerDataFile:FindFirstChild("OwnsTycoon")
		
					if ownsTycoon ~= nil and ownsTycoon.Value == tycoon then
						PlayerClaimHead.Transparency = 1
						debounce = false
						
						if player ~= nil and PlayerClaimHead ~= nil then
							--Load previously purchased objects
							local data = PlayerStatManager:getPlayerData(player)
							
							for key, object in pairs(TycoonAssetsHandler) do
								if data[key] == true then --Looking through sessionData table in Playerstat manager for dropper name
									local Buttons = Tycoon.Buttons:GetChildren()
									for i,v in pairs(Buttons) do
										if v.Object.Value == key then
											PositionPurchase(v,object,purchasedObjects)
										else
											wait()
										end
									end
								else
									print(tostring(object).." hasn't been bought for " .. tostring(tycoon) .. " because data = " .. tostring(data[key]))
								end
							end
							wait(2) --"Pressing" previously purchased 
							for key,v in pairs (TycoonAssetsHandler) do
								if data[key] == true then
									local buttonName = key
									local buttons = Tycoon.Buttons
									print("HIDING BUTTON FOR",v)
									hideButton(buttonName,buttons)
								end
							end
							print(tostring(player) .. " is now the owner of " .. tostring(tycoon))
						end
					else
						print(tostring(player) .. " already owns a tycoon! (" .. tostring(tycoon) .. ")")
					end
				else
					print("Player == nil or " .. tostring(tycoon) .. " has already been purchased")
				end
			end
		end)
	end)
	
	--Save Pressed Buttons
	if purchasedObjects ~= nil and owner ~= nil then
		purchasedObjects.ChildAdded:Connect(function(instance)
			local player = tostring(owner.Value)
			--print(instance.Name) = all purhcased objects (also prints when new object is bought)
			
			if player ~= nil then
				local bought = PlayerStatManager:getStat(player, instance.Name)
				if bought == false then
					print("Button (" .. tostring(instance) .. ") will be saved")
					PlayerStatManager:ChangeStat(player, instance.Name, true) --change player stat that will be saved later
				else
					print(instance.Name .. " has been bought in a previous game session")
				end
			end
		end)
	else
		error("PurchasedObjects or Tycoon Owner are nil")
	end
end


for i = 1,#tycoons,1 do
	PrepareTycoon(tycoons[i])
end

tycoonsFolder.ChildAdded:Connect(function(Tycoon)
	PrepareTycoon(Tycoon)	
end)

while wait(59) do
	pcall(function()
		print("AutoSaving All Player Progress...")
		local allPlayers = players:GetChildren()
		for i = 1,#allPlayers,1 do
			if allPlayers[i] ~= nil then
				local PlayerDataFile = PlayerData:FindFirstChild(tostring(allPlayers[i].UserId))
				local PlayerMoney = PlayerDataFile:FindFirstChild("Currencies"):FindFirstChild("UniversalCurrencies"):FindFirstChild("Currency")
				if PlayerMoney then 
					PlayerStatManager:initiateSaving(allPlayers[i], "Currency", PlayerMoney.Value)
					 --Initiate saving process by saving player money, saving data is in function
				end
			end
		end
	end)
end
