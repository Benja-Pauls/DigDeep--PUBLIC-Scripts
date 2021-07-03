--(ModuleScript)
--Handles all saving that occurs. Any true saving (ROBLOX data store assigning)
-------------------------------------------------------------------------------------------------------------------------------------------------
local PlayerStatManager = {}

local tycoons = game.Workspace:WaitForChild("Tycoons"):GetChildren()

local PlayerData = game.ServerStorage:FindFirstChild("PlayerData")
local Utility = require(game.ServerScriptService.Utility)
local equipmentData = require(game.ServerStorage.EquipmentData)
local itemData = require(game.ServerStorage.ItemData)

local EventsFolder = game.ReplicatedStorage.Events
local UpdateInventory = EventsFolder.GUI:WaitForChild("UpdateInventory")
local UpdateTycoonStorage = EventsFolder.GUI:WaitForChild("UpdateTycoonStorage")
local UpdatePlayerMenu = EventsFolder.GUI:WaitForChild("UpdatePlayerMenu")
local UpdateEquippedItem = EventsFolder.GUI:WaitForChild("UpdateEquippedItem")
local UpdateItemCount = EventsFolder.GUI:WaitForChild("UpdateItemCount")
local UpdateResearch = EventsFolder.GUI:WaitForChild("UpdateResearch")

local GetBagCount = EventsFolder.Utility:WaitForChild("GetBagCount")
local SellItem = EventsFolder.Utility:WaitForChild("SellItem")
local DepositInventory = EventsFolder.Utility:WaitForChild("DepositInventory")
local CheckResearchDepends = EventsFolder.Utility:WaitForChild("CheckResearchDepends")

local HandleDropMaterialsEvent = EventsFolder.Tycoon:WaitForChild("HandleDropMaterials")

-------------------------<|Set Up Game|>--------------------------------------------------------------------------------------------------------------------------------------
local DataStoreService = game:GetService("DataStoreService") 
local PlayerSave = DataStoreService:GetDataStore("Tycoon Test209") --Changing this will change the datastore info is taken from

--When player joins
game.Players.PlayerAdded:Connect(function(JoinedPlayer)
	print(tostring(JoinedPlayer) .. " has joined the game")
	
	if PlayerData:FindFirstChild(JoinedPlayer.UserId) == nil then --Server startup, make new folder
		local PlayerDataStorage = Instance.new('Folder', PlayerData) 
		PlayerDataStorage.Name = tostring(JoinedPlayer.UserId)
	end

	local playerDataFile = PlayerData:FindFirstChild(JoinedPlayer.UserId)
	
	local isOwner = Instance.new("ObjectValue", playerDataFile)
	isOwner.Name = "OwnsTycoon"

	if game.Workspace:WaitForChild(tostring(JoinedPlayer)) then
		print(tostring(JoinedPlayer),"'s CHARACTER WAS ASSIGNED TO PLAYERS FOLDER")
		local character = game.Workspace:FindFirstChild(tostring(JoinedPlayer))
		
		repeat wait() until character:FindFirstChild("LowerTorso") --Player has loaded in
		character.Parent = game.Workspace:WaitForChild("Players")

		--Way to make this a softer glow?
		local Light = Instance.new("PointLight")
		Light.Brightness = 7
		Light.Range = 7
		Light.Parent = character.HumanoidRootPart
		
		--**Insert BillboardGui displaying player's name
		
		--**Insert ProxPrompt in Player Here? (if players need to interact with each other)
	end
	
	FindPlayerData(JoinedPlayer)
end)

--When player leaves
game.Players.PlayerRemoving:Connect(function(JoinedPlayer)
	local PlayerDataFile = PlayerData:FindFirstChild(tostring(JoinedPlayer.UserId))
	
	if PlayerDataFile ~= nil then --Remove player from ServerStorage
		PlayerDataFile:Destroy()
	end
	--Tycoon is removed via TycoonHandler script
end)

local sessionData = {}

--------------------------<|Utility Functions|>----------------------------------------------------------------------------------------------------------------------------------

GetBagCount.OnInvoke = function(Player, itemInfo)
	local itemType = string.gsub(itemInfo.AssociatedSkill.Value, "Skill", "")
	local amount = PlayerStatManager:getItemCount(Player)
	local maxAmount = PlayerStatManager:getEquippedData(Player, itemInfo.Bag.Value .. "s", "Bags")
	
	if amount and maxAmount then
		return amount,maxAmount,itemType .. "s"
	else
		return amount,nil,itemType .. "s"
	end
end

local function CheckSaveData(Save)
	if not Save then
		return false --Nothing, not even 0, "", or false, have been recorded for this save value
	else
		return true
	end
end

