--(Script)
--Script in ServerScriptService that handles any purchases the player makes
-----------------------------------------------------------------------------------------------------------------------------------------------------------
local PlayerStatManager = require(game.ServerScriptService:WaitForChild("PlayerStatManager"))
local Utility = require(game.ServerScriptService:WaitForChild("Utility"))
local SoundEffects = require(game.ReplicatedStorage:WaitForChild("SoundEffects"))
local PlayerData = game.ServerStorage:WaitForChild("PlayerData")

local EventsFolder = game.ReplicatedStorage.Events
local PurchaseObject = EventsFolder.Utility:WaitForChild("PurchaseObject")
local UpdateInventory = EventsFolder.GUI:WaitForChild("UpdateInventory")

local function GetPlayer(WantedPlayer)
	local Players = game.Players:GetChildren()
	local lookingForPlayer = true
	for i,v in pairs(Players) do
		if tostring(v.UserId) == WantedPlayer then
			lookingForPlayer = false
			return v
		end
	end
	if lookingForPlayer == true then
		warn("Cannot find player: " .. WantedPlayer)
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
					AffordabilityCount = AffordabilityCount + 1 --Criteria for this material has been met
				end
			end
		end

		if AllMaterialsCount == AffordabilityCount then
			return true
		else
			return false
		end
	else
		return nil --Not a material-based purchase
	end	
end

--Tycoon Purchase Function
function PurchaseTycoonObject(Table, Tycoon, Material)
	local cost = Table[1]
	local item = Table[2]
	local stat = Table[3] 
	
	local PurchaseableObjects = require(Tycoon:FindFirstChild("TycoonAssetsHandler"))

	if Material then
		local Menu = Material.Parent
		local Player = GetPlayer(stat.Parent.Name)
		
		--print(cost) --5
		--print(item) --Terminal1
		--print(stat) --Inventory

		for i,menu in pairs (stat:GetChildren()) do
			if menu == stat:FindFirstChild(tostring(Menu)) then
				for i,item in pairs(menu:GetChildren()) do
					if item.Name == tostring(Material) then
						item.Value = item.Value - cost
						PlayerStatManager:ChangeStat(Player, item.Name, -cost, tostring(stat), true)

						if item.Value < 0 then --replace inventory with storage
							local PlayerDataFile = stat.Parent
							local PlayerStorage = PlayerDataFile:FindFirstChild("TycoonStorage")
							local MaterialStorage = PlayerStorage:FindFirstChild("TycoonStorage" .. tostring(Menu))

							--Zero inventory material
							--Subtract the absolute value of the material's previous value (replace offset)
							PlayerStatManager:ChangeStat(Player, "TycoonStorage" .. item.Name, item.Value, "TycoonStorage", true)
							PlayerStatManager:ChangeStat(Player, item.Name, item.Value, tostring(stat), true, "Zero")
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

	--Position ReplicatedStorage-Object Clone to true position
	if PurchaseableObjects[item.Object.Value]:FindFirstChild("Root") ~= nil then
		local MovedModel = PurchaseableObjects[item.Object.Value]
		MovedModel.PrimaryPart = MovedModel.Root

		local ModelPosition = item:FindFirstChild("PrimaryPartPosition")
		MovedModel.PrimaryPart.Orientation = ModelPosition.Orientation
		MovedModel:SetPrimaryPartCFrame(CFrame.new(ModelPosition.Position))

		item.PrimaryPartPosition:Destroy()
		MovedModel.PrimaryPart:Destroy()
	end

	if Tycoon.PurchasedObjects:FindFirstChild(tostring(PurchaseableObjects[item.Object.Value])) == nil then
		PurchaseableObjects[item.Object.Value].Parent = Tycoon.PurchasedObjects
	end
	
	if item.Visible.Value == true then	
		local ButtonParts = item.ButtonModel:GetChildren()
		item.Visible.Value = false
		for bp = 1,#ButtonParts,1 do
			ButtonParts[bp].Transparency = 1
			item.CanCollide = false
		end
	end
end

