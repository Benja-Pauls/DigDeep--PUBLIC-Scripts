local player = game.Players.LocalPlayer
local replicatedStorage = game.ReplicatedStorage
local currentCamera = game.Workspace.CurrentCamera
local tweenService = game:GetService("TweenService")

local guiElements = replicatedStorage.GuiElements
local guiUtility = require(replicatedStorage.GuiUtility)
local eventsFolder = replicatedStorage.Events

local depositInteract = eventsFolder.HotKeyInteract:WaitForChild("DepositInteract")

local sellItem = eventsFolder.Utility:WaitForChild("SellItem")

local insertItemViewerInfo = eventsFolder.GUI:WaitForChild("InsertItemViewerInfo")
local updateInventory = eventsFolder.GUI:WaitForChild("UpdateInventory")
local updateItemCount = eventsFolder.GUI:WaitForChild("UpdateItemCount")

local itemPopUpGui = script.Parent.ItemPopUp
local expBarPopUpGui = script.Parent.EXPBarPopUp
local mouseoverPopUpGui = script.Parent.MouseoverPopUp

local dataMenu = script.Parent.Parent.DataMenu.DataMenu
local playerModel = game.Workspace.Players:WaitForChild(tostring(player))

local currentPopUpTweens = {}

local function GetPopUpCount(popUpGui)
	local popUpCount = 0
	for _,popUp in pairs (itemPopUpGui:GetChildren()) do --Some PopUps will be labelled "expired"
		if string.match(popUp.Name, "PopUp") then
			popUpCount += 1
		end
	end
	return popUpCount
end


----------------------------<|Countdown Functions|>--------------------------------------------------------------------------------------------------------------------------
local coinDisplay = script.Parent.Parent.MoneyDisplay["Coin Display"]
local jumpDistance = coinDisplay.Size.Y.Scale/5.25
local movePopUpTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local xPos = 0.99

local function CountdownPopUp(popUp, expireTime, dontDestroy) --xJump, yJump, xJump2, yJump2
	local timer = popUp.TimeLeft
	timer.Value = 0
	
	coroutine.resume(coroutine.create(function()
		for sec = 1,expireTime do
			wait(1)
			
			if sec == timer.Value + 1 then
				timer.Value = sec
				if sec == expireTime then
					if string.match(popUp.Name, "PopUp") then
						popUp.Name = "Expired"
						
						if currentPopUpTweens[popUp] then
							currentPopUpTweens[popUp]:Pause()
							currentPopUpTweens[popUp]:Destroy()
						end
						
						--[[ --Move popups below back up (MAY COMPLICATE THINGS WITH NO BENEFIT, TILES ALREADY MOVE IF PUSHED DOWN)
						for _,belowPopUp in pairs (itemPopUpGui:GetChildren()) do
							if belowPopUp:IsA("TextButton") and string.match(belowPopUp.Name, "PopUp") then
								local p = string.gsub(belowPopUp.Name, "PopUp", "")
								p = tonumber(p)
								
								if p > popUpNumber then
									popUp.Name = "PopUp" .. tostring(p - 1)
									local tween = currentPopUpTweens[belowPopUp]

									if currentPopUpTweens[belowPopUp] then
										tween.Completed:Wait() --Moveup does not take priority over move down\
									end

									if currentPopUpTweens[belowPopUp] == tween then --Check waited for tween is still last tween
										local yPos = belowPopUp.Position.Y.Scale - popUp.Size.Y.Scale - jumpDistance
										local moveUpTween = tweenService:Create(belowPopUp, movePopUpTweenInfo, {Position = UDim2.new(xPos, 0, yPos, 0)})
										moveUpTween:Play()
										currentPopUpTweens[belowPopUp] = moveUpTween
									end
								end
							end
						end
						]]
						
						local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
						local currentXSize = popUp.Size.X.Scale
						local currentYPos = popUp.Position.Y.Scale
						local hideTween = tweenService:Create(popUp, tweenInfo, {Position = UDim2.new(1 + currentXSize, 0, currentYPos, 0)})
						hideTween:Play()
						
						wait(0.3)
					end
					
					if dontDestroy then
						popUp.Visible = dontDestroy
					else
						popUp:Destroy()
					end
				end
			end
		end
	end))
end