--Update ServerStorage Folders With Data
local function ImportSaveData(data, SaveCheck, Folder, Stat, Single)
	if SaveCheck == false then
		if typeof(Stat.Value) == "number" then
			Stat.Value = 0
		elseif typeof(Stat.Value) == "boolean" then
			Stat.Value = false
		else
			Stat.Value = ""
		end
	end
	
	if not Single then
		for i,v in pairs (Folder:GetChildren()) do
			if data[tostring(v)] == nil then
				data[tostring(v)] = Stat.Value --placeholder value to create (even if not interacted with yet)
			else
				v.Value = data[tostring(v)]
			end
		end
	else
		if data[tostring(Single)] == nil then
			data[tostring(Single)] = Stat.Value --placeholder value to create (even if not interacted with yet)
		else
			Stat.Value = data[tostring(Single)]
		end
	end
end

local function CreateSaveReference(ParentFolder, FolderName, InstanceType)
	local NewFolder = Instance.new(InstanceType, ParentFolder)
	NewFolder.Name = FolderName
	return NewFolder
end

local function FindAssociatedFolder(parentDataFolder, itemType, itemName)
	if parentDataFolder:FindFirstChild(itemType) then --make this a check folder existence function (utility section at end or start of code?)
		if not parentDataFolder:FindFirstChild(itemType):FindFirstChild(itemName) then --if item not already inputted from other location
			return parentDataFolder:FindFirstChild(itemType)
		end
	else
		return CreateSaveReference(parentDataFolder, itemType, "Folder")
	end
end

local function SavePlayerData(playerUserId)
	if sessionData[playerUserId] then
		local success = pcall(function()
			PlayerSave:SetAsync(playerUserId, sessionData[playerUserId]) --save sessionData as playerUserId
			print(playerUserId .. "'s held data was SAVED!")
		end)
		if not success then
			warn("Cannot save data for " .. tostring(playerUserId))
		end
	end
end

---------------------<|High-Traffic Functions|>--------------------------------------------------------------------------------------------------------------------------------------

local function UpdateGUIForFile(saveFolder, player, statName, value, overFlow)
	print(saveFolder, player, statName, value, overFlow)
	
	--Problem are now out of server scripts! (Still need to check shop gui and tycoon)
	--When done with dinner, fix the below errors having to do with displaying information after the player
	--has mined a block (material and exp popups)
	
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId
	local playerDataFile = PlayerData:WaitForChild(tostring(playerUserId))
	local dataFolder = playerDataFile:FindFirstChild(tostring(saveFolder))
	
	for i,itemType in pairs (dataFolder:GetChildren()) do
		if itemType:FindFirstChild(tostring(statName)) then --DataTab:FindFirstChild(file):FindFirstChild(statName)?
			local total = sessionData[playerUserId][statName]
			local amountAdded = value
			
			if tostring(saveFolder) == "Inventory" or tostring(saveFolder) == "Experience" then
				local LocationOfAcquirement
				if tostring(saveFolder) == "Inventory" then
					LocationOfAcquirement = Utility:GetItemInfo(statName, true)
					
					--Update Bag
					local TypeAmount = PlayerStatManager:getItemCount(player)
					local maxItemAmount = PlayerStatManager:getEquippedData(player, LocationOfAcquirement:FindFirstChild(statName).Bag.Value .. "s", "Bags") --Bag capacity
					if maxItemAmount then
						if value ~= 0 and not overFlow then
							UpdateItemCount:FireClient(player, TypeAmount+value, maxItemAmount, tostring(itemType))
						elseif overFlow then
							--put up popup showing how much has been payed
							local expense = math.abs(value - overFlow)
							UpdateItemCount:FireClient(player, TypeAmount-expense, maxItemAmount, tostring(itemType))
							--remove tile from inventory
							
						else
							UpdateItemCount:FireClient(player, 0, maxItemAmount, tostring(itemType), true)
						end
					end
				else
					LocationOfAcquirement = "Skills"
				end
				
				--Finally, update inventory information
				if LocationOfAcquirement then	
					UpdateInventory:FireClient(player, statName, tostring(itemType), tostring(total), amountAdded, tostring(saveFolder), tostring(LocationOfAcquirement))
				else
					warn("Item (" .. statName .. ") has no location of acquirement")
				end
				
			elseif tostring(saveFolder) == "TycoonStorage" then
				local LocationOfAcquirement = Utility:GetItemInfo(string.gsub(statName, "TycoonStorage", ""), true)
				--print(tostring(file), statName, tostring(total), amountAdded, LocationOfAcquirement)
				UpdateTycoonStorage:FireClient(player, tostring(itemType), statName, tostring(total), amountAdded, tostring(LocationOfAcquirement))
				
			elseif tostring(saveFolder) == "Currencies" then
				Utility:UpdateMoneyDisplay(player, Utility:ConvertShort(total))
			end
			
			--Finally, update DataStore value
			itemType:FindFirstChild(statName).Value = sessionData[playerUserId][statName]
		end
	end
