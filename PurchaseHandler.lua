--(Script)
--Script in ServerScriptService that handles any purchases the player makes
-----------------------------------------------------------------------------------------------------------------------------------------------------------
local PlayerStatManager = require(game.ServerScriptService:WaitForChild("PlayerStatManager"))
local Utility = require(game.ServerScriptService:WaitForChild("Utility"))
local SoundEffects = require(game.ReplicatedStorage:WaitForChild("SoundEffects"))
local PlayerData = game.ServerStorage:WaitForChild("PlayerData")

local EventsFolder = game.ReplicatedStorage.Events
local PurchaseObject = EventsFolder.Utility:WaitForChild("PurchaseObject")

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

--Tycoon Purchase Function
function PurchaseTycoonObject(Table, Tycoon, Material)
	local cost = Table[1]
	local item = Table[2]
	local stat = Table[3] 
	
	local PurchaseableObjects = require(Tycoon:FindFirstChild("TycoonAssetsHandler"))

	
	local Player = GetPlayer(stat.Parent.Parent.Parent.Name)
	stat.Value = stat.Value - cost
	Utility:UpdateMoneyDisplay(Player, stat.Value)

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
	
	--**Maybe destroy used buttons to save on part count?
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
	if player and player.UserId then
		local playerData = game.ServerStorage.PlayerData:FindFirstChild(player.UserId)
		if playerData and playerData:FindFirstChild("OwnsTycoon") then
			local tycoon = playerData.OwnsTycoon.Value
			
			if target:IsDescendantOf(tycoon) and target.CanCollide == true then
				local playerCash = playerData:FindFirstChild("Currencies"):FindFirstChild("UniversalCurrencies"):FindFirstChild("Coins")

				--If it's a gamepass button
				if (target:FindFirstChild('Gamepass')) and (target.Gamepass.Value >= 1) then
					if game:GetService("MarketplaceService"):PlayerOwnsAsset(player, target.Gamepass.Value) then
						PurchaseTycoonObject({target.Price.Value, target, playerCash}, tycoon)
					else
						game:GetService('MarketplaceService'):PromptPurchase(player, target.Gamepass.Value)
					end

				--If it's a DevProduct button
				elseif (target:FindFirstChild('DevProduct')) and (target.DevProduct.Value >= 1) then
					game:GetService('MarketplaceService'):PromptProductPurchase(player, target.DevProduct.Value)

				--Normal Button, player can afford it
				elseif playerCash.Value >= target.Price.Value then
					PurchaseTycoonObject({target.Price.Value, target, playerCash}, tycoon)
					SoundEffects:PlaySound(target, SoundEffects.Tycoon.Purchase)

				else --If the player can't afford it
					print("Cannot afford")
					local CashWarning = game.Players:FindFirstChild(tostring(player)).PlayerGui.TycoonPurchaseGui.TycoonPurchaseMenu.CashWarning
					CashWarning.Visible = true
					SoundEffects:PlaySound(target, SoundEffects.Tycoon.ErrorBuy)
					wait(2)
					CashWarning.Visible = false
				end
			else
				warn(tostring(player) .. " may be exploiting")
			end
		end
	end
end)

--------------------------------------<|Research Functions|>----------------------------------------------------------------------------------------------------------------

local AllResearchData = require(game.ServerStorage:WaitForChild("ResearchData"))