PurchaseObject.OnServerEvent:Connect(function(player, target)
	
	local AssociatedTycoon = target.Parent.Parent
	
	if target.CanCollide == true then
		if player ~= nil then
			if AssociatedTycoon.Owner.Value == player then

				local PlayerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
				if PlayerDataFile ~= nil then 
					local PlayerCash = PlayerDataFile:FindFirstChild("Currencies"):FindFirstChild("UniversalCurrencies"):FindFirstChild("Currency")
					local PlayerInventory = PlayerDataFile:FindFirstChild("Inventory")
					local PlayerStorage = PlayerDataFile:FindFirstChild("TycoonStorage")
					local MaterialCostCheck = CheckMaterialCosts(PlayerInventory, PlayerStorage, target)

					--If it's a gamepass button
					if (target:FindFirstChild('Gamepass')) and (target.Gamepass.Value >= 1) then
						if game:GetService("MarketplaceService"):PlayerOwnsAsset(player,target.Gamepass.Value) then
							PurchaseTycoonObject({target.Price.Value, target, PlayerCash}, AssociatedTycoon)
						else
							game:GetService('MarketplaceService'):PromptPurchase(player,target.Gamepass.Value)
						end

					--If it's a DevProduct button
					elseif (target:FindFirstChild('DevProduct')) and (target.DevProduct.Value >= 1) then
						game:GetService('MarketplaceService'):PromptProductPurchase(player,target.DevProduct.Value)

					--Normal Button, player can afford it
					elseif PlayerCash.Value >= target.Price.Value and MaterialCostCheck == nil then
						PurchaseTycoonObject({target.Price.Value, target, PlayerCash}, AssociatedTycoon)
						SoundEffects:PlaySound(target, SoundEffects.Tycoon.Purchase)
						
					--Material Button, player can afford it
					elseif PlayerCash.Value >= target.Price.Value and MaterialCostCheck == true then
						local DataGroups = target.MaterialPrice:GetChildren()
						for i,typeGroup in pairs (DataGroups) do
							local currentInventoryGroup = PlayerInventory:FindFirstChild(tostring(typeGroup))
							for i,material in pairs (typeGroup:GetChildren()) do
								local cost = material.Value

								PurchaseTycoonObject({cost, target, PlayerInventory}, AssociatedTycoon, material)
								--extra ",material" at end to say what specifically in the [3]'s menu that's affected)
								wait(.51) --Delay between purchases to successfully stack material popups
							end
						end
						PurchaseTycoonObject({target.Price.Value, target, PlayerCash}, AssociatedTycoon)
						SoundEffects:PlaySound(target, SoundEffects.Tycoon.Purchase)

						--put another for only materials required to purchase "buttons"
						--Make more efficient, remove elseifs or decrease the amount of elseifs

					else --If the player can't afford it
						print("Cannot afford")
						local CashWarning = game.Players:FindFirstChild(tostring(player)).PlayerGui.TycoonPurchaseGui.TycoonPurchaseMenu.CashWarning
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

--------------------------------------<|Research Functions|>----------------------------------------------------------------------------------------------------------------

local AllResearchData = require(game.ServerStorage:WaitForChild("ResearchData"))

local function MeetResearchCost(player, ResearchData, CostName, Paying)
	if #ResearchData[CostName] > 0 then
		local TotalCosts = #ResearchData[CostName]
		local CostsMet = 0
		for i,cost in pairs (ResearchData[CostName]) do
			local PlayerValue = PlayerStatManager:getStat(player, tostring(cost[1]))
			local PlayerStored = 0
			
			if CostName == "Material Cost" then
				PlayerStored = PlayerStatManager:getStat(player, "TycoonStorage" .. tostring(cost[1]))
			end

			if PlayerValue + PlayerStored >= cost[2] then
				if not Paying then
					CostsMet += 1
					if CostsMet == TotalCosts then
						return true
					end
				else
					if Paying == "Experience" then
						local ItemType = tostring(cost[1].Parent)
						PlayerStatManager:ChangeStat(player, tostring(cost[1]), 0, Paying, ItemType)
					else
						local ItemType = string.gsub(cost[1].Bag.Value, "Bag", "") .. "s"
						local AmountRemaining = PlayerStatManager:getStat(player, tostring(cost[1])) - cost[2]
						if AmountRemaining < 0 then
							PlayerStatManager:ChangeStat(player, "TycoonStorage" .. tostring(cost[1]), AmountRemaining, "TycoonStorage", true)
							PlayerStatManager:ChangeStat(player, tostring(cost[1]), -cost[2], Paying, true, "Zero", AmountRemaining)
						else
							PlayerStatManager:ChangeStat(player, tostring(cost[1]), -cost[2], Paying, ItemType)
						end
					end
				end
			end
		end
	else
		return true
	end
	return false
end