end

--Change saved stat to new value
function PlayerStatManager:ChangeStat(player, statName, value, saveFolder, itemType, special, overFlow)
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId
	local playerDataFile = PlayerData:WaitForChild(tostring(playerUserId))
	
	print(player, statName, value, saveFolder, itemType, special, overFlow)
	--print(typeof(sessionData[playerUserId][statName]),typeof(value),statName,sessionData[playerUserId][statName])	
	
	assert(typeof(sessionData[playerUserId][statName]) == typeof(value), tostring(player) .. "'s saved value types don't match")
	
	if typeof(sessionData[playerUserId][statName]) == "number" and saveFolder ~= "Research" then
		if sessionData[playerUserId][statName] ~= sessionData[playerUserId][statName] + value or special then --if changed	
			
			--Update DataStore Value
			if special == "Zero" then
				sessionData[playerUserId][statName] = 0
			else
				sessionData[playerUserId][statName] += value
			end
	
			if saveFolder then
				if playerDataFile:FindFirstChild(saveFolder):FindFirstChild(statName) then
					playerDataFile:FindFirstChild(saveFolder):FindFirstChild(statName).Value = sessionData[playerUserId][statName] 
				else
					UpdateGUIForFile(saveFolder, player, statName, value, overFlow)
				end
			end
			
			--**Possibly update the UpdateGUIForFile for all types of data and merge it for non stattype items
			
		end
		
	elseif sessionData[playerUserId][statName] ~= value then
		
		sessionData[playerUserId][statName] = value 
		
		--Research saves exact value, not += value
		if saveFolder == "Research" then
			if playerDataFile:FindFirstChild(saveFolder):FindFirstChild(statName) then
				playerDataFile:FindFirstChild(saveFolder):FindFirstChild(statName).Value = sessionData[playerUserId][statName] 
			end
		end

		if typeof(sessionData[playerUserId][statName]) == "boolean" then
			if saveFolder then
				if game.ReplicatedStorage.Equippable:FindFirstChild(saveFolder) then --Player Item Purchase Bool
					UpdatePlayerMenu:FireClient(player, saveFolder, itemType, statName)
					playerDataFile.Player:FindFirstChild(saveFolder):FindFirstChild(itemType):FindFirstChild(statName).Value = value
					
				elseif string.find(statName, "Discovered") then
					local acquiredLocation = Utility:GetItemInfo(string.gsub(statName, "Discovered", ""), true)
					UpdateTycoonStorage:FireClient(player, tostring(saveFolder), statName, value, nil, tostring(acquiredLocation))
					
				end
			end
			
		elseif typeof(sessionData[playerUserId][statName]) == "string" then --Equipped Items
			local equippedItemType = string.gsub(statName, "Equipped", "")
			local equippedItem = playerDataFile.Player.CurrentlyEquipped:FindFirstChild("Equipped" .. saveFolder):FindFirstChild("Equipped" .. equippedItemType)
			equippedItem.Value = value
			
			if saveFolder == "Bags" then --Update Equipped Bag (change bag capacity)
				local itemCount = PlayerStatManager:getItemCount(player)
				local maxItemAmount
				if value and value ~= "" then --if bag is equipped
					maxItemAmount = PlayerStatManager:getEquippedData(player, equippedItemType, "Bags").Value
				else	
					maxItemAmount = 0
				end
				
				UpdateItemCount:FireClient(player, itemCount, maxItemAmount, equippedItemType)
				
			elseif saveFolder == "Tools" then
				UpdateToolbar(player, tostring(equippedItemType), value)
				
			--elseif save Folder == "Pets" then
				
				
			--elseif saveFolder == "Mounts" then
				
			end
			
			UpdateEquippedItem:FireClient(player, saveFolder, equippedItemType, value)
		end
	end
end

------------------------------<|Set Up Player Data|>-----------------------------------------------------------------------------------------------------------------------

