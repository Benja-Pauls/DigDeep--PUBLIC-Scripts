--(ModuleScript)
--Handles all saving that occurs. Any true saving (ROBLOX data store assigning)
-------------------------------------------------------------------------------------------------------------------------------------------------
local PlayerStatManager = {}

local tycoons = game.Workspace:WaitForChild("Tycoons"):GetChildren() --utilize as a load before getting player data?

local playerData = game.ServerStorage:FindFirstChild("PlayerData")

local Utility = require(game.ServerScriptService.Utility)
local equipmentData = require(game.ServerStorage.EquipmentData)
local experienceData = require(game.ServerStorage.ExperienceData)
local itemData = require(game.ServerStorage.ItemData)
local researchData = require(game.ServerStorage.ResearchData)

-----<|Events/Functions|>-----     (displayed in order called within folders)
local eventsFolder = game.ReplicatedStorage.Events

local awardLevelRewards = eventsFolder.GUI:WaitForChild("AwardLevelRewards")
local displayCurrencyPopUp = eventsFolder.GUI:WaitForChild("DisplayCurrencyPopUp")
local updateExperience = eventsFolder.GUI:WaitForChild("UpdateExperience")
local updateInventory = eventsFolder.GUI:WaitForChild("UpdateInventory")
local updateTycoonStorage = eventsFolder.GUI:WaitForChild("UpdateTycoonStorage")
local updatePlayerMenu = eventsFolder.GUI:WaitForChild("UpdatePlayerMenu")
local updateItemCount = eventsFolder.GUI:WaitForChild("UpdateItemCount")
local updateResearch = eventsFolder.GUI:WaitForChild("UpdateResearch")
local updateEquippedItem = eventsFolder.GUI:WaitForChild("UpdateEquippedItem")

local getItemStatTable = eventsFolder.Utility:WaitForChild("GetItemStatTable")
local getItemCountSum = eventsFolder.Utility:WaitForChild("GetItemCountSum")
local getBagCount = eventsFolder.Utility:WaitForChild("GetBagCount")
local getCurrentPlayerLevel = eventsFolder.Utility:WaitForChild("GetCurrentPlayerLevel")
local sellItem = eventsFolder.Utility:WaitForChild("SellItem")
local depositInventory = eventsFolder.Utility:WaitForChild("DepositInventory")
local checkResearchDepends = eventsFolder.Utility:WaitForChild("CheckResearchDepends")
local checkPlayerStat = eventsFolder.Utility:WaitForChild("CheckPlayerStat")

local handleDropMaterialsEvent = eventsFolder.Tycoon:WaitForChild("HandleDropMaterials")

-------------------------<|Set Up Game|>--------------------------------------------------------------------------------------------------------------------------------------
local DataStoreService = game:GetService("DataStoreService") 
local PlayerSave = DataStoreService:GetDataStore("Tycoon Test212") --Changing this will change the datastore info is taken from

--When player joins
game.Players.PlayerAdded:Connect(function(joinedPlayer)
	print(tostring(joinedPlayer) .. " has joined the game")
	
	if playerData:FindFirstChild(joinedPlayer.UserId) == nil then --Server startup, make new folder
		local playerDataStorage = Instance.new('Folder', playerData) 
		playerDataStorage.Name = tostring(joinedPlayer.UserId)
	end

	local playerDataFile = playerData:FindFirstChild(joinedPlayer.UserId)
	
	local isOwner = Instance.new("ObjectValue", playerDataFile)
	isOwner.Name = "OwnsTycoon"

	if game.Workspace:WaitForChild(tostring(joinedPlayer)) then
		print(tostring(joinedPlayer),"'s CHARACTER WAS ASSIGNED TO PLAYERS FOLDER")
		local character = game.Workspace:FindFirstChild(tostring(joinedPlayer))
		
		repeat wait() until character:FindFirstChild("LowerTorso") --Player has loaded in
		character.Parent = game.Workspace:WaitForChild("Players")

		--Glow around character (way to make this softer?)
		local light = Instance.new("PointLight")
		light.Brightness = 7
		light.Range = 7
		light.Parent = character.HumanoidRootPart
		
		--Display Player's Name and Title
		character:WaitForChild("Humanoid").DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		local nameDisplay = game.ReplicatedStorage.GuiElements.NameDisplay:Clone()
		nameDisplay.Parent = character
		nameDisplay.Adornee = character.HumanoidRootPart
		nameDisplay.TextLabel.Text = tostring(joinedPlayer)
		
		--**Insert ProxPrompt in Player Here? (if players need to interact with each other)
	end
	
	findPlayerData(joinedPlayer)
end)

--When player leaves
game.Players.PlayerRemoving:Connect(function(joinedPlayer)
	local playerDataFile = playerData:FindFirstChild(tostring(joinedPlayer.UserId))
	
	if playerDataFile ~= nil then --Remove player from ServerStorage
		playerDataFile:Destroy()
	end
	--Tycoon is removed via TycoonHandler script
end)

local sessionData = {}

--------------------------<|Utility Functions|>----------------------------------------------------------------------------------------------------------------------------------