local differenceEXPAdded = 0
local lastProgressAmount = 0
local function CountdownEXPDifference(difference, progressBar, levelProgress, amountAdded, levelFinished)
	print(difference, progressBar, levelProgress, amountAdded, levelFinished)
	local expBar = difference.Parent.Parent

	if expBar:FindFirstChild("TimeLeft") and amountAdded >= 1 then
		differenceEXPAdded = differenceEXPAdded + amountAdded

		if levelProgress < lastProgressAmount or levelProgress >= 1 or levelFinished then
			lastProgressAmount = levelProgress
			NewDiffPopUp(expBar, differenceEXPAdded, 1)
			differenceEXPAdded = 0

			progressBar:TweenSize(UDim2.new(levelProgress, 0, 0, 30), "Out", "Quint", .5)
			difference:TweenSize(UDim2.new(levelProgress, 0, 0, 30), "Out", "Quint", .5)
			local PreviousLevel = tonumber(expBar.CurrentLevel.Text)
			expBar.CurrentLevel.Text = PreviousLevel + 1
			expBar.NextLevel.Text = PreviousLevel + 2

		else --Countdown to when difference bar is filled
			lastProgressAmount = levelProgress

			local timer = difference.TimeLeft
			timer.Value = 0

			coroutine.resume(coroutine.create(function()
				for sec = 1,5,1 do
					wait(1)

					if timer then
						if sec == timer.Value + 1 then
							timer.Value = sec
							if sec == 5 then
								NewDiffPopUp(expBar, differenceEXPAdded, 3)
								differenceEXPAdded = 0

								progressBar:TweenSize(UDim2.new(0, difference.Size.X.Offset, difference.Size.Y.Scale, 30), "Out", "Quint", .5)
								wait(.6)
								difference:Destroy()
							end
						end
					end
				end
			end))
		end
	end
end

----------------------------<|Mouseover Info Functions|>---------------------------------------------------------------------------------------------------------
local mouse = player:GetMouse()
local mouseoverDisplay = script.Parent.MouseoverPopUp.MouseoverDisplay

local mouseDisplayUsed = false
--local guisAtPosition = player.PlayerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)

local function SetupMouseoverInfo(gui)
	gui.MouseEnter:Connect(function()
		mouseDisplayUsed = true
		mouseoverDisplay.Visible = false

		local charCount = string.len(" " .. gui.MouseoverInfo.Value)
		mouseoverDisplay.Size = UDim2.new(0.007 * charCount, 0, mouseoverDisplay.Size.Y.Scale, 0)
		mouseoverDisplay.Position = UDim2.new(0.017, mouse.X, 0, mouse.Y)
		mouseoverDisplay.TextLabel.Text = "<b>" .. gui.MouseoverInfo.Value .. "</b>"
		mouseoverDisplay.TextLabel.UIPadding.PaddingLeft = UDim.new(0.05 * (1-0.007*charCount))

		CountdownPopUp(mouseoverDisplay, 1, true)
	end)

	gui.MouseLeave:Connect(function()
		mouseDisplayUsed = false
		mouseoverDisplay.Visible = false
		mouseoverDisplay.TimeLeft.Value = -1
	end)
end

for _,gui in pairs (player.PlayerGui:GetDescendants()) do
	if gui:FindFirstChild("MouseoverInfo") then
		SetupMouseoverInfo(gui)
	end
end

mouse.Move:Connect(function()
	if mouseDisplayUsed == true then
		mouseoverDisplay.Position = UDim2.new(0.017, mouse.X, 0, mouse.Y)
	end
end)









----------------------------<|EXPBar PopUp Functions|>------------------------------------------------------------------------------------------------------------