function FindPlayerData(JoinedPlayer)
	local PlayerDataFile = PlayerData:FindFirstChild(tostring(JoinedPlayer.UserId))
	local playerUserId = JoinedPlayer.UserId
	
	local success,data = pcall(function()
		return PlayerSave:GetAsync(playerUserId) --Get save data saved as playerUserId
	end)
	
	if success then
		wait(5) --Allow tycoon to be categorized
		if data then --load data
			print("DataStore was Accessed for " .. JoinedPlayer.Name .. " (" .. tostring(JoinedPlayer.UserId) .. ")")
			sessionData[playerUserId] = data
			
			local PlayerCash = LoadPlayerData(PlayerDataFile,data,JoinedPlayer)
			SetTycoonPurchases(JoinedPlayer, PlayerCash, playerUserId)
		else --New player
			print(tostring(JoinedPlayer) .. " is a new player!")
			sessionData[playerUserId] = {} --No data
			
			local PlayerCash = LoadPlayerData(PlayerDataFile,sessionData[playerUserId],JoinedPlayer)
			SetTycoonPurchases(JoinedPlayer, PlayerCash, playerUserId)
		end	
		print("SET TYCOON PURCHASES HAS FINISHED")
	else
		warn("Couldn't Get or Set-Up Player Data For " .. tostring(JoinedPlayer))
		FindPlayerData(JoinedPlayer)
	end		
end