local function checkSaveData(save)
	if not save then
		return false --Nothing, not even 0, "", or false, has been recorded for this save value
	else
		return true
	end
end

-- Update ServerStorage Folders With Data
local function importSaveData(data, previousSave, saveName, refer)
	if not previousSave then
		if typeof(refer.Value) == "number" then
			refer.Value = 0
		elseif typeof(refer.Value) == "boolean" then
			refer.Value = false
		else
			refer.Value = ""
		end
	end
	
	if data[saveName] == nil then
		data[saveName] = refer.Value -- laceholder value to create (even if not interacted with yet)
	else
		refer.Value = data[saveName]
	end
end

-- Create folder in ServerStorage for player's data file
local function createSaveReference(parentFolder, folderName, instanceType)
	local newFolder = Instance.new(instanceType, parentFolder)
	newFolder.Name = folderName
	return newFolder
end

local function findAssociatedFolder(parentDataFolder, itemTypeName, itemName)
	if parentDataFolder:FindFirstChild(itemTypeName) then 
		if not parentDataFolder:FindFirstChild(itemTypeName):FindFirstChild(itemName) then --if item not already inputted from other location
			return parentDataFolder:FindFirstChild(itemTypeName)
		end
	else
		return createSaveReference(parentDataFolder, itemTypeName, "Folder")
	end
end

local function savePlayerData(playerUserId)
	if sessionData[playerUserId] then
		local success = pcall(function()
			--**Update this code using :UpdateAsync
			
			PlayerSave:SetAsync(playerUserId, sessionData[playerUserId]) --save sessionData as playerUserId
			print(playerUserId .. "'s Data Was SAVED!")
		end)
		
		if not success then
			warn("Cannot save data for " .. tostring(playerUserId))
		end
	end
end

---------------------<|High-Traffic Functions|>--------------------------------------------------------------------------------------------------------------------------------------

-- 
local function updateGUIForFile(saveFolder, player, statName, value, overFlow)
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId
	local playerDataFile = playerData:WaitForChild(tostring(playerUserId))
	local dataFolder = playerDataFile:FindFirstChild(saveFolder)
	
	for _,itemType in pairs (dataFolder:GetChildren()) do
		if itemType:FindFirstChild(statName) then --DataTab:FindFirstChild(file):FindFirstChild(statName)?
			local total = sessionData[playerUserId][statName]
			local amountAdded = value
			
			if saveFolder == "Inventory" then
				local itemTypeInfo = Utility:getItemInfo(statName, true)
				
				--Update Bag
				local typeAmount = PlayerStatManager:getItemCount(player)
				local maxItemAmount = PlayerStatManager:getEquippedData(player, itemTypeInfo:FindFirstChild(statName).Bag.Value .. "s", "Bags") --Bag capacity
				if maxItemAmount then
					if value ~= 0 and not overFlow then
						updateItemCount:FireClient(player, typeAmount+value, maxItemAmount, tostring(itemType))
						
					elseif overFlow then
						local expense = math.abs(value - overFlow)
						updateItemCount:FireClient(player, typeAmount-expense, maxItemAmount, tostring(itemType))
						
					else
						updateItemCount:FireClient(player, 0, maxItemAmount, tostring(itemType), true)
					end
				end
				
				updateInventory:FireClient(player, statName, tostring(itemType), tostring(total), "Inventory", amountAdded)
				
			elseif saveFolder == "Experience" then	
				
				local savedLevelValue = sessionData[playerUserId][statName .. "Level"]
				local expInfo = experienceData[tostring(itemType)][statName]
				local expLevel = GetPlayerLevel(player, expInfo)
				
				local levelUp
				if savedLevelValue ~= expLevel then --If, because of new exp, player is higher level than save, send signal to display levelUp
					sessionData[playerUserId][statName .. "Level"] = expLevel
					sessionData[playerUserId][statName .. "UnseenLevels"] += 1
					
					local expRefer = playerDataFile.Experience:FindFirstChild(tostring(itemType)):FindFirstChild(statName)
					expRefer.Value = expLevel
					expRefer:FindFirstChild(statName .. "UnseenLevels").Value += 1

					levelUp = expLevel
				end
				
				updateExperience:FireClient(player, statName, tostring(itemType), tostring(total), tostring(saveFolder), amountAdded, levelUp)
				
			elseif saveFolder == "TycoonStorage" then
				updateTycoonStorage:FireClient(player, statName, tostring(total), tostring(itemType))
				
			elseif saveFolder == "Currencies" then
				Utility:updateMoneyDisplay(player, Utility:convertShort(total))
				
				--**Will later recognize which type of currency is being updated
				--displayCurrencyPopUp:FireClient(player, "Coin", value)
			end
			
			--Finally, update DataStore value
			itemType:FindFirstChild(statName).Value = sessionData[playerUserId][statName]
		end
	end
end