--[[
function NewDiffPopUp(expBar, difference, pace)
	local realDiffPopUp = guiElements:FindFirstChild("EXPPopUp")
	local newDiffPopUp = realDiffPopUp:Clone()

	newDiffPopUp.Parent = expBar
	newDiffPopUp.Text = "+" .. tostring(difference) .. "XP"
	newDiffPopUp.Position = UDim2.new(math.random(-17.72,-15.48), 0, math.random(-1.71,-.777), 0)
	newDiffPopUp:TweenSize(UDim2.new(0, 100, 0, 25), "Out", "Quart", .5) --Grow
	wait(pace)

	newDiffPopUp:TweenSizeAndPosition(UDim2.new(0, 0, 0, 0), UDim2.new(-7.64, 0, 0.123, 0), "In", "Quint", 1) --Move to bar
	wait(1.1)
	newDiffPopUp:Destroy()
end

local function ShowEXPChange(currentLevel, nextLevel, skillInfo, expAmount, amountAdded)
	local experienceBar = expPopUpGui.ExperienceBar
	experienceBar.CurrentLevel.Text = tostring(currentLevel)
	experienceBar.NextLevel.Text = tostring(nextLevel)

	local currentLevelInfo = skillInfo["Levels"][currentLevel]
	local nextLevelInfo = skillInfo["Levels"][nextLevel]
	local progressBar = experienceBar.ProgressBar

	local levelProgress = tonumber(expAmount - currentLevelInfo["Exp Requirement"]) / tonumber(nextLevelInfo["Exp Requirement"] - currentLevelInfo["Exp Requirement"])
	if progressBar:FindFirstChild("EXPDifference") then --Difference Bar Check
		local difference = progressBar.EXPDifference

		if levelProgress < lastProgressAmount then
			difference:TweenSize(UDim2.new(0, 276, 0, 30), "Out", "Quint", .2)
			wait(.2)
			progressBar.Progress:TweenSize(UDim2.new(0, 276, 0, 30), "Out", "Quint", .2)
			wait(.2)
			CountdownEXPDifference(difference, progressBar.Progress, levelProgress, amountAdded, true)

			print("Level up") --** NEXT ON THE PROGRAMMING AGENDA
		else
			difference:TweenSize(UDim2.new(0, 276*levelProgress, 0, 30), "Out", "Quint", .2)
			CountdownEXPDifference(difference, progressBar.Progress, levelProgress, amountAdded)
		end

	else
		local difference = progressBar.Progress:Clone()
		difference.ZIndex = 3 --Put behind progress frame
		difference.Parent = progressBar
		difference.Name = "EXPDifference"
		difference.BackgroundColor3 = Color3.new(85, 255, 255)

		local timeLeftValue = Instance.new("IntValue", difference)
		timeLeftValue.Name = "TimeLeft"	

		difference:TweenSize(UDim2.new(0, 276*levelProgress, 0, 30), "Out", "Quint", .2)

		CountdownEXPDifference(difference, progressBar.Progress, levelProgress, levelProgress, amountAdded)
	end
end

local function InsertNewEXPBar(skillInfo, statName, expAmount, currentLevel, nextLevel, popUpAlreadyExists)

	if popUpAlreadyExists then
		local oldExpPopUp = expPopUpGui.ExperienceBar
		local namePlate = oldExpPopUp.NamePlate
		namePlate:TweenPosition(UDim2.new(-12,0,0,0), "Out", "Quint", .15)
		wait(.15)
		oldExpPopUp:TweenPosition(UDim2.new(0.98, 0, 1.055, 0), "Out", "Quint", .2)
		wait(.2)
		oldExpPopUp:Destroy()
	end

	local newExpBar = expBarGui:Clone()
	newExpBar.Parent = expPopUpGui
	newExpBar.Position = UDim2.new(0.98, 0, 1.055, 0)
	newExpBar.CurrentLevel.Text = tostring(currentLevel)
	newExpBar.NextLevel.Text = tostring(nextLevel)

	newExpBar:TweenPosition(UDim2.new(.98, 0, newExpBar.Position.Y.Scale - .1, 0), "Out", "Quint", .5)

	local progressBar = expPopUpGui.ExperienceBar.ProgressBar

	local currentLevelInfo = skillInfo["Levels"][currentLevel]
	local nextLevelInfo = skillInfo["Levels"][nextLevel]
	local levelProgress = tonumber(expAmount - currentLevelInfo["Exp Requirement"]) / tonumber(nextLevelInfo["Exp Requirement"] - currentLevelInfo["Exp Requirement"])

	progressBar.Progress.Size = UDim2.new(0, 276*levelProgress, 0, 30)
	CountdownPopUp(expPopUpGui, newExpBar, 12, .45, 0, 0, .9) --Start Countdown

	local namePlate = newExpBar.NamePlate
	namePlate.DisplayName.Text = tostring(statName)

	wait(.5)
	namePlate:TweenPosition(UDim2.new(-12, 0, -0.9, 0), "Out", "Quint", .3)
end

local function ManageEXPPopUp(statName, expAmount, amountAdded)
	local skillInfo = getItemStatTable:InvokeServer("Experience", nil, "Skills", statName)
	local simpleStatName = string.gsub(statName, " Skill", "")

	local currentLevel, nextLevel = guiUtility.FindStatLevel(skillInfo, expAmount)

	if #expPopUpGui:GetChildren() ~= 0 then
		if expPopUpGui.ExperienceBar.NamePlate.DisplayName.Text == simpleStatName then --Old Exp Bar
			ShowEXPChange(currentLevel, nextLevel, skillInfo, expAmount, amountAdded)
			CountdownPopUp(expPopUpGui, expPopUpGui.ExperienceBar, 12, 0.5, 0, 0, 0.9)
		else
			InsertNewEXPBar(skillInfo, simpleStatName, expAmount, currentLevel, nextLevel, true)
		end

	else
		InsertNewEXPBar(skillInfo, simpleStatName, expAmount, currentLevel, nextLevel)
		ShowEXPChange(currentLevel, nextLevel, skillInfo, expAmount, amountAdded)
	end
end

]]

local rarityTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function AnimateRarityShine(popUp, rarityInfo)
	for _,rarityFrame in pairs (popUp:GetChildren()) do
		if string.match(rarityFrame.Name, "RarityFrame") then
			rarityFrame.BackgroundColor3 = Color3.new(255, 255, 255)
			if rarityFrame:FindFirstChild("RarityGradient") then
				rarityFrame.RarityGradient:Destroy()
			end
			
			local rarityGradient = rarityInfo.RarityGradient:Clone()
			rarityGradient.Parent = rarityFrame
			rarityGradient.Rotation = 90
			rarityGradient.Offset = Vector2.new(0, 1.2)
			
			local outShineEffect = tweenService:Create(rarityGradient, rarityTweenInfo, {Offset = Vector2.new(0, -1.2)})
			outShineEffect:Play()
			--outShineEffect.Completed:Wait()
			
			--local inShineEffect = tweenService:Create(rarityGradient, rarityTweenInfo, {Offset = Vector2.new(0, -1.2)})
			--inShineEffect:Play()
			--inShineEffect.Completed:Wait()
		end
	end
	
	--wait(1)
	--if newPopUp.Parent then --was continuous without parent, is it with?
		--print("is this function continuous? for popup: ", newPopUp)
		--AnimateRarityShine(newPopUp, rarityInfo)
	--end
end

---------------------<|RightSide PopUp Management|>---------------------------------------------------------------------