function LoadPlayerData(PlayerDataFile, data, JoinedPlayer)
	print("Loading " .. tostring(JoinedPlayer) .. "'s data")
	local playerUserId = game.Players:FindFirstChild(tostring(JoinedPlayer)).UserId
	local DataMenu = JoinedPlayer.PlayerGui:WaitForChild("DataMenu"):WaitForChild("DataMenu")
	
	local PlayerInventory = CreateSaveReference(PlayerDataFile, "Inventory", "Folder")
	
	local TycoonStorage = CreateSaveReference(PlayerDataFile, "TycoonStorage", "Folder")	
	
	local PlayerResearch = CreateSaveReference(PlayerDataFile, "Research", "Folder")
	local RealResearch = require(game.ServerStorage.ResearchData)
	
	local PlayerExperience = CreateSaveReference(PlayerDataFile, "Experience", "Folder") --Skills, Stats, Reputation
	local SkillsFolder = CreateSaveReference(PlayerExperience, "Skills", "Folder")
	
	local PlayerStatItems = CreateSaveReference(PlayerDataFile, "Player", "Folder")
	local EquippedItems = CreateSaveReference(PlayerStatItems, "CurrentlyEquipped", "Folder")
	
	
	local ResearchersAvailable = CreateSaveReference(PlayerResearch, "ResearchersAvailable", "NumberValue")
	local SavedResearchers = CheckSaveData(data["ResearchersAvailable"])
	ImportSaveData(data, SavedResearchers, PlayerResearch, ResearchersAvailable)
	sessionData[playerUserId]["ResearchersAvailable"] = 5 --for testing right now
	--UpdateResearch:FireClient(JoinedPlayer, nil, nil, nil, nil, 5) --put Researchers in front to prevent heavy nils
	
	local ResearchersUsed = CreateSaveReference(PlayerResearch, "ResearchersUsed", "NumberValue")
	local SavedResearcherUsage = CheckSaveData(data["ResearchersUsed"])
	ImportSaveData(data, SavedResearcherUsage, PlayerResearch, ResearchersUsed)
	local UsedCount = 0
	
	local ResearchTable = RealResearch["Research"]
	for i,researchType in pairs (ResearchTable) do
		local ResearchTypeName = researchType["Research Type Name"]
		local ResearchTypeFolder = CreateSaveReference(PlayerResearch, ResearchTypeName, "Folder")
		
		for r = 1,#researchType,1 do
			if researchType[r] then
				local ResearchData = researchType[r]
				local ResearchName = ResearchData["Research Name"]

				local Research = CreateSaveReference(ResearchTypeFolder, ResearchName, "BoolValue") --true if completed
				local SavedValue = CheckSaveData(data[ResearchName])
				ImportSaveData(data, SavedValue, ResearchTypeFolder, Research)
				
				local PurchasedBool = CreateSaveReference(Research, ResearchName .. "Purchased", "BoolValue")
				local SavedPurchaseBool = CheckSaveData(data[ResearchName .. "Purchased"])
				ImportSaveData(data, SavedPurchaseBool, Research, PurchasedBool, ResearchName .. "Purchased")
				
				local FinishTime = CreateSaveReference(Research, ResearchName .. "FinishTime", "NumberValue")
				local SavedFinishTime = CheckSaveData(data[ResearchName .. "FinishTime"])
				ImportSaveData(data, SavedFinishTime, Research, FinishTime, ResearchName .. "FinishTime")

				--Purchase Handler will have to place the research appropriately or fire the appropriate events
				--so different locations understand the research is now available
				local ClonedResearchData = Utility:CloneTable(ResearchData)
				local CompletionValue = data[ResearchName]
				local PurchasedValue = data[ResearchName .. "Purchased"]
				local FinishTimeValue = data[ResearchName .. "FinishTime"]
				
				UpdateResearch:FireClient(JoinedPlayer, ClonedResearchData, ResearchTypeName, CompletionValue, PurchasedValue, FinishTimeValue)
				
				if PurchasedValue and not CompletionValue then
					UsedCount += 1
				end
			end
		end
	end
	PlayerStatManager:ChangeStat(JoinedPlayer, "ResearchersUsed", UsedCount, "Research")
	
	--Once new experience folder is available, make for all experience folders (Skills and Reputation)
	local RealSkills = game.ReplicatedStorage:WaitForChild("Skills")
	for i,skill in pairs (RealSkills:GetChildren()) do
		local Skill = CreateSaveReference(SkillsFolder, tostring(skill), "NumberValue")
		local SavedValue = CheckSaveData(data[tostring(skill)])
		ImportSaveData(data, SavedValue, SkillsFolder, Skill)
		
		--Make acquired skill tiles
		UpdateInventory:FireClient(JoinedPlayer, tostring(Skill), SkillsFolder.Name, tostring(data[tostring(Skill)]), nil, "Experience", "Skills")
	end

	--All Locations' Item Data
	for i,itemType in pairs (game.ReplicatedStorage.InventoryItems:GetChildren()) do
		for i,item in pairs (itemType:GetChildren()) do
			local associatedSkill = item.AssociatedSkill.Value
			local ItemType = string.gsub(item.AssociatedSkill.Value, "Skill", "")

			local AssociatedFolder = FindAssociatedFolder(PlayerInventory, ItemType, tostring(item))
			local AssociatedItemStorage = FindAssociatedFolder(TycoonStorage, "TycoonStorage" .. ItemType, "TycoonStorage" .. tostring(item))
			
			local Item = CreateSaveReference(AssociatedFolder, tostring(item), "NumberValue")
			local SavedValue = CheckSaveData(data[tostring(item)])
			ImportSaveData(data, SavedValue, AssociatedFolder, Item)
			UpdateInventory:FireClient(JoinedPlayer, tostring(Item), AssociatedFolder.Name, tostring(data[tostring(Item)]), nil, "Inventory", tostring(itemType))
			
			local ItemDiscovery = CreateSaveReference(Item, tostring(Item) .. "Discovered", "BoolValue")
			local SavedDiscoverValue = CheckSaveData(data[tostring(ItemDiscovery)])
			ImportSaveData(data, SavedDiscoverValue, Item, ItemDiscovery)
			UpdateTycoonStorage:FireClient(JoinedPlayer, AssociatedFolder.Name, tostring(Item) .. "Discovered", data[tostring(ItemDiscovery)], nil, tostring(itemType))
			
			local TycoonStorageItem = CreateSaveReference(AssociatedItemStorage, "TycoonStorage" .. tostring(item), "NumberValue")
			local SavedTycoonStorageValue = CheckSaveData(data[tostring(TycoonStorageItem)])
			ImportSaveData(data, SavedTycoonStorageValue, AssociatedItemStorage, TycoonStorageItem)
			UpdateTycoonStorage:FireClient(JoinedPlayer, AssociatedItemStorage.Name, tostring(TycoonStorageItem), tostring(data[tostring(TycoonStorageItem)]), nil, tostring(itemType))   
		end	
	end
	
	--All Data For Equippables (bags, but pickaxes, boots, pets, etc.)
	local Equippables = game.ReplicatedStorage.Equippable
	for _,equiptype in pairs (Equippables:GetChildren()) do
		local EquippedTypeFolder = CreateSaveReference(EquippedItems, "Equipped" .. tostring(equiptype), "Folder")
		local EquipTypeFolder = CreateSaveReference(PlayerStatItems, tostring(equiptype), "Folder")
		
		for _,itemtype in pairs (equiptype:GetChildren()) do
			
			--data["Equipped" .. tostring(itemtype)] is the player's equipped item (string)
			--data[tostring(item)] is if the item is purchased (boolean)
			
			local ItemTypeFolder = CreateSaveReference(EquipTypeFolder, tostring(itemtype), "Folder")
			for _,item in pairs (itemtype:GetChildren()) do
				local Item = CreateSaveReference(ItemTypeFolder, tostring(item), "BoolValue")
				local SavedValue = CheckSaveData(data[tostring(item)])		
				ImportSaveData(data, SavedValue, ItemTypeFolder, Item)
				
				if SavedValue == true then --if previously purchased
					UpdatePlayerMenu:FireClient(JoinedPlayer, tostring(equiptype), tostring(itemtype), tostring(item))
				end
			end
			
			local EquippedItem = CreateSaveReference(EquippedTypeFolder, "Equipped" .. tostring(itemtype), "StringValue")
			local SavedValue = CheckSaveData(data["Equipped" .. tostring(itemtype)])
			ImportSaveData(data, SavedValue, EquippedTypeFolder, EquippedItem)
			
			local EquippedItem = itemtype:FindFirstChild(data["Equipped" .. tostring(itemtype)])
			
			if EquippedItem then
				if tostring(equiptype) == "Bags" then --Update GUI Menus (Inventory Bag # Limits)
					local MenuName = "MaterialsMenu"
					local bagStats = equipmentData["Bags"][tostring(itemtype)][tostring(EquippedItem)]
					DataMenu:WaitForChild("InventoryMenu"):FindFirstChild(MenuName):SetAttribute("BagCapacity", bagStats["Stats"]["Bag Capacity"])

					local ItemCount = PlayerStatManager:getItemCount(JoinedPlayer)
					DataMenu:WaitForChild("InventoryMenu"):FindFirstChild(MenuName):SetAttribute("ItemCount", ItemCount)
				end
				
				if tostring(equiptype) == "Tools" then
					UpdateToolbar(JoinedPlayer, tostring(itemtype), tostring(EquippedItem))
				end

				UpdateEquippedItem:FireClient(JoinedPlayer, tostring(equiptype), tostring(itemtype), tostring(EquippedItem))
			else
				UpdateEquippedItem:FireClient(JoinedPlayer, tostring(equiptype), tostring(itemtype), "")
			end
		end
	end
	
	local CurrencyFolder = CreateSaveReference(PlayerDataFile, "Currencies", "Folder")
	local UniversalCurrency = CreateSaveReference(CurrencyFolder, "UniversalCurrencies", "Folder")
	local Currency = CreateSaveReference(UniversalCurrency, "Coins", "NumberValue")

	local PlayerCash = UniversalCurrency:FindFirstChild("Coins")
	
	local SavedValue = CheckSaveData(data[tostring("Coins")])
	if SavedValue == false then
		PlayerCash.Value = 0
		data[tostring("Coins")] = PlayerCash.Value
	else
		PlayerCash.Value = PlayerCash.Value + data[tostring("Coins")]
	end
	
	print(tostring(JoinedPlayer) .. " has $" .. tostring(data["Coins"]))
	return PlayerCash.Value
end

function SetTycoonPurchases(JoinedPlayer, PlayerCash, playerUserId)
	for i = 1,#tycoons,1 do 
		local TycoonAssetsHandler = require(tycoons[i]:WaitForChild("TycoonAssetsHandler")) --Tycoon's possible purchases (table)
		local data = sessionData[playerUserId]

		--Set-up Entrance Save
		local Entrance = tycoons[i].Entrance.Name
		if data[Entrance] == nil then --Change name of entrance for multiple tycoon purchases
			print("Setting Entrance to Unbought")
			data[Entrance] = false
		end

		for key,_ in pairs(TycoonAssetsHandler) do
			if data[key] == nil then --if a value of the object hasn't been placed in player's sessiondata,
				--Make one, and set it equal to false (so it can be set to true later)
				data[key] = false --Set the objects as not bought
			end
		end	

		Utility:UpdateMoneyDisplay(JoinedPlayer, Utility:ConvertShort(PlayerCash))
	end
end

----------------------------------------<|Get Item Info Functions|>------------------------------------------------------------------------------------------------------

function PlayerStatManager:getPlayerData(player)
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId
	return sessionData[playerUserId]
end 

function PlayerStatManager:getStat(player, statName) --Stat Check
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId
	
	if sessionData[playerUserId] then
		return sessionData[playerUserId][statName]
	else
		warn(player," does not have save data! Trying again...") --possibly kick player from game and tell to try again
		wait(2)
		PlayerStatManager:getStat(player, statName)
	end
end 

function PlayerStatManager:getItemCount(player) --For Amount in Bag Checking
	local playerUserId = player.UserId
	local PlayerDataFile = game.ServerStorage.PlayerData:FindFirstChild(tostring(playerUserId))
	
	local inventoryAmount = 0
	for _,itemTypeFolder in pairs (PlayerDataFile.Inventory:GetChildren()) do --if item type checks come back, it can be checked here
		for _,statData in pairs (itemTypeFolder:GetChildren()) do
			inventoryAmount += statData.Value
		end
	end
	
	return inventoryAmount
end

function PlayerStatManager:getEquippedData(player, itemType, equipType)
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId
	local PlayerDataFile = game.ServerStorage.PlayerData:FindFirstChild(tostring(playerUserId))
	
	if PlayerDataFile.Player.CurrentlyEquipped:FindFirstChild("Equipped" .. equipType):FindFirstChild("Equipped" .. itemType) then
		local equippedItem = PlayerDataFile.Player.CurrentlyEquipped:FindFirstChild("Equipped" .. equipType):FindFirstChild("Equipped" .. itemType)
		local equipmentName = equippedItem.Value

		if equipmentName ~= "" then
			local maxAmount = equipmentData[equipType][itemType][equipmentName]["Stats"]["Bag Capacity"]
				--game.ReplicatedStorage.Equippable:FindFirstChild(Type):FindFirstChild(Equippable):FindFirstChild(EquipmentName)
			return maxAmount
		end
	else
		warn("Could not find equippable for " .. tostring(player) .. " with name: " .. itemType)
	end
end

function PlayerStatManager:initiateSaving(player, statName, PlayerMoney)
	--print("Saving Data for Player: " .. tostring(player))
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId

	sessionData[playerUserId][statName] = PlayerMoney
	--print("Saving Data for Player: " .. tostring(player))
	
	SavePlayerData(playerUserId)
end

--------------------------------<|Equip Functions|>----------------------------------------------------------------------------------------------

function UpdateToolbar(Player, ItemType, NewlyEquippedItem)
	local ItemTypeFolder = game.ReplicatedStorage.Equippable.Tools:FindFirstChild(ItemType)
	
	--Delete existing items of type from backpack
	for i,item in pairs (Player.Backpack:GetChildren()) do
		if ItemTypeFolder:FindFirstChild(tostring(item)) then
			item:Destroy()
		end
	end
	--check if holding item of same type
	for i,item in pairs (workspace.Players:FindFirstChild(tostring(Player)):GetChildren()) do
		if item:IsA("Tool") then
			if ItemTypeFolder:FindFirstChild(tostring(item)) then
				item:Destroy()
			end
		end
	end
	
	if NewlyEquippedItem and NewlyEquippedItem ~= "" then
		local Tool = ItemTypeFolder:FindFirstChild(NewlyEquippedItem):Clone()
		Tool.Parent = Player.Backpack
	end
end

-----------------------------<|Stat-Handling Remote Events/Functions|>------------------------------------------------------------------------------------------

local getItemStats = EventsFolder.Utility:WaitForChild("GetItemStats")
function getItemStats.OnServerInvoke(player, dataType, equipType, itemType, itemName)
	local dataModule = require(game.ServerStorage:FindFirstChild(dataType .. "Data"))

	local itemInfo
	if dataType == "Equipment" then
		itemInfo = dataModule[equipType][itemType][itemName]
	else
		itemInfo = dataModule[itemType][itemName]
	end
	
	if itemInfo then
		local cloneInfo = Utility:CloneTable(itemInfo)
		return cloneInfo
	else
		warn(player, " is exploiting. Trying to grab false equipmentStats")
	end
end

local SellItem = EventsFolder.Utility:WaitForChild("SellItem")
SellItem.OnServerEvent:Connect(function(Player, Menu, item, Percentage)--, Amount)
	if Percentage >= 0 and Percentage <= 1 then
		local playerUserId = game.Players:FindFirstChild(tostring(Player)).UserId

		local itemInfo = Utility:GetItemInfo(item)

		if itemInfo then
			local ItemWorth = tonumber(itemInfo.CurrencyValue.Value)
			local Amount = math.ceil(Percentage * sessionData[playerUserId]["TycoonStorage" .. tostring(itemInfo)])
			local SellAmount = Amount*ItemWorth

			print("Selling " .. tostring(Amount) .. " " .. tostring(itemInfo) .. "'s for $" .. tostring(SellAmount))

			PlayerStatManager:ChangeStat(Player, "Coins", SellAmount, "Currencies", true) --Update Currency
			PlayerStatManager:ChangeStat(Player, "TycoonStorage" .. tostring(itemInfo), -Amount, "TycoonStorage")
		else
			--exploiter
			warn("Item could not be found to sell!")
		end
	end
end)