--Change saved stat to new value
function PlayerStatManager:changeStat(player, statName, value, saveFolder, itemType, special, overFlow)
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId
	local playerDataFile = playerData:WaitForChild(tostring(playerUserId))
	
	--print(player, statName, value, saveFolder, itemType, special, overFlow)
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
					updateGUIForFile(saveFolder, player, statName, value, overFlow)
				end
			end		
		end
		
	elseif sessionData[playerUserId][statName] ~= value then
		
		sessionData[playerUserId][statName] = value 
		
		--Research saves exact value, not += value
		if saveFolder == "Research" then
			if itemType then
				if playerDataFile.Research:FindFirstChild(itemType) then
					local researchFolder = playerDataFile.Research:FindFirstChild(itemType)

					if researchFolder:FindFirstChild(statName) then
						researchFolder:FindFirstChild(statName).Value = sessionData[playerUserId][statName]
					end
				end
				
			elseif playerDataFile.Research:FindFirstChild(statName) then
				playerDataFile.Research:FindFirstChild(statName).Value = sessionData[playerUserId][statName]
			end
		end

		if typeof(sessionData[playerUserId][statName]) == "boolean" then
			if saveFolder then
				
				-- Player item purchase boolean
				if game.ReplicatedStorage.Equippable:FindFirstChild(saveFolder) then
					updatePlayerMenu:FireClient(player, saveFolder, itemType, statName, true)
					playerDataFile.Player:FindFirstChild(saveFolder):FindFirstChild(itemType):FindFirstChild(statName).Value = value
					
				-- Item discovery boolean
				elseif string.find(statName, "Discovered") then
					local itemType = Utility:getItemInfo(string.gsub(statName, "Discovered", ""), true)
					updateTycoonStorage:FireClient(player, statName, value, tostring(itemType))
					updateInventory:FireClient(player, statName, tostring(itemType), value, "Discovered", 1)
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
				
				updateItemCount:FireClient(player, itemCount, maxItemAmount, equippedItemType)
				
			elseif saveFolder == "Tools" then
				UpdateToolbar(player, tostring(equippedItemType), value)
				
			--elseif save Folder == "Pets" then
				
				
			--elseif saveFolder == "Mounts" then
				
			end
			
			updateEquippedItem:FireClient(player, saveFolder, equippedItemType, value)
		end
	end
end

------------------------------<|Set Up Player Data|>-----------------------------------------------------------------------------------------------------------------------

function findPlayerData(joinedPlayer)
	local playerDataFile = playerData:FindFirstChild(tostring(joinedPlayer.UserId))
	local playerUserId = joinedPlayer.UserId
	
	local success,data = pcall(function()
		return PlayerSave:GetAsync(playerUserId) --Get save data saved as playerUserId
	end)
	
	if success then
		wait(5) --Allow tycoon to be categorized (change for all internet speeds)
		if data then --load data
			print("DataStore was Accessed for " .. joinedPlayer.Name .. " (" .. tostring(joinedPlayer.UserId) .. ")")
			sessionData[playerUserId] = data
			
			local playerCash = LoadPlayerData(playerDataFile,data,joinedPlayer)
			setTycoonPurchases(joinedPlayer, playerCash, playerUserId)
		else --New player
			print(tostring(joinedPlayer) .. " is a new player!")
			sessionData[playerUserId] = {} --No data
			
			local playerCash = LoadPlayerData(playerDataFile,sessionData[playerUserId],joinedPlayer)
			setTycoonPurchases(joinedPlayer, playerCash, playerUserId)
		end	
		print("SET TYCOON PURCHASES HAS FINISHED")
	else
		warn("Couldn't Get or Set-Up Player Data For " .. tostring(joinedPlayer))
		findPlayerData(joinedPlayer)
	end		
end

