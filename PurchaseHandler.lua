--(Script)
--Script in ServerScriptService that handles any purchases the player makes
-----------------------------------------------------------------------------------------------------------------------------------------------------------

local PlayerStatManager = require(game.ServerScriptService:WaitForChild("PlayerStatManager"))
local Utility = require(game.ServerScriptService:WaitForChild("Utility"))
local SoundEffects = require(game.ServerScriptService.Utility:WaitForChild("SoundEffects"))
local PlayerData = game.ServerStorage:WaitForChild("PlayerData")

local EventsFolder = game.ReplicatedStorage.Events
local PurchaseObject = EventsFolder.Utility.PurchaseObject
local UpdateInventory = EventsFolder.GUI.UpdateInventory

local function GetPlayer(WantedPlayer)
	print("WANTED PLAYER: " .. tostring(WantedPlayer))
	local Players = game.Players:GetChildren()
	local lookingForPlayer = true
	for i,v in pairs(Players) do
		if tostring(v.UserId) == WantedPlayer then
			lookingForPlayer = false
			return v
		end
	end
	if lookingForPlayer == true then
		warn("Something went wrong, cannot find player")
	end
end

-------------------------------<|Tycoon Purchases|>----------------------------------------------------------------------------------------------------------

local function CheckMaterialCosts(Inventory, Storage, Button)
	local AllMaterialsCount = 0
	local AffordabilityCount = 0
	if Button:FindFirstChild("MaterialPrice") then
		local DataGroups = Button.MaterialPrice:GetChildren()
		for i,typeGroup in pairs (DataGroups) do
			local currentInventoryGroup = Inventory:FindFirstChild(tostring(typeGroup))
			local currentStorageGroup = Storage:FindFirstChild("TycoonStorage" .. tostring(typeGroup))
			for i,material in pairs (typeGroup:GetChildren()) do
				AllMaterialsCount = AllMaterialsCount + 1
				local cost = material.Value
				local sum = currentInventoryGroup:FindFirstChild(tostring(material)).Value + currentStorageGroup:FindFirstChild("TycoonStorage" .. tostring(material)).Value
				if sum >= cost then
					AffordabilityCount = AffordabilityCount + 1
				end
			end
		end

		if AllMaterialsCount == AffordabilityCount then
			return true
		else
			return false
		end
	else
		return nil
	end	
end

--Tycoon Purchase Function
function Purchase(Table, Tycoon, Material)
	local cost = Table[1]
	local item = Table[2]
	local stat = Table[3] 
	
	local PurchaseableObjects = require(Tycoon:FindFirstChild("TycoonPurchaseHandler"))

	if Material then
		local Menu = Material.Parent
		local Player = GetPlayer(stat.Parent.Name)
		
		--print(cost) --5
		--print(item) --Terminal1
		--print(stat) --Inventory

		for i,menu in pairs (stat:GetChildren()) do
			if menu == stat:FindFirstChild(tostring(Menu)) then
				for i,v in pairs(menu:GetChildren()) do
					if v.Name == tostring(Material) then
						print(tostring(v) .. "'s value has been subtracted by " .. tostring(cost))
						v.Value = v.Value - cost

						PlayerStatManager:ChangeStat(Player, v.Name, -cost, tostring(stat), true)
						--PlayerStatManager is updated here because mats only updated when "harvested" otherwise

						if v.Value < 0 then --replace inventory with storage
							local PlayerDataFile = stat.Parent
							local PlayerStorage = PlayerDataFile:FindFirstChild("TycoonStorage")
							local MaterialStorage = PlayerStorage:FindFirstChild("TycoonStorage" .. tostring(Menu))

							--Zero inventory material
							--Subtract the absolute value of the material's previous value
							PlayerStatManager:ChangeStat(Player, "TycoonStorage" .. v.Name, v.Value, tostring(PlayerStorage), true)
							PlayerStatManager:ChangeStat(Player, v.Name, 0, tostring(stat), true, "Zero")
						end
					end
				end
			end
		end	
	else --Update Currency
		local Player = GetPlayer(stat.Parent.Parent.Parent.Name)
		stat.Value = stat.Value - cost
		Utility:UpdateMoneyDisplay(Player, stat.Value)
		UpdateInventory:FireClient(Player, "Currency", "Currencies", nil, -cost, "Inventory", "Money1")
	end

	--Objects[item.Object.Value] is created in for _,v in pairs (script.Parent.Buttons:GetChildren())
	--Position Replicated Storage Object Clone to true position
	if PurchaseableObjects[item.Object.Value]:FindFirstChild("Root") ~= nil then
		local MovedModel = PurchaseableObjects[item.Object.Value]
		MovedModel.PrimaryPart = MovedModel.Root

		local ModelPosition = item:FindFirstChild("PrimaryPartPosition")
		MovedModel.PrimaryPart.Orientation = ModelPosition.Orientation
		MovedModel:SetPrimaryPartCFrame(CFrame.new(ModelPosition.Position))

		item.PrimaryPartPosition:Destroy()
		MovedModel.PrimaryPart:Destroy()
	end

	if script.Parent.PurchasedObjects:FindFirstChild(tostring(PurchaseableObjects[item.Object.Value])) == nil then
		--Shouldn't I clone it, does it get rid of it from file?
		PurchaseableObjects[item.Object.Value].Parent = script.Parent.PurchasedObjects
	end

	if item.Visible.Value == true then	
		local ButtonParts = item.Model:GetChildren()
		item.Visible.Value = false
		for bp = 1,#ButtonParts,1 do
			ButtonParts[bp].Transparency = 1
			item.CanCollide = false
		end
	end