DepositInventory.OnServerEvent:Connect(function(Player)
	local PlayerDataFile = PlayerData:FindFirstChild(tostring(Player.UserId))
	for i,folder in pairs (PlayerDataFile.Inventory:GetChildren()) do
		for i,item in pairs (folder:GetChildren()) do
			local InventoryValue = item.Value --the value of the item is one more than the actual value
			if InventoryValue > 0 then
				--Update Inventory
				PlayerStatManager:ChangeStat(Player, tostring(item), 0, "Inventory", nil, "Zero")
				item.Value = 0

				--Update Storage
				PlayerStatManager:ChangeStat(Player, "TycoonStorage" .. tostring(item), InventoryValue, "TycoonStorage")
				print(PlayerDataFile.Inventory:FindFirstChild(tostring(folder)):FindFirstChild(tostring(item)).Value)

				--Call Inventory to Wipe Previous Pages and Tiles
				DepositInventory:FireClient(Player)
			end
		end
	end

	return true
end)

local GetItemCountSum = EventsFolder.Utility:WaitForChild("GetItemCountSum")
function GetItemCountSum.OnServerInvoke(Player, StatName)
	local PlayerUserId = Player.UserId
	local InventoryAmount = sessionData[PlayerUserId][StatName]
	local StorageAmount = sessionData[PlayerUserId]["TycoonStorage" .. StatName]
	
	return InventoryAmount + StorageAmount