function LoadPlayerData(playerDataFile, data, joinedPlayer)
	print("Loading " .. tostring(joinedPlayer) .. "'s data")
	
	local playerUserId = joinedPlayer.UserId
	local dataMenu = joinedPlayer.PlayerGui:WaitForChild("DataMenu"):WaitForChild("DataMenu")
	
	local PlayerInventory = createSaveReference(playerDataFile, "Inventory", "Folder")
	local TycoonStorage = createSaveReference(playerDataFile, "TycoonStorage", "Folder")	
	local playerResearch = createSaveReference(playerDataFile, "Research", "Folder")
	local playerExperience = createSaveReference(playerDataFile, "Experience", "Folder")
	local PlayerStatItems = createSaveReference(playerDataFile, "Player", "Folder")
	local EquippedItems = createSaveReference(PlayerStatItems, "CurrentlyEquipped", "Folder")
	
	local researchersPurchased = createSaveReference(playerResearch, "ResearchersPurchased", "NumberValue")
	local savedResearchersPurchased = checkSaveData(data["ResearchersPurchased"])
	importSaveData(data, savedResearchersPurchased, "ResearchersPurchased", researchersPurchased)
	data["ResearchersPurchased"] = 5 --for testing right now
	--UpdateResearch:FireClient(joinedPlayer, nil, nil, nil, nil, 5)
	
	local researchersUsed = createSaveReference(playerResearch, "ResearchersUsed", "NumberValue")
	local savedResearchersUsed = checkSaveData(data["ResearchersUsed"])
	importSaveData(data, savedResearchersUsed, "ResearchersUsed", researchersUsed)
	
	for _,expType in pairs (experienceData) do
		if expType["StatTypeName"] then
			local expTypeName = expType["StatTypeName"]
			local expSaveFolder = createSaveReference(playerExperience, expTypeName, "Folder")

			for _,expInfo in pairs (expType) do
				if expInfo["StatName"] then
					
					local expName = expInfo["StatName"]
					local expRefer = createSaveReference(expSaveFolder, expName, "NumberValue")
					local expSave = checkSaveData(data[expName])
					importSaveData(data, expSave, expName, expRefer)
					
					local unseenLevelsSaveName = expName .. "UnseenLevels"
					local unseenLevelsRefer = createSaveReference(expRefer, unseenLevelsSaveName, "NumberValue")
					local unseenLevelsSave = checkSaveData(data[unseenLevelsSaveName])
					importSaveData(data, unseenLevelsSave, unseenLevelsSaveName, unseenLevelsRefer)
					
					--Calculated reference, don't check data
					local expLevel = createSaveReference(expRefer, expName .. "Level", "NumberValue")
					expLevel.Value = GetPlayerLevel(joinedPlayer, expInfo) --Match data with exp amount
					data[expName .. "Level"] = expLevel.Value

					--Create exp tiles with value > 0
					updateExperience:FireClient(joinedPlayer, expName, expTypeName, tostring(data[expName]), "Experience")
				end
			end
		end
	end
	
	local usedResearcherCount = 0
	local researchTable = researchData["Research"]
	for _,researchType in pairs (researchTable) do
		local researchTypeName = researchType["Research Type Name"]
		local researchTypeFolder = createSaveReference(playerResearch, researchTypeName, "Folder")
		
		for r = 1,#researchType,1 do
			if researchType[r] then
				local researchInfo = researchType[r]
				
				local researchName = researchInfo["Research Name"]
				local researchRefer = createSaveReference(researchTypeFolder, researchName, "BoolValue") --true if completed
				local researchSave = checkSaveData(data[researchName])
				importSaveData(data, researchSave, researchName, researchRefer)
				
				local purchasedSaveName = researchName .. "Purchased"
				local purchasedRefer = createSaveReference(researchRefer, purchasedSaveName, "BoolValue")
				local purchasedSave = checkSaveData(data[purchasedSaveName])
				importSaveData(data, purchasedSave, purchasedSaveName, purchasedRefer)
				
				local finishedSaveName = researchName .. "FinishTime"
				local finishTimeRefer = createSaveReference(researchRefer, finishedSaveName, "NumberValue")
				local finishTimeSave = checkSaveData(data[finishedSaveName])
				importSaveData(data, finishTimeSave, finishedSaveName, finishTimeRefer)
				
				local skillMetSaveName = researchName .. "SkillMet"
				if #researchInfo["Experience Cost"] > 0 then
					local skillMetBool = createSaveReference(researchRefer, skillMetSaveName, "BoolValue")
					
					for e = 1,#researchInfo["Experience Cost"] do --Ensure SkillMet matches expData
						local expTable = researchInfo["Experience Cost"][e]
						local expInfo = expTable[1]
						local expRequirement = expTable[2]
						
						local playerLevel = GetPlayerLevel(joinedPlayer, expInfo)
						if playerLevel >= expRequirement then --see if player already meets skill require
							skillMetBool.Value = true
							data[skillMetSaveName] = true
						else
							importSaveData(data, false, skillMetSaveName, skillMetBool)
						end
					end
				end
				
				local clonedResearchInfo = Utility:cloneTable(researchInfo)
				local completionValue = data[researchName]
				local purchasedValue = data[purchasedSaveName]
				local finishTimeValue = data[finishedSaveName]
				local skillMetValue = data[skillMetSaveName]
				
				updateResearch:FireClient(joinedPlayer, clonedResearchInfo, researchTypeName, completionValue, purchasedValue, finishTimeValue, skillMetValue, nil, true)
				
				if purchasedValue and not completionValue then
					usedResearcherCount += 1
				end
			end
		end
	end
	PlayerStatManager:changeStat(joinedPlayer, "ResearchersUsed", usedResearcherCount, "Research")

	--All Inventory Item Data
	for _,itemType in pairs (game.ReplicatedStorage.InventoryItems:GetChildren()) do
		for _,item in pairs (itemType:GetChildren()) do
			local inventoryItemTypeFolder = findAssociatedFolder(PlayerInventory, tostring(itemType), tostring(item))
			local storageItemTypeFolder = findAssociatedFolder(TycoonStorage, "TycoonStorage" .. tostring(itemType), "TycoonStorage" .. tostring(item))
			
			local itemRefer = createSaveReference(inventoryItemTypeFolder, tostring(item), "NumberValue")
			local itemSave = checkSaveData(data[tostring(item)])
			importSaveData(data, itemSave, tostring(item), itemRefer)
			updateInventory:FireClient(joinedPlayer, tostring(item), tostring(itemType), tostring(data[tostring(item)]), "Inventory")
			
			local discoveredSaveName = tostring(item) .. "Discovered"
			local discoveredRefer = createSaveReference(itemRefer, discoveredSaveName, "BoolValue")
			local discoveredSave = checkSaveData(data[discoveredSaveName])
			importSaveData(data, discoveredSave, discoveredSaveName, discoveredRefer)
			updateTycoonStorage:FireClient(joinedPlayer, discoveredSaveName, data[discoveredSaveName], tostring(itemType))
			
			local storageSaveName = "TycoonStorage" .. tostring(item)
			local itemStorageRefer = createSaveReference(storageItemTypeFolder, storageSaveName, "NumberValue")
			local itemStorageSave = checkSaveData(data[storageSaveName])
			importSaveData(data, itemStorageSave, storageSaveName, itemStorageRefer)
			updateTycoonStorage:FireClient(joinedPlayer, storageSaveName, tostring(data[storageSaveName]), tostring(itemType))   
		end	
	end
	
	--Equippable Data
	for _,equiptype in pairs (game.ReplicatedStorage.Equippable:GetChildren()) do
		local equippedItemsFolder = createSaveReference(EquippedItems, "Equipped" .. tostring(equiptype), "Folder")
		local equipTypeFolder = createSaveReference(PlayerStatItems, tostring(equiptype), "Folder")
		
		for _,itemType in pairs (equiptype:GetChildren()) do
			
			local itemTypeFolder = createSaveReference(equipTypeFolder, tostring(itemType), "Folder")
			for _,item in pairs (itemType:GetChildren()) do
				local itemRefer = createSaveReference(itemTypeFolder, tostring(item), "BoolValue")
				local itemSave = checkSaveData(data[tostring(item)])		
				importSaveData(data, itemSave, tostring(item), itemRefer)
				
				if itemSave == true then --if previously purchased, add to inventory
					updatePlayerMenu:FireClient(joinedPlayer, tostring(equiptype), tostring(itemType), tostring(item), true)
				end
			end
			
			local equippedItemSaveName = "Equipped" .. tostring(itemType)
			local equippedItemRefer = createSaveReference(equippedItemsFolder, equippedItemSaveName, "StringValue")
			local equippedItemSave = checkSaveData(data[equippedItemSaveName])
			importSaveData(data, equippedItemSave, equippedItemSaveName, equippedItemRefer)
			
			local equippedItem = itemType:FindFirstChild(data[equippedItemSaveName])
			if equippedItem then
				if tostring(equiptype) == "Bags" then --Update GUI Menus (Inventory Bag # Limits)
					local menuName = "MaterialsMenu"
					local bagStats = equipmentData["Bags"][tostring(itemType)][tostring(equippedItem)]
					dataMenu:WaitForChild("InventoryMenu"):FindFirstChild(menuName):SetAttribute("BagCapacity", bagStats["Stats"]["Bag Capacity"])

					local itemCount = PlayerStatManager:getItemCount(joinedPlayer)
					dataMenu:WaitForChild("InventoryMenu"):FindFirstChild(menuName):SetAttribute("ItemCount", itemCount)
				end
				
				if tostring(equiptype) == "Tools" then
					UpdateToolbar(joinedPlayer, tostring(itemType), tostring(equippedItem))
				end

				updateEquippedItem:FireClient(joinedPlayer, tostring(equiptype), tostring(itemType), tostring(equippedItem))
			else
				updateEquippedItem:FireClient(joinedPlayer, tostring(equiptype), tostring(itemType), "")
			end
		end
	end
	
	local currencyFolder = createSaveReference(playerDataFile, "Currencies", "Folder")
	local universalCurrencyFolder = createSaveReference(currencyFolder, "UniversalCurrencies", "Folder")
	local coinsRefer = createSaveReference(universalCurrencyFolder, "Coins", "NumberValue")

	local playerCoins = universalCurrencyFolder.Coins.Value
	local coinsSave = checkSaveData(data["Coins"])
	if coinsSave == false then
		playerCoins = 0
		data["Coins"] = 0
	else
		playerCoins = data["Coins"]
	end
	
	print(tostring(joinedPlayer) .. " Has " .. tostring(data["Coins"]) .. " Coins")
	return playerCoins
end

function setTycoonPurchases(joinedPlayer, PlayerCash, playerUserId)
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

		Utility:updateMoneyDisplay(joinedPlayer, Utility:convertShort(PlayerCash))
	end
end

----------------------------------------<|Get Item Info Functions|>------------------------------------------------------------------------------------------------------

function PlayerStatManager:getPlayerData(player)
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId
	return sessionData[playerUserId]
end 

function PlayerStatManager:getStat(player, statName, boolCheck) --Check Stat Value
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId

	if sessionData[playerUserId] then
		if boolCheck then --Does not allow viewing stats that are not booleans
			if typeof(sessionData[playerUserId][statName]) == "boolean" then
				return (sessionData[playerUserId][statName])
			else
				warn(player, "could be exploiting")
			end
		else
			return sessionData[playerUserId][statName]
		end
		
	else
		warn(player," does not have save data! Trying again...") --possibly kick player from game and tell to try again
		wait(2)
		PlayerStatManager:getStat(player, statName)
	end
end 

function PlayerStatManager:getItemCount(player) --For Amount in Bag Checking
	local playerUserId = player.UserId
	local playerDataFile = playerData:FindFirstChild(tostring(playerUserId))
	
	local inventoryAmount = 0
	for _,itemTypeFolder in pairs (playerDataFile.Inventory:GetChildren()) do --if item type checks come back, it can be checked here
		for _,statData in pairs (itemTypeFolder:GetChildren()) do
			inventoryAmount += statData.Value
		end
	end
	
	return inventoryAmount
end

function PlayerStatManager:getEquippedData(player, itemType, equipType)
	local playerDataFile = playerData:FindFirstChild(tostring(player.UserId))
	
	if playerDataFile.Player.CurrentlyEquipped:FindFirstChild("Equipped" .. equipType):FindFirstChild("Equipped" .. itemType) then
		local equippedItem = playerDataFile.Player.CurrentlyEquipped:FindFirstChild("Equipped" .. equipType):FindFirstChild("Equipped" .. itemType)
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

function PlayerStatManager:initiateSaving(player, statName, PlayerMoney) --Start saving process by updating money dataStore
	local playerUserId = game.Players:FindFirstChild(tostring(player)).UserId
	sessionData[playerUserId][statName] = PlayerMoney
	--Likely update gem amount here as well

	savePlayerData(playerUserId)
end

--------------------------------<|Equip Functions|>----------------------------------------------------------------------------------------------

function UpdateToolbar(Player, ItemType, NewlyEquippedItem)
	local ItemTypeFolder = game.ReplicatedStorage.Equippable.Tools:FindFirstChild(ItemType)
	
	--Delete existing items of type from backpack
	for _,item in pairs (Player.Backpack:GetChildren()) do
		if ItemTypeFolder:FindFirstChild(tostring(item)) then
			item:Destroy()
		end
	end
	--check if holding item of same type
	for _,item in pairs (workspace.Players:FindFirstChild(tostring(Player)):GetChildren()) do
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

function getItemStatTable.OnServerInvoke(player, dataType, equipType, itemType, itemName)
	local dataModule = require(game.ServerStorage:FindFirstChild(dataType .. "Data"))
	
	local itemInfo
	if dataType == "Equipment" then
		itemInfo = dataModule[equipType][itemType][itemName]
		
	elseif dataType == "Research" then
		local researchTypeInfo = dataModule["Research"][itemType]
		
		for r = 1,#researchTypeInfo,1 do
			local researchInfo = researchTypeInfo[r]
			
			if researchInfo["Research Name"] == itemName then
				itemInfo = researchInfo
			end
		end
		
	else
		itemInfo = dataModule[itemType][itemName]
	end
	
	if itemInfo then
		local cloneInfo = Utility:cloneTable(itemInfo)
		return cloneInfo
	else
		warn(player, " is possibly exploiting: Trying to grab nil DataStatTables")
	end
end

getBagCount.OnInvoke = function(Player, itemInfo)
	if itemInfo then
		if itemInfo:FindFirstChild("AssociatedSkill") then
			local itemType = string.gsub(itemInfo.AssociatedSkill.Value, " Skill", "")
			local amount = PlayerStatManager:getItemCount(Player)
			local maxAmount = PlayerStatManager:getEquippedData(Player, itemInfo.Bag.Value .. "s", "Bags")

			if amount and maxAmount then
				return amount,maxAmount,itemType .. "s"
			else
				return amount,nil,itemType .. "s"
			end
		end
	end
end

function getItemCountSum.OnServerInvoke(player, statName)
	print("Checking item count sum for " .. statName)
	local playerUserId = player.UserId
	local inventoryAmount = sessionData[playerUserId][statName]
	local storageAmount = sessionData[playerUserId]["TycoonStorage" .. statName]

	if inventoryAmount and storageAmount then
		return inventoryAmount + storageAmount
	else
		warn("InventoryAmount or StorageAmount does not exist for ", player, statName)
	end
end

function GetPlayerLevel(player, expInfo, onlyExpAmount, onlyRewardCount) --Use total exp to find level, not level saved value
	local playerUserId = player.UserId
	local expName = expInfo["StatName"]
	
	if sessionData[playerUserId][expName] then
		if onlyRewardCount then
			local unseenLevels = sessionData[playerUserId][expName .. "UnseenLevels"]
			return unseenLevels
		else
			local expAmount = sessionData[playerUserId][expName]

			if onlyExpAmount then
				return expAmount
			else
				local highestLevel
				for lvl = 1,#expInfo["Levels"] do
					if expInfo["Levels"][lvl]["Exp Requirement"] <= expAmount then
						if highestLevel then
							if lvl > highestLevel then
								highestLevel = lvl
							end
						else
							highestLevel = lvl
						end
					end
				end
				
				return highestLevel
			end
		end
	end
end

function getCurrentPlayerLevel.OnServerInvoke(player, expInfo, onlyExpAmount, onlyRewardCount)
	return GetPlayerLevel(player, expInfo, onlyExpAmount, onlyRewardCount) --Both PSM and client need to access this function
end

-- @PARAMS
-- player = 
-- expName = 
-- expTypeName = 
function awardLevelRewards.OnServerInvoke(player, expName, expTypeName)
	local playerUserId = player.UserId
	local playerDataFile = playerData:FindFirstChild(tostring(playerUserId))
	
	if experienceData[expTypeName] then
		if experienceData[expTypeName][expName] then
			local expInfo = experienceData[expTypeName][expName]
			local unseenLevelsCount = sessionData[playerUserId][expName .. "UnseenLevels"]
			
			if unseenLevelsCount > 0 then -- Ensure player actually needs to level up
				local currentLevel = sessionData[playerUserId][expName .. "Level"]
				local rewardLevel = currentLevel - unseenLevelsCount + 1
				local levelInfo = expInfo["Levels"][rewardLevel]
				
				-- Give player level rewards
				if sessionData[playerUserId][expName] >= levelInfo["Exp Requirement"] then
					for r = 1,#levelInfo["Rewards"] do
						local rewardInfo = levelInfo["Rewards"][r]
						local rewardType = rewardInfo[1]
						local statInfo = rewardInfo[2]
						
						if rewardType == "Item" then
							local amount = rewardInfo[3]
							PlayerStatManager:changeStat(player, tostring(statInfo), amount, "Inventory")
							
							-- Declare "new item discovered!" if not already
							local discoveredValue = sessionData[playerUserId][tostring(statInfo) .. "Discovered"]
							if discoveredValue == false then
								PlayerStatManager:changeStat(player, tostring(statInfo) .. "Discovered", true, "Inventory")
							end
							
						elseif rewardType == "Equipment" then
							PlayerStatManager:changeStat(player, tostring(statInfo), true, "Equipment")
							
						else -- Research List Reward
							for r = 1,#rewardInfo do
								local researchName = rewardInfo[r]["Research Name"]
								local researchType = rewardInfo[r]["Resarch Type"]
								
								local researchTypeInfo = researchData["Research"][string.gsub(researchType, " Research") .. " Improvements"]
								for rd = 1,researchTypeInfo do
									if researchTypeInfo[rd]["Research Name"] == researchName then
										local researchInfo = Utility:cloneTable(researchTypeInfo[rd])
										
										local completed = sessionData[playerUserId][researchName]
										local purchased = sessionData[playerUserId][researchName .. "Purchased"]
										local finishTime = sessionData[playerUserId][researchName .. "FinishTime"]
										local skillMet = sessionData[playerUserId][researchName .. "SkillMet"]
										
										updateResearch:FireClient(researchInfo, researchType, completed, purchased, finishTime, skillMet, nil, true)
									end
								end
							end
						end
					end
					
					sessionData[playerUserId][expName .. "UnseenLevels"] -= 1
					if playerDataFile.Experience:FindFirstChild(expTypeName) then
						local expFolder = playerDataFile.Experience:FindFirstChild(expTypeName):FindFirstChild(expName)
						if expFolder then
							if expFolder:FindFirstChild(expName .. "UnseenLevels") then
								expFolder:FindFirstChild(expName .. "UnseenLevels").Value -= 1
							end
						end
					end
					
					if sessionData[playerUserId][expName .. "UnseenLevels"] > 0 then
						return true
					else
						return false
					end
				end
			end
		end
	end
	
	return false
end

sellItem.OnServerEvent:Connect(function(Player, Menu, item, Percentage)--, Amount)
	if Percentage >= 0 and Percentage <= 1 then
		local playerUserId = game.Players:FindFirstChild(tostring(Player)).UserId

		local itemInfo = Utility:getItemInfo(item)

		if itemInfo then
			local ItemWorth = tonumber(itemInfo.CurrencyValue.Value)
			local Amount = math.ceil(Percentage * sessionData[playerUserId]["TycoonStorage" .. tostring(itemInfo)])
			local SellAmount = Amount*ItemWorth

			print("Selling " .. tostring(Amount) .. " " .. tostring(itemInfo) .. "'s for $" .. tostring(SellAmount))

			PlayerStatManager:changeStat(Player, "Coins", SellAmount, "Currencies", true) --Update Currency
			PlayerStatManager:changeStat(Player, "TycoonStorage" .. tostring(itemInfo), -Amount, "TycoonStorage")
			
			sellItem:FireClient(Player) --RightSide Notify
		else
			--exploiter
			warn("Item could not be found to sell!")
		end
	end
end)

