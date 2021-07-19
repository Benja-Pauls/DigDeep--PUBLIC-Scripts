local player = game.Players.LocalPlayer
local replicatedStorage = game.ReplicatedStorage
local currentCamera = game.Workspace.CurrentCamera
local tweenService = game:GetService("TweenService")

local guiElements = replicatedStorage.GuiElements
local guiUtility = require(replicatedStorage.GuiUtility)
local eventsFolder = replicatedStorage.Events

local updateInventory = eventsFolder.GUI:WaitForChild("UpdateInventory")
local updateItemCount = eventsFolder.GUI:WaitForChild("UpdateItemCount")

local itemPopUpGui = script.Parent.ItemPopUp
local expBarPopUpGui = script.Parent.EXPBarPopUp
local mouseoverPopUpGui = script.Parent.MouseoverPopUp

local currentPopUpTweens = {}
----------------------------<|Countdown Functions|>--------------------------------------------------------------------------------------------------------------------------

local function CountdownPopUp(popUp, expireTime) --xJump, yJump, xJump2, yJump2
	local timer = popUp.TimeLeft
	timer.Value = 0
	
	coroutine.resume(coroutine.create(function()
		for sec = 1,expireTime do
			wait(1)
			
			if sec == timer.Value + 1 then
				timer.Value = sec
				if sec == expireTime then
					popUp.Name = "Expired"
					
					if currentPopUpTweens[popUp] then
						currentPopUpTweens[popUp]:Pause()
						currentPopUpTweens[popUp]:Destroy()
					end
					
					local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					local currentXSize = popUp.Size.X.Scale
					local currentYPos = popUp.Position.Y.Scale
					
					local hideTween = tweenService:Create(popUp, tweenInfo, {Position = UDim2.new(1 + currentXSize, 0, currentYPos, 0)})
					hideTween:Play()
					
					wait(0.3)
					popUp:Destroy()
				end
			end
		end
	end))
	
	
	--[[
	if popUp:FindFirstChild("TimeLeft") then
		local Timer = popUp.TimeLeft
		Timer.Value = 0

		coroutine.resume(coroutine.create(function()
			for sec = 1,expireTime,1 do
				wait(1)

				if sec == Timer.Value + 1 then
					Timer.Value = sec
					if sec == expireTime then
						
						
						popUp:Destroy()

						if #itemPopUpGui:GetChildren() > 0 then --Rename remaining popUps
							for i,slot in pairs (itemPopUpGui:GetChildren()) do
								slot.Name = "PopUp" .. tostring(i)
							end
						end
					end
				end
			end
		end))
	end
	]]
end

local differenceEXPAdded = 0
local lastProgressAmount = 0
local function CountdownDifference(difference, progressBar, levelProgress, amountAdded, levelFinished)
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
			CountdownDifference(difference, progressBar.Progress, levelProgress, amountAdded, true)

			print("Level up") --** NEXT ON THE PROGRAMMING AGENDA
		else
			difference:TweenSize(UDim2.new(0, 276*levelProgress, 0, 30), "Out", "Quint", .2)
			CountdownDifference(difference, progressBar.Progress, levelProgress, amountAdded)
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

		CountdownDifference(difference, progressBar.Progress, levelProgress, levelProgress, amountAdded)
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