local PurchaseResearch = EventsFolder.Utility:WaitForChild("PurchaseResearch")
local UpdateResearch = EventsFolder.GUI:WaitForChild("UpdateResearch")

PurchaseResearch.OnServerEvent:Connect(function(player, ResearchName, ResearchType)
	local ResearchersAvailable = PlayerStatManager:getStat(player, "ResearchersAvailable")
	local UsedResearchSlots = PlayerStatManager:getStat(player, "ResearchersUsed")
	
	if ResearchersAvailable >= UsedResearchSlots + 1 then 
		print("Slot available for research",UsedResearchSlots)
	
		local PurchaseHistory = PlayerStatManager:getStat(player, ResearchName .. "Purchased")
		local CompletionHistory = PlayerStatManager:getStat(player, ResearchName)
		
		if PurchaseHistory == false and CompletionHistory == false then
			for key,rType in pairs (AllResearchData["Research"]) do
				if rType["Research Type Name"] == ResearchType then
					for i,r in pairs (rType) do
						if rType[i]["Research Name"] == ResearchName then
							local ResearchData = rType[i]
							
							local ExpMet = MeetResearchCost(player, ResearchData, "Experience Cost")
							local MatMet = MeetResearchCost(player, ResearchData, "Material Cost")
							
							if ExpMet and MatMet then
								local ClonedTable = Utility:CloneTable(ResearchData)
								
								MeetResearchCost(player, ResearchData, "Material Cost", "Inventory")
								MeetResearchCost(player, ResearchData, "Experience Cost", "Experience")
								
								local FinishTime = os.time() + ResearchData["Research Length"]
								PlayerStatManager:ChangeStat(player, ResearchData["Research Name"] .. "FinishTime", FinishTime, "Research", ResearchData["Research Name"])
								PlayerStatManager:ChangeStat(player, ResearchData["Research Name"] .. "Purchased", true, "Research", ResearchData["Research Name"])
								
								UpdateResearch:FireClient(player, ClonedTable, ResearchType, false, true, FinishTime)
								PurchaseResearch:FireClient(player, ClonedTable)
							else
								PurchaseResearch:FireClient(player)
							end
						end
					end
				end
				
			end
		else
			warn("Research (" .. ResearchName .. ") has already been purchased or completed")
		end
	else
		warn("No slots available for research")
	end
end)

local function CheckResearchUnlocks(player, CompletedResearch)
	local UnlockedResearch = {}
	
	for i,rType in pairs (AllResearchData["Research"]) do
		local ResearchType = rType["Research Type Name"]
		for i,r in pairs (rType) do
			local Research = rType[i]
			
			if Research["Dependencies"] then
				local DependencyFound = false
				
				--Dependencies where new research is depend of possibly new unlock
				for d = 1,#Research["Dependencies"] do
					if Research["Dependencies"][d] == CompletedResearch then
						print("Research just researched is a dependency of ", Research) --may need to look through dependency table
						if #Research["Dependencies"] == 1 then
							table.insert(UnlockedResearch, ResearchType)
							table.insert(UnlockedResearch, Research)
						else
							local DependenciesMet = 0
							for d = 1,#Research["Dependencies"] do
								if PlayerStatManager:getStat(player, Research["Dependencies"][d]) then
									DependenciesMet += 1
								end
							end
							if DependenciesMet == #Research["Dependencies"] then
								table.insert(UnlockedResearch, ResearchType)
								table.insert(UnlockedResearch, Research)
							end
						end
					end
				end
			end
		end
	end
	return UnlockedResearch
end