depositInventory.OnServerEvent:Connect(function(Player)
	local playerDataFile = playerData:FindFirstChild(tostring(Player.UserId))
	
	if playerDataFile:FindFirstChild("Inventory") then
		for i,folder in pairs (playerDataFile.Inventory:GetChildren()) do
			for i,item in pairs (folder:GetChildren()) do
				local InventoryValue = item.Value --the value of the item is one more than the actual value
				if InventoryValue > 0 then
					--Update Inventory
					PlayerStatManager:changeStat(Player, tostring(item), 0, "Inventory", nil, "Zero")
					item.Value = 0

					--Update Storage
					PlayerStatManager:changeStat(Player, "TycoonStorage" .. tostring(item), InventoryValue, "TycoonStorage")

					--Call Inventory to Wipe Previous Pages and Tiles
					depositInventory:FireClient(Player)
				end
			end
		end

		return true
	end
end)

local function CheckResearchDepends(player, researchInfo, specificDepend)
	--Possibly check if player hasn't already finished this research. Otherwise, they could be exploiting
	
	if typeof(researchInfo) == "string" then --find researchInfo (including type) and if depends met
		local researchFound = false
		
		for _,researchType in pairs (researchData["Research"]) do
			for r = 1,#researchType do
				if researchFound == false and researchType[r] then
					if researchType[r]["Research Name"] == researchInfo then
						researchFound = true
						researchInfo = researchType[r]
						
						local dependsMet = false
						if PlayerStatManager:getStat(player, researchInfo["Research Name"], true) then
							dependsMet = true
						else --Depend not already completed, see if all depends met for 
							dependsMet = CheckResearchDepends(player, researchInfo)
						end

						return Utility:cloneTable(researchInfo),dependsMet
					end
				end
			end
		end
		
	elseif researchInfo["Research Name"] then
		if not PlayerStatManager:getStat(player, researchInfo["Research Name"], true) then
			
			--Count all dependencies since not specific
			if researchInfo["Dependencies"] and specificDepend == nil then
				local dependencies = researchInfo["Dependencies"]
				
				local dependenciesMet = 0
				for _,dependency in pairs(dependencies) do
					local researchCompleted = PlayerStatManager:getStat(player, dependency, true)
					if researchCompleted then
						dependenciesMet += 1
					end
				end
				
				if dependenciesMet == #dependencies then
					return true
				else
					return false
				end
				
			elseif researchInfo["Dependencies"] and specificDepend then
				if typeof(specificDepend) == "string" then
					local researchCompleted = PlayerStatManager:getStat(player, specificDepend, true)
					return researchCompleted
				end
			else
				warn(player, "is exploiting")
			end
		else
			warn(player, "is exploiting")
		end
	end
