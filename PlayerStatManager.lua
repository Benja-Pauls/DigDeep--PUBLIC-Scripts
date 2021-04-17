--(ModuleScript)
--Handles all saving that occurs. Any true saving (ROBLOX data store assigning)
-------------------------------------------------------------------------------------------------------------------------------------------------
local PlayerStatManager = {}

local tycoons = game.Workspace:WaitForChild("Tycoons"):GetChildren()

local PlayerData = game.ServerStorage:FindFirstChild("PlayerData")
local Utility = require(game.ServerScriptService:WaitForChild("Utility"))

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
local PlayerSave = DataStoreService:GetDataStore("Tycoon Test202") --Changing this will change the datastore info is taken from

--When player joins
game.Players.PlayerAdded:Connect(function(JoinedPlayer)
	print(tostring(JoinedPlayer) .. " has joined the game")
	if PlayerData:FindFirstChild(JoinedPlayer.UserId) == nil then --Server startup, make new folder
		local PlayerDataStorage = Instance.new('Folder', PlayerData) 
		PlayerDataStorage.Name = tostring(JoinedPlayer.UserId)
	end

	local PlayerDataFile = PlayerData:FindFirstChild(JoinedPlayer.UserId)
	
	local isOwner = Instance.new("ObjectValue", PlayerDataFile)
	isOwner.Name = "OwnsTycoon"

	if game.Workspace:WaitForChild(tostring(JoinedPlayer)) then
		print(tostring(JoinedPlayer),"'s CHARACTER WAS ASSIGNED TO PLAYERS FOLDER")
		local Character = game.Workspace:FindFirstChild(tostring(JoinedPlayer))
		
		repeat wait() until Character:FindFirstChild("LowerTorso")
		Character.Parent = game.Workspace:WaitForChild("Players")

		--Way to make this a softer glow?
		local Light = Instance.new("PointLight")
		Light.Brightness = 7
		Light.Range = 7
		Light.Parent = Character.Head
		
		--Insert ProxPrompt in Player Here? (if players need to interact with each other
	end
	
	FindPlayerData(JoinedPlayer)
end)

--When player leaves
game.Players.PlayerRemoving:Connect(function(JoinedPlayer)
	local PlayerDataFile = PlayerData:FindFirstChild(tostring(JoinedPlayer.UserId))
	
	if PlayerDataFile ~= nil then --Remove player from ServerStorage
		PlayerDataFile:Destroy()
	end
	--Tycoon is removed via TycoonControl script
end)

local sessionData = {}

--------------------------<|Utility Functions|>----------------------------------------------------------------------------------------------------------------------------------

GetBagCount.OnInvoke = function(Player, ItemInfo)
	local ItemType = string.gsub(ItemInfo.Bag.Value, "Bag", "")
	local Amount = PlayerStatManager:getItemTypeCount(Player, ItemType .. "s")
	local MaxAmount = PlayerStatManager:getEquippedData(Player, ItemInfo.Bag.Value .. "s", "Bags")
	
	if Amount and MaxAmount then
		return Amount,MaxAmount.Value,ItemType .. "s"
	else
		return Amount,nil,ItemType .. "s"
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

local function FindItemInfo(statName, bagType, locationOnly)
	for i,location in pairs (game.ReplicatedStorage.ItemLocations:GetChildren()) do
		if location:FindFirstChild(statName) then
			if string.gsub(location:FindFirstChild(statName).Bag.Value, "Bag", "") .. "s" == bagType then
				if locationOnly then
					return location
				else
					return location:FindFirstChild(statName)
				end
			end
		end
	end	
end

local function FindAssociatedFolder(MotherFolder, ItemType, ItemName)
	if MotherFolder:FindFirstChild(ItemType) then --make this a check folder existence function (utility section at end or start of code?)
		if not MotherFolder:FindFirstChild(ItemType):FindFirstChild(ItemName) then --if item not already inputted from other location
			return MotherFolder:FindFirstChild(ItemType)
		end
	else
		return CreateSaveReference(MotherFolder, ItemType, "Folder")
	end
end

local function SavePlayerData(playerUserId)
	if sessionData[playerUserId] then --if there is a sessiondata value with the player's userid...
		local success = pcall(function() --Check to make sure it is saving
			PlayerSave:SetAsync(playerUserId, sessionData[playerUserId]) --save sessionData[playerUserId] as playerUserId
			print(playerUserId .. "'s held data was SAVED!")
			--playerUserId = string (key), and sessionData[playerUserId] = variant (value of given key)
		end)
		if not success then
			warn("Cannot save data for " .. tostring(playerUserId))
		end
	end
end

---------------------<|High-Traffic Functions|>--------------------------------------------------------------------------------------------------------------------------------------

local function UpdateGUIForFile(DataTabName, PlayerDataFile, player, playerUserId, statName, value)
	local DataTab = PlayerDataFile:FindFirstChild(DataTabName) --Example: (UserId).Experience
	for i,file in pairs (DataTab:GetChildren()) do
		if file:FindFirstChild(tostring(statName)) then --DataTab:FindFirstChild(file):FindFirstChild(statName)?
			local total = sessionData[playerUserId][statName]
			local amountAdded = value
			
			if tostring(DataTabName) == "Inventory" or tostring(DataTabName) == "Experience" then
				local LocationOfAcquirement
				if tostring(DataTabName) == "Inventory" then
					LocationOfAcquirement = FindItemInfo(statName, tostring(file), true)
					
					--Update Bag
					local TypeAmount = PlayerStatManager:getItemTypeCount(player, tostring(file))
					local MaxItemAmount = PlayerStatManager:getEquippedData(player, LocationOfAcquirement:FindFirstChild(statName).Bag.Value .. "s", "Bags") --Bag capacity
					if MaxItemAmount then
						if value ~= 0 then
							UpdateItemCount:FireClient(player, TypeAmount+1, MaxItemAmount.Value, tostring(file))
						else
							UpdateItemCount:FireClient(player, 0, MaxItemAmount.Value, tostring(file), true)
						end
					end
				else
					LocationOfAcquirement = "Skills"
				end
				
				--Finally, update inventory information
				if LocationOfAcquirement then	
					UpdateInventory:FireClient(player, statName, tostring(file), tostring(total), amountAdded, tostring(DataTab), nil, tostring(LocationOfAcquirement))
				else
					warn("Item (" .. statName .. ") has no location of acquirement")
				end
				
			elseif tostring(DataTabName) == "TycoonStorage" then
				local LocationOfAcquirement = FindItemInfo(string.gsub(statName, "TycoonStorage", ""), string.gsub(tostring(file), "TycoonStorage", ""), true)
				--print(tostring(file), statName, tostring(total), amountAdded, LocationOfAcquirement)
				UpdateTycoonStorage:FireClient(player, tostring(file), statName, tostring(total), amountAdded, LocationOfAcquirement)
				
			elseif tostring(DataTabName) == "Currencies" then
				local RScurrency = game.ReplicatedStorage.Currencies:FindFirstChild(statName)
				
				--if Global currency
				Utility:UpdateMoneyDisplay(player, Utility:ConvertShort(total))
				UpdateInventory:FireClient(player, statName, tostring(DataTab), nil, amountAdded, "Inventory", RScurrency.Value)
				--(put inventory for parameter so popup shows up; otherwise, leave nil.)
			end
		end
	end
end

--Change saved stat to new value
function PlayerStatManager:ChangeStat(player, statName, value, Folder, ItemType, special)
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId
	local PlayerDataFile = PlayerData:FindFirstChild(tostring(playerUserId))
	
	--print(typeof(sessionData[playerUserId][statName]),typeof(value),statName,sessionData[playerUserId][statName])	
	assert(typeof(sessionData[playerUserId][statName]) == typeof(value), tostring(player) .. "'s saved value types don't match")
	if typeof(sessionData[playerUserId][statName]) == "number" then
		if sessionData[playerUserId][statName] ~= sessionData[playerUserId][statName] + value or special then --if changed	
			
			if special == "Zero" then
				sessionData[playerUserId][statName] = 0
			else
				sessionData[playerUserId][statName] = sessionData[playerUserId][statName] + value
			end
	
			if Folder then 
				UpdateGUIForFile(tostring(Folder), PlayerDataFile, player, playerUserId, statName, value)
			end
			
			--Client script data management so exploiters cant handle sensitive data
			--Updating where data is stored in ServerStorage (viewed by server scripts)
			print(player, statName, value, Folder, PlayerDataFile)
			for i,file in pairs (PlayerDataFile:FindFirstChild(Folder):GetChildren()) do
				if file:FindFirstChild(statName) then
					file:FindFirstChild(statName).Value = sessionData[playerUserId][statName]
				end
			end
		end
	else --bool and string values
		sessionData[playerUserId][statName] = value 

		if typeof(sessionData[playerUserId][statName]) == "boolean" then
			if Folder then
				if game.ReplicatedStorage.Equippable:FindFirstChild(Folder) then --Player Item Purchase Bool
					UpdatePlayerMenu:FireClient(player, Folder, ItemType, statName)
					PlayerDataFile.Player:FindFirstChild(Folder):FindFirstChild(ItemType):FindFirstChild(statName).Value = value
					
				elseif string.find(statName, "Discovered") then
					--Unlock tile in tycoon storage
					local LocationOfAcquirement = FindItemInfo(string.gsub(statName, "Discovered", ""), tostring(Folder), true)
					UpdateTycoonStorage:FireClient(player, tostring(Folder), statName, value, nil, LocationOfAcquirement)
				end
			end
		else
			local ItemType = string.gsub(statName, "Equipped", "")
			
			if Folder == "Bags" then --Update Equipped Bag (change bag capacity)
				local TypeAmount = PlayerStatManager:getItemTypeCount(player, string.gsub(ItemType, "Bag", ""))
				local MaxItemAmount
				if value and value ~= "" then
					MaxItemAmount = PlayerStatManager:getEquippedData(player, ItemType, "Bags").Value
				else	
					MaxItemAmount = 0
				end
				
				UpdateItemCount:FireClient(player, TypeAmount, MaxItemAmount, ItemType)
				
			elseif Folder == "Tools" then
				UpdateToolbar(player, tostring(ItemType), value)
			end
			
			UpdateEquippedItem:FireClient(player, Folder, ItemType, value)
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
				
				--wait(.5)
				UpdateResearch:FireClient(JoinedPlayer, ClonedResearchData, ResearchTypeName, CompletionValue, PurchasedValue, FinishTimeValue)
			end
		end
	end
	
	--Once new experience folder is available, make for all experience folders (Skills and Reputation)
	local RealSkills = game.ReplicatedStorage:WaitForChild("Skills")
	for i,skill in pairs (RealSkills:GetChildren()) do
		local Skill = CreateSaveReference(SkillsFolder, tostring(skill), "NumberValue")
		local SavedValue = CheckSaveData(data[tostring(skill)])
		ImportSaveData(data, SavedValue, SkillsFolder, Skill)
		
		--Make acquired skill tiles
		UpdateInventory:FireClient(JoinedPlayer, tostring(Skill), SkillsFolder.Name, tostring(data[tostring(Skill)]), nil, "Experience", nil, "Skills")
	end

	--All Locations' Item Data
	for i,location in pairs (game.ReplicatedStorage.ItemLocations:GetChildren()) do
		for i,item in pairs (location:GetChildren()) do --change to mine materials (no longer sorted by type in RS, rather location purposes
			local AssociatedBag = item.Bag.Value
			local ItemType = string.gsub(AssociatedBag, "Bag", "") .. "s"

			local AssociatedFolder = FindAssociatedFolder(PlayerInventory, ItemType, tostring(item))
			local AssociatedItemStorage = FindAssociatedFolder(TycoonStorage, "TycoonStorage" .. ItemType, "TycoonStorage" .. tostring(item))
			
			local Item = CreateSaveReference(AssociatedFolder, tostring(item), "NumberValue")
			local SavedValue = CheckSaveData(data[tostring(item)])
			ImportSaveData(data, SavedValue, AssociatedFolder, Item)
			UpdateInventory:FireClient(JoinedPlayer, tostring(Item), AssociatedFolder.Name, tostring(data[tostring(Item)]), nil, "Inventory", nil, tostring(location))
			
			local ItemDiscovery = CreateSaveReference(Item, tostring(Item) .. "Discovered", "BoolValue")
			local SavedDiscoverValue = CheckSaveData(data[tostring(ItemDiscovery)])
			ImportSaveData(data, SavedDiscoverValue, Item, ItemDiscovery)
			UpdateTycoonStorage:FireClient(JoinedPlayer, AssociatedFolder.Name, tostring(Item) .. "Discovered", data[tostring(ItemDiscovery)], nil, tostring(location))
			
			local TycoonStorageItem = CreateSaveReference(AssociatedItemStorage, "TycoonStorage" .. tostring(item), "NumberValue")
			local SavedTycoonStorageValue = CheckSaveData(data[tostring(TycoonStorageItem)])
			ImportSaveData(data, SavedTycoonStorageValue, AssociatedItemStorage, TycoonStorageItem)
			UpdateTycoonStorage:FireClient(JoinedPlayer, AssociatedItemStorage.Name, tostring(TycoonStorageItem), tostring(data[tostring(TycoonStorageItem)]), nil, tostring(location))   
		end	
	end
	
	--All Data For Equippables (bags, but pickaxes, boots, pets, etc.)
	local Equippables = game.ReplicatedStorage.Equippable
	for i,equiptype in pairs (Equippables:GetChildren()) do
		local EquippedTypeFolder = CreateSaveReference(EquippedItems, "Equipped" .. tostring(equiptype), "Folder")
		local EquipTypeFolder = CreateSaveReference(PlayerStatItems, tostring(equiptype), "Folder")
		
		for i,itemtype in pairs (equiptype:GetChildren()) do
			
			--data["Equipped" .. tostring(itemtype)] is the player's equipped item (string)
			--data[tostring(item)] is if the item is purchased (boolean)
			
			local ItemTypeFolder = CreateSaveReference(EquipTypeFolder, tostring(itemtype), "Folder")
			for i,item in pairs (itemtype:GetChildren()) do
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
					local MenuName = string.gsub(tostring(itemtype), "Bag", "") .. "Menu"
					DataMenu:WaitForChild("InventoryMenu"):FindFirstChild(MenuName):SetAttribute("BagCapacity", EquippedItem.Value)

					local ItemCount = PlayerStatManager:getItemTypeCount(JoinedPlayer, string.gsub(tostring(itemtype), "Bag", ""))
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
	local Currency = CreateSaveReference(UniversalCurrency, "Currency", "NumberValue")

	local PlayerCash = UniversalCurrency:FindFirstChild("Currency")
	
	local SavedValue = CheckSaveData(data[tostring("Currency")])
	if SavedValue == false then
		PlayerCash.Value = 0
		data[tostring("Currency")] = PlayerCash.Value
	else
		PlayerCash.Value = PlayerCash.Value + data[tostring("Currency")]
	end
	
	print(tostring(JoinedPlayer) .. " has $" .. tostring(data["Currency"]))
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
	return sessionData[playerUserId][statName]
end 

function PlayerStatManager:getItemTypeCount(player, Type) --For Amount in Bag Checking
	local playerUserId = player.UserId
	local PlayerDataFile = game.ServerStorage.PlayerData:FindFirstChild(tostring(playerUserId))
	local TypeSaveFolder = PlayerDataFile.Inventory:FindFirstChild(Type)
	
	if TypeSaveFolder then
		local Amount = 0
		for i,statData in pairs (TypeSaveFolder:GetChildren()) do
			Amount = Amount + statData.Value
		end
		return Amount
	end
end

function PlayerStatManager:getEquippedData(player, Equippable, Type)
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId
	local PlayerDataFile = game.ServerStorage.PlayerData:FindFirstChild(tostring(playerUserId))
	
	if PlayerDataFile.Player.CurrentlyEquipped:FindFirstChild("Equipped" .. Type):FindFirstChild("Equipped" .. Equippable) then
		local EquippedItem = PlayerDataFile.Player.CurrentlyEquipped:FindFirstChild("Equipped" .. Type):FindFirstChild("Equipped" .. Equippable)
		local EquipmentName = EquippedItem.Value
		
		if EquipmentName ~= "" then
			local EquipmentStats = game.ReplicatedStorage.Equippable:FindFirstChild(Type):FindFirstChild(Equippable):FindFirstChild(EquipmentName)
			return EquipmentStats
		end
	else
		warn("Could not find equippable for " .. tostring(player) .. " with name: " .. Equippable)
	end
end

function PlayerStatManager:initiateSaving(player, statName, value)
	print("Saving Data for Player: " .. tostring(player))
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId

	sessionData[playerUserId][statName] = value 
	print(tostring(player) .. "'s Money: $" .. tostring(sessionData[playerUserId]["Currency"]))
	
	SavePlayerData(playerUserId) --After saving money amount, update datastore for other stats!
	--Other stats include purhcases, inventory, etc.
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
	
	if NewlyEquippedItem and NewlyEquippedItem ~= "" then
		local Tool = ItemTypeFolder:FindFirstChild(NewlyEquippedItem):Clone()
		Tool.Parent = Player.Backpack
	end
end

-----------------------------<|Stat-Handling Remote Events/Functions|>------------------------------------------------------------------------------------------

local SellItem = EventsFolder.Utility:WaitForChild("SellItem")
SellItem.OnServerEvent:Connect(function(Player, Menu, item, Percentage)--, Amount)
	if Percentage >= 0 and Percentage <= 1 then
		local playerUserId = game.Players:FindFirstChild(tostring(Player)).UserId

		local Item = FindItemInfo(item, tostring(Menu))

		if Item then
			local ItemWorth = tonumber(Item.CurrencyValue.Value)
			local Amount = math.ceil(Percentage * sessionData[playerUserId]["TycoonStorage" .. tostring(Item)])
			local SellAmount = Amount*ItemWorth

			print("Selling " .. tostring(Amount) .. " " .. tostring(Item) .. "'s for $" .. tostring(SellAmount))

			PlayerStatManager:ChangeStat(Player, "Currency", SellAmount, "Currencies", true) --Update Currency
			PlayerStatManager:ChangeStat(Player, "TycoonStorage" .. tostring(Item), -Amount, "TycoonStorage")
		else
			warn("Item could not be found to sell!")
		end
		--else
		--exploiter warning
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
	
	--Ensure Item Type for bag is 0 if under else statement; otherwise, exploiter changed values
	
	print(Player, EquipType, ItemType, NewlyEquippedItem)
	
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

					PlayerStatManager:ChangeStat(Player,tostring(material) .. "Discovered", true, tostring(file))
				end
			end
		end
	end
end
HandleDropMaterialsEvent.Event:Connect(HandleDropMaterials)


return PlayerStatManager