local function CreateRightSidePopUp(newPopUp, popUpType, statName, itemTypeName, amountAdded)
	local yPos = coinDisplay.Position.Y.Scale + coinDisplay.Size.Y.Scale + jumpDistance
	
	--Insert Tile Info
	local newTweenInfo
	local expireTime
	if popUpType == "Item" then
		local itemInfo = replicatedStorage.InventoryItems:FindFirstChild(itemTypeName):FindFirstChild(statName)
		local rarityInfo = guiElements.RarityColors:FindFirstChild(itemInfo["GUI Info"].RarityName.Value)
		local itemImage = itemInfo["GUI Info"].StatImage.Value
		
		if newPopUp:FindFirstChild("ItemAmount") then
			newPopUp.ItemAmount.Text = tostring(amountAdded)
			newTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			expireTime = 2 --possibly 3? Check with timing
		else --Discovered Item PopUp
			newPopUp.UnlockSymbol.ImageColor3 = rarityInfo.Value
			newTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			statName = string.gsub(statName, "Discovered", "")
			expireTime = 6
		end
		
		newPopUp.ItemName.Text = tostring(itemInfo)
		newPopUp.ItemImage.Image = itemImage
		
		newPopUp.RarityFrame.BackgroundColor3 = rarityInfo.Value
		newPopUp.RarityFrame2.BackgroundColor3 = rarityInfo.Value
		--coroutine.resume(coroutine.create(function()
			--AnimateRarityShine(newPopUp, rarityInfo) --Possibly implement?
		--end))
		
		newPopUp.Activated:Connect(function()
			if dataMenu.Visible == false then
				guiUtility.OpenDataMenu(player, playerModel, dataMenu, "InventoryMenu")
			end
			--**Possibly make this a function in GuiUtility (wide purpose use with IsA and possibly string.match() to
			--look through not only pages but even ReplicatedStorage Folders)
			
			local pageFound
			local tileFound
			for _,page in pairs (dataMenu.InventoryMenu.MaterialsMenu:GetChildren()) do
				if tileFound == nil then
					if page:IsA("Frame") and string.match(page.Name, "Page") then
						if tileFound == nil then
							for _,tile in pairs (page:GetChildren()) do
								local itemName = tile.StatName.Value
								
								if itemName == tostring(itemInfo) then
									pageFound = page
									tileFound = tile
								end
							end
						end	
					end
				end
			end
			
			insertItemViewerInfo:Fire(tileFound, dataMenu.InventoryMenu.QuickViewMenu.QuickViewMenu, "Inventory", tostring(itemInfo), itemInfo)
			
			--Highlight tile containing item
			
			
			--Change to page with tile of item
			if dataMenu.InventoryMenu.MaterialsMenu:FindFirstChild("Page1") and pageFound then
				pageFound.Visible = true
				
				local pageManager = dataMenu.PageManager
				pageManager.CurrentPage.Value = pageFound
				pageManager.Menu.Value = dataMenu.InventoryMenu.MaterialsMenu
				pageManager.Visible = true
				pageManager.PartialBottomDisplay.Visible = true
				pageManager.FullBottomDisplay.Visible = false
			end
		end)
		
	elseif string.match(popUpType, "Notify") then --LevelUp, ItemsSold, BagCapacity, EquipBag, ItemsStored
		if popUpType == "LevelUpNotify" then
			
			newPopUp.Activated:Connect(function()
				print("Open Exp Menu and the tile of the skill that was pressed")
				
			end)
			
		elseif popUpType == "BagEquipNotify" then
			
			newPopUp.Activated:Connect(function()
				print("Open Bag Menu")

			end)
			
		else --BagCapacityNotify, ItemsStoredNotify
			newPopUp.Activated:Connect(function()
				print("Open Inventory Menu")
				
			end)
		end	
		
		newTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		expireTime = 6
	end
	
	local popUpCount = GetPopUpCount(itemPopUpGui)
	
	--Move all other popups down
	for p = 1,popUpCount do
		local popUp = itemPopUpGui:FindFirstChild("PopUp" .. tostring(p))
		
		if popUp then
			popUp.Name = "PopUp" .. tostring(p + 1)
			
			local sizeSum = newPopUp.Size.Y.Scale
			if p >= 2 then
				for i = 2,p do
					local iTile = itemPopUpGui:FindFirstChild("PopUp" .. tostring(i))
					if iTile then
						sizeSum += iTile.Size.Y.Scale
					end
				end
			end
			
			local tween = tweenService:Create(popUp, movePopUpTweenInfo, {Position = UDim2.new(xPos, 0, sizeSum + jumpDistance*p + yPos, 0)})
			
			if currentPopUpTweens[popUp] then
				currentPopUpTweens[popUp]:Pause()
				currentPopUpTweens[popUp]:Destroy()
			end
			currentPopUpTweens[popUp] = tween
			tween:Play()
		end
	end
	
	newPopUp.Parent = itemPopUpGui
	newPopUp.Name = "PopUp1"
	newPopUp.Position = UDim2.new(1 + newPopUp.Size.X.Scale, 0, yPos, 0)
	
	if newTweenInfo then
		local tween = tweenService:Create(newPopUp, newTweenInfo, {Position = UDim2.new(xPos, 0, yPos, 0)})
		currentPopUpTweens[newPopUp] = tween
		tween:Play()
	end
	
	CountdownPopUp(newPopUp, expireTime)
end

local itemTilePopUp = guiElements.ItemPopUp
local staticXSize = itemTilePopUp.Size.X.Scale
local staticYSize = itemTilePopUp.Size.Y.Scale
local outPos = UDim2.new(staticXSize*1.04, 0, staticYSize*1.08, 0)

local itemStoredNotify = guiElements.NotifyPopUps.ItemsStoredNotify
depositInteract.Event:Connect(function()
	CreateRightSidePopUp(itemStoredNotify:Clone(), "ItemsStoredNotify")
end)

local sellItemNotify = guiElements.NotifyPopUps.SellItemNotify
sellItem.OnClientEvent:Connect(function()
	CreateRightSidePopUp(sellItemNotify:Clone(), "SellItemNotify") --Should this, if clicked, open notify menu? **Will notify contain transaction history?
end)