local CompleteResearch = EventsFolder.Utility:WaitForChild("CompleteResearch")
CompleteResearch.OnServerEvent:Connect(function(player, ResearchName, ResearchType)
	local PurchaseHistory = PlayerStatManager:getStat(player, ResearchName .. "Purchased")
	local CompletionHistory = PlayerStatManager:getStat(player, ResearchName)
	local FinishTime = PlayerStatManager:getStat(player, ResearchName .. "FinishTime")
	
	if PurchaseHistory and os.time() >= FinishTime then
		if not CompletionHistory then
			local TypeTableName = string.gsub(ResearchType, "Research", "") .. "Improvements"
			local ResearchTypeTable = AllResearchData["Research"][TypeTableName]
			
			local ResearchData
			for research = 1,#ResearchTypeTable,1 do
				if ResearchTypeTable[research]["Research Name"] == ResearchName and ResearchData == nil then
					ResearchData = Utility:CloneTable(ResearchTypeTable[research])
				end
			end
			
			if ResearchData then
				local UsedResearchSlots = PlayerStatManager:getStat(player, "ResearchersUsed")
				PlayerStatManager:ChangeStat(player, "ResearchersUsed", UsedResearchSlots - 1, "Research")
				PlayerStatManager:ChangeStat(player, ResearchName, true, "Research")
				
				local PlayerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
				if ResearchType == "Tycoon Research" then
					local OwnedTycoon = PlayerDataFile:FindFirstChild("OwnsTycoon").Value
					
					if OwnedTycoon then
						local ResearchReference = Instance.new("Model")
						ResearchReference.Name = ResearchName
						ResearchReference.Parent = OwnedTycoon.CompletedResearch
						--Otherwise, when player loads tycoon, research will be inserted
					end
					
					CompleteResearch:FireClient(player, ResearchData)
					UpdateResearch:FireClient(player, ResearchData, ResearchType, true, true)
					
					local NewResearchUnlocks = CheckResearchUnlocks(player, ResearchName)
					if #NewResearchUnlocks > 0 then --Unlock now unlocked research
						for r = 1,#NewResearchUnlocks,1 do
							if r%2 == 0 then --even
								local ResearchData = NewResearchUnlocks[r]
								local ResearchType = NewResearchUnlocks[r-1]

								UpdateResearch:FireClient(player, ResearchData, ResearchType, false, false)
							end
						end
					end
				else
					print("Different type of reserach than tycoon")
					print("Where should other research type dependencies be checked?")
				end
			end
		else
			warn(ResearchName .. " has already been completed")
		end
	end
end)


-------------------------------<|StoreFront Purchase Functions|>---------------------------------------------------------------------------------------------------------

local AllNPCData = require(game.ServerStorage:WaitForChild("NPCData"))
local StoreFrontInteract = EventsFolder.HotKeyInteract:WaitForChild("StoreFrontInteract")
local UpdateStoreFront = EventsFolder.GUI:WaitForChild("UpdateStoreFront")

StoreFrontInteract.OnServerEvent:Connect(function(player, NPC)
	local npcData = Utility:CloneTable(AllNPCData[tostring(NPC)])
	local AlreadyPurchased = {}
	
	for item = 1,#npcData["Items"],1 do
		local Value = PlayerStatManager:getStat(player, tostring(npcData["Items"][item][1]))
		
		if Value == true then
			table.insert(AlreadyPurchased, npcData["Items"][item][1])
		end
	end
	
	print("AlreadyPurchased",AlreadyPurchased)
	
	UpdateStoreFront:FireClient(player, NPC, npcData, AlreadyPurchased)
end)

local StoreFrontPurchase = game.ReplicatedStorage.Events.Utility:WaitForChild("StoreFrontPurchase")
StoreFrontPurchase.OnServerEvent:Connect(function(player, NPC, ItemName, ItemType, EquipType, Tile)
	local PlayerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
	local Item = game.ReplicatedStorage.Equippable:FindFirstChild(EquipType):FindFirstChild(ItemType):FindFirstChild(ItemName)

	local npcData = AllNPCData[NPC]
	
	local ItemPrice 	
	for item = 1,#npcData["Items"],1 do
		if npcData["Items"][item][1] == Item then
			ItemPrice = npcData["Items"][item][2]
		end
	end
	
	local PlayerCash = PlayerDataFile:FindFirstChild("Currencies"):FindFirstChild("UniversalCurrencies"):FindFirstChild("Currency")
	
	if ItemPrice then
		if PlayerCash.Value >= ItemPrice then
			--Pay for Item
			PlayerCash.Value = PlayerCash.Value - ItemPrice
			Utility:UpdateMoneyDisplay(player, PlayerCash.Value)
			UpdateInventory:FireClient(player, "Currency", "Currencies", nil, -ItemPrice, "Inventory", "Money1")
			
			--Get & Equip Item
			PlayerStatManager:ChangeStat(player, ItemName, true, EquipType, ItemType)
			PlayerStatManager:ChangeStat(player, "Equipped" .. ItemType, ItemName, EquipType, ItemType)
			
			StoreFrontPurchase:FireClient(player, Item)
		else
			local MissingFunds = ItemPrice - PlayerCash.Value
			StoreFrontPurchase:FireClient(player, Item, MissingFunds)
		end
	else
		--Exploiter warning
		--warn(player, "This player could have interfered with item info")
	end
end)