local function MeetResearchCost(player, researchData, costName, paying)
	if #researchData[costName] > 0 then
		local TotalCosts = #researchData[costName]
		local CostsMet = 0
		
		for _,cost in pairs (researchData[costName]) do
			local statName = tostring(cost[1])
			if string.match(statName, "table: ") then
				statName = cost[1]["StatName"]
			end
			
			local inventoryAmount = PlayerStatManager:getStat(player, statName)
			local storageAmount = 0
			if costName == "Material Cost" then
				storageAmount = PlayerStatManager:getStat(player, "TycoonStorage" .. statName)
			end

			if inventoryAmount + storageAmount >= cost[2] then
				if not paying then --highlight CostList requirement as met
					CostsMet += 1
					if CostsMet == TotalCosts then
						return true
					end
				else
					if paying == "Experience" then
						local ItemType = tostring(cost[1].Parent)
						PlayerStatManager:ChangeStat(player, statName, 0, paying, ItemType)
					else
						local ItemType = string.gsub(cost[1].Bag.Value, "Bag", "") .. "s"
						local AmountRemaining = PlayerStatManager:getStat(player, statName) - cost[2]
						if AmountRemaining < 0 then
							PlayerStatManager:ChangeStat(player, "TycoonStorage" .. statName, AmountRemaining, "TycoonStorage", true)
							PlayerStatManager:ChangeStat(player, statName, -cost[2], paying, true, "Zero", AmountRemaining)
						else
							PlayerStatManager:ChangeStat(player, statName, -cost[2], paying, ItemType)
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

PurchaseResearch.OnServerEvent:Connect(function(player, researchName, researchType)
	local researchersAvailable = PlayerStatManager:getStat(player, "ResearchersAvailable")
	local usedResearchSlots = PlayerStatManager:getStat(player, "ResearchersUsed")
	
	if researchersAvailable >= usedResearchSlots + 1 then 
		local researchPurchased = PlayerStatManager:getStat(player, researchName .. "Purchased")
		local researchCompleted = PlayerStatManager:getStat(player, researchName)
		
		if researchPurchased == false and researchCompleted == false then
			for _,rType in pairs (AllResearchData["Research"]) do
				if rType["Research Type Name"] == researchType then
					
					for i,r in pairs (rType) do
						if rType[i]["Research Name"] == researchName then
							local researchData = rType[i]
							local expMet = MeetResearchCost(player, researchData, "Experience Cost")
							local matMet = MeetResearchCost(player, researchData, "Material Cost")
							
							if expMet and matMet then
								local clonedTable = Utility:CloneTable(researchData)
								
								MeetResearchCost(player, researchData, "Material Cost", "Inventory")
								MeetResearchCost(player, researchData, "Experience Cost", "Experience")
								
								local finishTime = os.time() + researchData["Research Length"]
								PlayerStatManager:ChangeStat(player, researchData["Research Name"] .. "FinishTime", finishTime, "Research", researchData["Research Name"])
								PlayerStatManager:ChangeStat(player, researchData["Research Name"] .. "Purchased", true, "Research", researchData["Research Name"])
								
								UpdateResearch:FireClient(player, clonedTable, researchType, false, true, finishTime)
								PurchaseResearch:FireClient(player, clonedTable)
							else
								PurchaseResearch:FireClient(player)
							end
						end
					end
				end
				
			end
		else
			warn("Research (" .. researchName .. ") has already been purchased or completed")
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
	
	if PurchaseHistory == true and os.time() >= FinishTime then
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
				PlayerStatManager:ChangeStat(player, ResearchName, true, "Research", ResearchType)
				
				local PlayerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
				if ResearchType == "Tycoon Research" then
					local OwnedTycoon = PlayerDataFile:FindFirstChild("OwnsTycoon").Value
					
					if OwnedTycoon then
						local ResearchReference = Instance.new("Model")
						ResearchReference.Name = ResearchName
						ResearchReference.Parent = OwnedTycoon.CompletedResearch
						--New research is inserted this way, but PlayerStatManager inserts references on load
					end
					
					--[[
					CompleteResearch:FireClient(player, ResearchData)
					UpdateResearch:FireClient(player, ResearchData, ResearchType, true, true)
					
					local NewResearchUnlocks = CheckResearchUnlocks(player, ResearchName)
					if #NewResearchUnlocks > 0 then --Just finished research caused another research to unlock
						for r = 1,#NewResearchUnlocks,1 do
							if r%2 == 0 then --even
								local ResearchData = NewResearchUnlocks[r]
								local ResearchType = NewResearchUnlocks[r-1]

								UpdateResearch:FireClient(player, ResearchData, ResearchType, false, false)
							end
						end
					end
					]]
				--else
					--print("Different type of reserach than tycoon")
					--print("Where should other research type dependencies be checked?")
					
					--Check this research type the same way as the bottom of tycoon research, just no need to create
					--a physical reference for buttons to start appearing
					
					
					--Honestly, all research types should just check the player's save file to see if they have purchased
					--all the dependencies rather than checking physics objects
					
					--Also, the shop research did not update to say true (that I completed it)
					--so ensure that this code also does that and doesn't only wait for the autosave to do something
				end
				
				CompleteResearch:FireClient(player, ResearchData)
				UpdateResearch:FireClient(player, ResearchData, ResearchType, true, true)

				local NewResearchUnlocks = CheckResearchUnlocks(player, ResearchName)
				if #NewResearchUnlocks > 0 then --Just finished research caused another research to unlock
					for r = 1,#NewResearchUnlocks,1 do
						if r%2 == 0 then --even
							local ResearchData = NewResearchUnlocks[r]
							local ResearchType = NewResearchUnlocks[r-1]

							UpdateResearch:FireClient(player, ResearchData, ResearchType, false, false)
						end
					end
				end
			end
		else
			warn(ResearchName .. " has already been completed")
		end
	end
end)