end

local GetCurrentSkillLevel = EventsFolder.Utility:WaitForChild("GetCurrentSkillLevel")
function GetCurrentSkillLevel.OnServerInvoke(Player, SkillInfo)
	local PlayerUserId = Player.UserId
	local ExpAmount = sessionData[PlayerUserId][tostring(SkillInfo)]
	
	local HighestLevel
	for i,level in pairs (SkillInfo.Levels:GetChildren()) do
		if level.Value <= ExpAmount then
			if HighestLevel then
				if level.Value > HighestLevel.Value then
					HighestLevel = level
				end
			else
				HighestLevel = level
			end
		end
	end
	return tonumber(HighestLevel.Name)
end

function CheckResearchDepends.OnServerInvoke(Player, ResearchData)
	local Dependencies = ResearchData["Dependencies"]
	
	local DependenciesMet = 0
	for i,dependency in pairs (Dependencies) do
		local ResearchCompleted = PlayerStatManager:getStat(Player, dependency)
		if ResearchCompleted then
			DependenciesMet += 1
		end
	end
	
	if DependenciesMet == #Dependencies then
		return true
	end
end

--Fires when player equips new item (must be saved for when they join back)
UpdateEquippedItem.OnServerEvent:Connect(function(Player, EquipType, ItemType, NewlyEquippedItem)
	local playerUserId = Player.UserId
	local PlayerDataFile = PlayerData:FindFirstChild(tostring(playerUserId))
	local EquipValue = PlayerDataFile.Player.CurrentlyEquipped:FindFirstChild("Equipped" .. EquipType):FindFirstChild("Equipped" .. ItemType)

	--Check if value selected is not already equipped
	if NewlyEquippedItem then
		if NewlyEquippedItem ~= sessionData[playerUserId]["Equipped" .. ItemType] then --If not already equipped
			if sessionData[playerUserId][NewlyEquippedItem] == true then --Item is purchased
				if EquipType == "Tools" then --must update player hotbar
					UpdateToolbar(Player, ItemType, NewlyEquippedItem)
				end
					
				EquipValue.Value = NewlyEquippedItem
				PlayerStatManager:ChangeStat(Player, "Equipped" .. ItemType, NewlyEquippedItem, EquipType)	
			end
		end
	else --Unequipped Item, set value for equipped item to nil
		if EquipType == "Tools" then
			UpdateToolbar(Player, ItemType)
		end
		
		EquipValue.Value = ""
		PlayerStatManager:ChangeStat(Player, "Equipped" .. ItemType, "", EquipType)	
	end
end)