updateInventory.OnClientEvent:Connect(function(statName, folder, value, amountAdded, Type, itemTypeName)
	--folder = "Material", "Arcade Level", "Skill", etc...

	if amountAdded ~= nil and amountAdded ~= 0 then
		if Type == "Inventory" then

			local tileUpdated = false
			if itemPopUpGui:FindFirstChild("PopUp1") then
				local popUp = itemPopUpGui.PopUp1
				
				if popUp:FindFirstChild("ItemName") then
					if popUp.ItemName.Text == statName then
						tileUpdated = true
						CountdownPopUp(popUp, 3)
						
						if currentPopUpTweens[statName .. "Out"] then
							currentPopUpTweens[statName .. "Out"]:Pause()
							currentPopUpTweens[statName .. "Out"]:Destroy()
						end
						if currentPopUpTweens[statName .. "In"] then
							currentPopUpTweens[statName .. "In"]:Pause()
							currentPopUpTweens[statName .. "In"]:Destroy()
						end
						popUp.Size = UDim2.new(staticXSize, 0, staticYSize, 0)	
							
						local outTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
						local inTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
						
						local outTween = tweenService:Create(popUp, outTweenInfo, {Size = outPos})
						outTween:Play()
						currentPopUpTweens[statName .. "Out"] = outTween
						
						popUp.ItemAmount.Text = tostring(tonumber(popUp.ItemAmount.Text) + amountAdded)
						wait(0.1)
						
						local inTween = tweenService:Create(popUp, inTweenInfo, {Size = UDim2.new(staticXSize, 0, staticYSize, 0)})
						inTween:Play()
						currentPopUpTweens[statName .. "In"] = inTween
						
						--local itemInfo = game.ReplicatedStorage.InventoryItems:FindFirstChild(itemTypeName):FindFirstChild(statName)
						--local rarityName = itemInfo["GUI Info"].RarityName.Value
						--local rarityInfo = guiElements.RarityColors:FindFirstChild(rarityName)
						--AnimateRarityShine(popUp, rarityInfo)
					end
				end
			end
				
			if tileUpdated == false then
				CreateRightSidePopUp(itemTilePopUp:Clone(), "Item", statName, itemTypeName, amountAdded) 
			end
			
		elseif Type == "Discovered" then
			local newItemTile = guiElements.NotifyPopUps.NewItemNotify:Clone()
			
			wait(0.1)
			CreateRightSidePopUp(newItemTile, "Item", statName, itemTypeName)
			
		elseif Type == "Experience" then 
			--ManageEXPPopUp(statName, value, amountAdded)
		end
	end
end)

local equipBagNotify = guiElements.NotifyPopUps.EquipBagNotify

local bagInterestCapacities = {0.5,0.75,1}

local previousFillPercent
updateItemCount.OnClientEvent:Connect(function(itemTypeCount, bagCapacity, bagType, depositedInventory)
	if itemTypeCount < 0 then
		itemTypeCount = 0
	end

	if not depositedInventory then
		local fillPercent = itemTypeCount/bagCapacity
		
		if previousFillPercent then
			if fillPercent-previousFillPercent > 0 then
				for _,poi in pairs (bagInterestCapacities) do
					if (fillPercent > poi and previousFillPercent < poi) or fillPercent == poi then
						local interestPoint = tostring(poi*100)
						local bagNotify = guiElements.NotifyPopUps:FindFirstChild("Bag" .. interestPoint .. "%Notify") 
						
						wait(0.1)
						CreateRightSidePopUp(bagNotify:Clone(), "Notify") --Remember to :Clone()
					end
				end	
			end
		end

		previousFillPercent = itemTypeCount/bagCapacity
	end

	if itemTypeCount ~= bagCapacity or bagCapacity ~= 0 then --Reference values for inventoryMenu
		local inventoryMenu = dataMenu.InventoryMenu.MaterialsMenu
		inventoryMenu:SetAttribute("ItemCount", itemTypeCount)
		inventoryMenu:SetAttribute("BagCapacity", bagCapacity)
		
	elseif bagCapacity == 0 then
		CreateRightSidePopUp(equipBagNotify:Clone(), "EquipBagNotify")
	end
end)