end

checkResearchDepends.OnServerInvoke = CheckResearchDepends --call function on event invoke

function checkPlayerStat.OnServerInvoke(player, statName)
	return PlayerStatManager:getStat(player, statName, true)
end

--Fires when player equips new item (must be saved for when they join back)
updateEquippedItem.OnServerEvent:Connect(function(Player, EquipType, ItemType, NewlyEquippedItem)
	local playerUserId = Player.UserId
	local playerDataFile = playerData:FindFirstChild(tostring(playerUserId))
	local EquipValue = playerDataFile.Player.CurrentlyEquipped:FindFirstChild("Equipped" .. EquipType):FindFirstChild("Equipped" .. ItemType)

	--Check if value selected is not already equipped
	if NewlyEquippedItem then
		if NewlyEquippedItem ~= sessionData[playerUserId]["Equipped" .. ItemType] then --If not already equipped
			if sessionData[playerUserId][NewlyEquippedItem] == true then --Item is purchased
				if EquipType == "Tools" then --must update player hotbar
					UpdateToolbar(Player, ItemType, NewlyEquippedItem)
				end
					
				EquipValue.Value = NewlyEquippedItem
				PlayerStatManager:changeStat(Player, "Equipped" .. ItemType, NewlyEquippedItem, EquipType)	
			end
		end
	else --Unequipped Item, set value for equipped item to nil
		if EquipType == "Tools" then
			UpdateToolbar(Player, ItemType)
		end
		
		EquipValue.Value = ""
		PlayerStatManager:changeStat(Player, "Equipped" .. ItemType, "", EquipType)	
	end
end)