local HandleDropMaterialsEvent = EventsFolder.Tycoon:WaitForChild("HandleDropMaterials")
local function HandleDropMaterials(Tycoon, Drop) --Update Tycoon Storage for drop's worth
	local Player = Tycoon:FindFirstChild("Owner").Value
	local playerUserId = game.Players:FindFirstChild(tostring(Player)).UserId
	local PlayerDataFile = PlayerData:FindFirstChild(playerUserId)
	local OwnedTycoon = PlayerDataFile:FindFirstChild("OwnsTycoon").Value
	
	--Match player with saved Tycoon value in player data storage (prevent exploiters)
	if tostring(Tycoon) == tostring(OwnedTycoon) then
		if Drop:FindFirstChild("Materials") then	
			for i,file in pairs (Drop.Materials:GetChildren()) do
				for i,material in pairs (file:GetChildren()) do
					PlayerStatManager:ChangeStat(Player, "TycoonStorage" .. tostring(material), material.Value, "TycoonStorage")
					
					print(file, material) --Change this so it grabs "Mining" to reference for item instead of mineshaft
					local itemInfo = Utility:GetItemInfo(tostring(material), true)
					
					local discoverValue = PlayerDataFile.Inventory:FindFirstChild(tostring(itemInfo)):FindFirstChild(tostring(material)):FindFirstChild(tostring(material) .. "Discovered")
					if discoverValue == false then
						PlayerStatManager:ChangeStat(Player,tostring(material) .. "Discovered", true, tostring(file))
					end
				end
			end
		end
	end
end
HandleDropMaterialsEvent.Event:Connect(HandleDropMaterials)


return PlayerStatManager