--------------------<|Material PopUp Functions|>-------------------------------------------------------------------------------------------------------------------
--[[
local itemPopUpGui = script.Parent.Parent.PopUps:FindFirstChild("ItemPopUp")

local moveUpAmount = 0.105
local itemPopUpCount
local function InsertNewMaterialPopUp(itemType, statName, amountAdded)

	--Move other popups upward
	for _,popUp in pairs (itemPopUpGui:GetChildren()) do
		popUp:TweenPosition(UDim2.new(popUp.Position.X.Scale, 0, popUp.Position.Y.Scale - moveUpAmount, 0), "Out", "Quint", .8)
	end

	local itemInfo = game.ReplicatedStorage.InventoryItems:FindFirstChild(itemType):FindFirstChild(statName)

	local newItemPopUp = guiElements.PopUpSlot:Clone()
	newItemPopUp.Parent = itemPopUpGui
	newItemPopUp.Amount.Text = tostring(amountAdded)
	newItemPopUp.DisplayName.Text = statName
	newItemPopUp.Object.Value = statName
	newItemPopUp.Position = UDim2.new(0.835, 0,1, 0)

	itemPopUpCount = #itemPopUpGui:GetChildren()
	newItemPopUp.Name = "PopUp" .. tostring(itemPopUpCount)
	newItemPopUp.Object.Value = statName

	local imageId = itemInfo["GUI Info"].StatImage.Value
	newItemPopUp.Picture.Image = imageId

	local rarityName = itemInfo["GUI Info"].RarityName.Value
	local rarityInfo = guiElements.RarityColors:FindFirstChild(rarityName)
	newItemPopUp.BackgroundColor3 = rarityInfo.TileColor.Value
	newItemPopUp.BorderColor3 = rarityInfo.Value
	newItemPopUp.CircleBorder.BackgroundColor3 = rarityInfo.Value
	newItemPopUp["Round Edge"].BackgroundColor3 = rarityInfo.Value
	newItemPopUp["Round Edge"].Inner.BackgroundColor3 = rarityInfo.TileColor.Value

	newItemPopUp.ZIndex = 50

	newItemPopUp:TweenPosition(UDim2.new(0.835, 0,0.8, 0), "Out" , "Quint", .45)
	CountdownPopUp(itemPopUpGui, newItemPopUp, 5, .2, 0)
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
local coinDisplay = script.Parent.Parent.MoneyDisplay["Coin Display"]
local jumpDistance = coinDisplay.Size.Y.Scale/5.25
local scaleJumpDistance = jumpDistance / currentCamera.ViewportSize.Y
local xPos = 0.99

local function CreateRightSidePopUp(newPopUp, popUpType, statName, itemTypeName, amountAdded)
	local yPos = coinDisplay.Position.Y.Scale + coinDisplay.Size.Y.Scale + jumpDistance
	
	--Insert Tile Info
	local newTweenInfo
	local expireTime
	if popUpType == "Item" then
		if newPopUp:FindFirstChild("ItemAmount") then
			newPopUp.ItemAmount.Text = tostring(amountAdded)
			newTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			expireTime = 3
		else --Discovered Item PopUp
			newTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			statName = string.gsub(statName, "Discovered", "")
			expireTime = 7
		end
		
		local itemInfo = replicatedStorage.InventoryItems:FindFirstChild(itemTypeName):FindFirstChild(statName)
		local rarityInfo = guiElements.RarityColors:FindFirstChild(itemInfo["GUI Info"].RarityName.Value)
		local itemImage = itemInfo["GUI Info"].StatImage.Value
		
		newPopUp.ItemName.Text = tostring(itemInfo)
		newPopUp.ItemImage.Image = itemImage
		
		newPopUp.RarityFrame.BackgroundColor3 = rarityInfo.Value
		newPopUp.RarityFrame2.BackgroundColor3 = rarityInfo.Value
		--coroutine.resume(coroutine.create(function()
			--AnimateRarityShine(newPopUp, rarityInfo) --Possibly implement?
		--end))
		
		newPopUp.Activated:Connect(function()
			print("Open Inventory Menu")
			
		end)
		
	elseif string.match(popUpType, "Notify") then
		if popUpType == "LevelUpNotify" then
			
			newPopUp.Activated:Connect(function()
				print("Open Exp Menu")
				
			end)
			
		elseif popUpType == "BagEquipNotify" then
			
			
			newPopUp.Activated:Connect(function()
				print("Open Bag Menu")

			end)
			
		else --BagCapacityNotify
			newPopUp.Activated:Connect(function()
				print("Open Inventory Menu")
				
			end)
		end	
		
		newTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		expireTime = 7
	end
	
	local popUpCount = 0
	for _,popUp in pairs (itemPopUpGui:GetChildren()) do --Some PopUps will be labelled "expired"
		if string.match(popUp.Name, "PopUp") then
			popUpCount += 1
		end
	end
	
	--Move all other popups
	for p = 1,popUpCount do
		local popUp = itemPopUpGui:FindFirstChild("PopUp" .. tostring(p))
		
		if popUp then
			popUp.Name = "PopUp" .. tostring(p + 1)
			
			local sizeSum = newPopUp.Size.Y.Scale
			if p >= 2 then
				for i = 2,p do
					local iTile = itemPopUpGui:FindFirstChild("PopUp" .. tostring(i))
					sizeSum += iTile.Size.Y.Scale
				end
			end
			
			local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			local tween = tweenService:Create(popUp, tweenInfo, {Position = UDim2.new(xPos, 0, sizeSum + jumpDistance*p + yPos, 0)})
			
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

updateInventory.OnClientEvent:Connect(function(statName, folder, value, amountAdded, Type, itemTypeName)
	--folder = "Material", "Arcade Level", "Skill", etc...
	
	--**ADD NEWDISCOVERY PARAMETER
	
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

local dataMenu = script.Parent.Parent.DataMenu.DataMenu

local bagInterestCapacities = {0.5,0.75,1}

local previousFillPercent = 0
updateItemCount.OnClientEvent:Connect(function(itemTypeCount, bagCapacity, bagType, depositedInventory)
	if itemTypeCount < 0 then
		itemTypeCount = 0
	end

	if not depositedInventory then
		local fillPercent = itemTypeCount/bagCapacity
		
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
		
		
		
		
		previousFillPercent = itemTypeCount/bagCapacity
	else
		--**
		print("Put a PopUp when this happens that the player emptied their inventory into storage")
	end

	if itemTypeCount ~= bagCapacity or bagCapacity ~= 0 then --Reference values for inventoryMenu
		local inventoryMenu = dataMenu.InventoryMenu.MaterialsMenu
		inventoryMenu:SetAttribute("ItemCount", itemTypeCount)
		inventoryMenu:SetAttribute("BagCapacity", bagCapacity)
		
	elseif bagCapacity == 0 then
		print("No Bag Equipped. Did this message work properly?")
		--Does this work?
	end
end)