local function HandleDropMaterials(Tycoon, Drop) --Update Tycoon Storage for drop's worth
	--**This will have to be updated for security since it's a bindable event that an exploiter could fire
	--If they change the values, they could give themselves a lot of money with this current code using
	--their tycoon and a fake drop with a cashValue that's high
	
	--(Will probably need to reference the replicated storage drop, looking at the name the player sent,
	--then see if that drop's dropper has been purchased by the player)
	
	--How will this script securely know what player it is though? Because the exploiter could set the Tycoon
	--parameter to another tycoon that is much farther than them with the dropper unlocked
	
	local Player = Tycoon.Owner.Value
	local playerUserId = game.Players:FindFirstChild(tostring(Player)).UserId
	local playerDataFile = playerData:FindFirstChild(playerUserId)
	local OwnedTycoon = playerDataFile.OwnsTycoon.Value
	
	--Match player with saved Tycoon value in player data storage (prevent exploiters)
	if tostring(Tycoon) == tostring(OwnedTycoon) then
		if Drop:FindFirstChild("Materials") then	
			for _,file in pairs (Drop.Materials:GetChildren()) do
				for _,material in pairs (file:GetChildren()) do
					PlayerStatManager:changeStat(Player, "TycoonStorage" .. tostring(material), material.Value, "TycoonStorage", tostring(file))
					
					local itemInfo = Utility:getItemInfo(tostring(material), true)
					
					local discoverValue = sessionData[playerUserId][tostring(material) .. "Discovered"]
					if discoverValue == false then
						PlayerStatManager:changeStat(Player, tostring(material) .. "Discovered", true, tostring(file))
					end
				end
			end
		end
	end
end
handleDropMaterialsEvent.Event:Connect(HandleDropMaterials)


return PlayerStatManager