end

PurchaseObject.OnServerEvent:Connect(function(player, target)
	
	--target.Parent.Parent = associated tycoon
	--target = button 
	
	if target.CanCollide == true then
		if player ~= nil then
			if script.Parent.Owner.Value == player then

				local PlayerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
				if PlayerDataFile ~= nil then 
					local PlayerCash = PlayerDataFile:FindFirstChild("Currencies"):FindFirstChild("UniversalCurrencies"):FindFirstChild("Currency")
					local PlayerInventory = PlayerDataFile:FindFirstChild("Inventory")
					local PlayerStorage = PlayerDataFile:FindFirstChild("TycoonStorage")
					local MaterialCostCheck = CheckMaterialCosts(PlayerInventory, PlayerStorage, target)

					--If it's a gamepass button
					if (target:FindFirstChild('Gamepass')) and (target.Gamepass.Value >= 1) then
						if game:GetService("MarketplaceService"):PlayerOwnsAsset(player,target.Gamepass.Value) then
							Purchase({[1] = target.Price.Value,[2] = target,[3] = PlayerCash})
						else
							game:GetService('MarketplaceService'):PromptPurchase(player,target.Gamepass.Value)
						end

						--If it's a DevProduct button
					elseif (target:FindFirstChild('DevProduct')) and (target.DevProduct.Value >= 1) then
						game:GetService('MarketplaceService'):PromptProductPurchase(player,target.DevProduct.Value)

						--Normal Button, player can afford it
					elseif PlayerCash.Value >= target.Price.Value and MaterialCostCheck == nil then
						Purchase({[1] = target.Price.Value,[2] = target,[3] = PlayerCash})
						SoundEffects:PlaySound(target, SoundEffects.Tycoon.Purchase)

					elseif PlayerCash.Value >= target.Price.Value and MaterialCostCheck == true then
						local DataGroups = target.MaterialPrice:GetChildren()
						for i,typeGroup in pairs (DataGroups) do
							local currentInventoryGroup = PlayerInventory:FindFirstChild(tostring(typeGroup))
							for i,material in pairs (typeGroup:GetChildren()) do
								local cost = material.Value

								Purchase({[1] = cost, [2] = target, [3] = PlayerInventory}, material)
								--extra ",material" at end to say what specifically in the [3]'s menu that's affected)
								wait(.51) --Delay between purchases to successfully stack material popups
							end
						end
						Purchase({[1] = target.Price.Value,[2] = target,[3] = PlayerCash})
						SoundEffects:PlaySound(target, SoundEffects.Tycoon.Purchase)


						--put another for only materials required to purchase "buttons"
						--Make more efficient, remove elseifs or decrease the amount of elseifs

					else --If the player can't afford it
						print("Cannot afford")
						local CashWarning = game.Players:FindFirstChild(tostring(player)).PlayerGui.ButtonHandler.Menu.CashWarning
						CashWarning.Visible = true
						SoundEffects:PlaySound(target, SoundEffects.Tycoon.ErrorBuy)
						wait(2)
						CashWarning.Visible = false
					end
				else
					warn(tostring(player) .. " doesn't have an affiliated DataStore!")
				end
			end
		end
	end
end)