-------------------------------<|StoreFront Purchase Functions|>---------------------------------------------------------------------------------------------------------

local AllShopData = require(game.ServerStorage:WaitForChild("ShopData"))
local StoreFrontInteract = EventsFolder.HotKeyInteract:WaitForChild("StoreFrontInteract")
local UpdateStoreFront = EventsFolder.GUI:WaitForChild("UpdateStoreFront")

StoreFrontInteract.OnServerEvent:Connect(function(player, NPC)
	local shopData = Utility:CloneTable(AllShopData[tostring(NPC)])
	local AlreadyPurchased = {}
	
	for item = 1,#shopData["Items"],1 do
		local buyValue = PlayerStatManager:getStat(player, tostring(shopData["Items"][item][1]))
		
		if buyValue == true then
			table.insert(AlreadyPurchased, shopData["Items"][item][1])
		end
	end
	
	print("AlreadyPurchased",AlreadyPurchased,player)
	
	UpdateStoreFront:FireClient(player, NPC, shopData, AlreadyPurchased)
end)

local StoreFrontPurchase = game.ReplicatedStorage.Events.Utility:WaitForChild("StoreFrontPurchase")
StoreFrontPurchase.OnServerEvent:Connect(function(player, NPC, Item)
	local playerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
	local shopData = AllShopData[NPC]
	
	local ItemPrice 	
	for item = 1,#shopData["Items"],1 do
		if shopData["Items"][item][1] == Item then
			ItemPrice = shopData["Items"][item][2]
		end
	end
	
	local PlayerCash = playerDataFile:FindFirstChild("Currencies"):FindFirstChild("UniversalCurrencies"):FindFirstChild("Coins")
	
	if ItemPrice then
		if PlayerCash.Value >= ItemPrice then
			--Pay for Item
			PlayerCash.Value = PlayerCash.Value - ItemPrice
			Utility:UpdateMoneyDisplay(player, PlayerCash.Value)
			
			local itemName = tostring(Item)
			local itemType = tostring(Item.Parent)
			local equipType = tostring(Item.Parent.Parent)
			
			if equipType == "InventoryItems" then
				PlayerStatManager:ChangeStat(player, itemName, true, equipType, itemType)
				
			else --Equipment
				PlayerStatManager:ChangeStat(player, itemName, true, equipType, itemType)
				PlayerStatManager:ChangeStat(player, "Equipped" .. itemType, itemName, equipType, itemType)
			end
			
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

