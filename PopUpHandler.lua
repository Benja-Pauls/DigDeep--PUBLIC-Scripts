local player = game.Players.LocalPlayer
local replicatedStorage = game.ReplicatedStorage
local currentCamera = game.Workspace.CurrentCamera

local guiElements = replicatedStorage.GuiElements
local guiUtility = require(replicatedStorage.GuiUtility)
local eventsFolder = replicatedStorage.Events

local updateInventory = eventsFolder.GUI:WaitForChild("UpdateInventory")
local updateItemCount = eventsFolder.GUI:WaitForChild("UpdateItemCount")

local itemPopUpGui = script.Parent.ItemPopUp
local expBarPopUpGui = script.Parent.EXPBarPopUp
local mouseoverPopUpGui = script.Parent.MouseoverPopUp

----------------------------<|Countdown Functions|>--------------------------------------------------------------------------------------------------------------------------

function CountdownPopUp(popUpGuiScreen, popUp, expireTime, xJump, yJump, xJump2, yJump2)
	if popUp:FindFirstChild("TimeLeft") then
		local Timer = popUp.TimeLeft
		Timer.Value = 0

		coroutine.resume(coroutine.create(function()
			for sec = 1,expireTime,1 do
				wait(1)

				if sec == Timer.Value + 1 then
					Timer.Value = sec
					if sec == expireTime then
						if popUp:FindFirstChild("NamePlate") then
							local namePlate = popUp:FindFirstChild("NamePlate")
							local xPos = namePlate.Position.X.Scale
							local yPos = namePlate.Position.Y.Scale
							namePlate:TweenPosition(UDim2.new(xPos + xJump2 ,0 , yPos + yJump2 ,0), "Out", "Quint", .3)
							wait(.4)
						end

						local xPos = popUp.Position.X.Scale
						local yPos = popUp.Position.Y.Scale
						popUp:TweenPosition(UDim2.new(xPos + xJump, 0, yPos + yJump, 0), "In", "Quint", .5)
						wait(.8)
						popUp:Destroy()

						if #popUpGuiScreen:GetChildren() > 0 then
							for i,slot in pairs (popUpGuiScreen:GetChildren()) do
								slot.Name = "PopUp" .. tostring(i)
							end
						end
					end
				end
			end
		end))
	end
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

---------------------<|RightSide PopUp Management|>---------------------------------------------------------------------
local coinDisplay = script.Parent.Parent.MoneyDisplay["Coin Display"]
local jumpDistance = coinDisplay.Size.Y.Scale/5.25
local scaleJumpDistance = jumpDistance / currentCamera.ViewportSize.Y
local xPos = 0.99

local function CreateRightSidePopUp(tile, tileType, statName, itemTypeName, amountAdded)
	--statName, itemTypeName, and amountAdded are for itemPopUps, not notifiers
	
	--**no limit on the count of tiles; if they insert fast enough, there should be a lot on-screen
	
	
	local yPos = coinDisplay.Position.Y.Scale + coinDisplay.Size.Y.Scale + jumpDistance
	
	if tileType == "Item" then
		--Insert tile info
		local itemInfo = replicatedStorage.InventoryItems:FindFirstChild(itemTypeName):FindFirstChild(statName)
		local rarityInfo = guiElements.RarityColors:FindFirstChild(itemInfo["GUI Info"].RarityName.Value)
		local itemImage = itemInfo["GUI Info"].StatImage.Value
		
		tile.ItemName.Text = tostring(itemInfo)
		tile.ItemImage.Image = itemImage
		tile.ItemAmount.Text = tostring(amountAdded)
		tile.RarityFrame.BackgroundColor3 = rarityInfo.Value
		tile.RarityFrame2.BackgroundColor3 = rarityInfo.Value
		
		
		
		
		
		tile.Activated:Connect(function()
			print("Open Inventory Menu")
			
		end)
		
	elseif string.match(tileType, "Notify") then
		if tileType == "LevelUpNotify" then
			
			tile.Activated:Connect(function()
				print("Open Exp Menu")
				
			end)
			
		elseif tileType == "BagEquipNotify" then
			
			
			tile.Activated:Connect(function()
				print("Open Bag Menu")

			end)
			
		else --BagCapacityNotify, NewItemNotify
			
			tile.Activated:Connect(function()
				print("Open Inventory Menu")
				
			end)
		end	
	end
	
	--for _,popUp in pairs (itemPopUpGui:GetChildren()) do
	for p = 1,#itemPopUpGui:GetChildren() do
		local popUp = itemPopUpGui:FindFirstChild("PopUp" .. tostring(p))
		popUp.Name = "PopUp" .. tostring(p + 1)
		
		--popUp.Position = UDim2.new(xPos, 0, popUp.Position.Y.Scale + tile.Size.Y.Scale + scaleJumpDistance, yPos)
		--popUp.Position = UDim2.new(xPos, 0, popUp.Position.Y.Scale + tile.Size.Y.Scale + jumpDistance, 0)
		
		local sizeSum = tile.Size.Y.Scale
		if p >= 2 then
			for i = 2,p do
				local iTile = itemPopUpGui:FindFirstChild("PopUp" .. tostring(i))
				sizeSum += iTile.Size.Y.Scale
			end
		end
		
		popUp.Position = UDim2.new(xPos, 0, sizeSum + jumpDistance*p + yPos, 0)
		
		if p == #itemPopUpGui:GetChildren() then
			 print(sizeSum, jumpDistance*p, jumpDistance*(p-1), p)
		end
	end
	
	tile.Parent = itemPopUpGui
	tile.Name = "PopUp1"
	
	--**Later tween into position
	tile.Position = UDim2.new(xPos, 0, yPos, 0)
	
	--manage right side pop ups by naming the new slot 1 and the rest prev+1 while also moving all other tiles down 
	--by the height of the newly inserted tile+jump distance, if there is any other tiles to move
	
	
	--[[
	if amountAdded < 0 then
		currentPopUpStat = "Negative" .. statName --Should losing items be recorded? YES
	else
		currentPopUpStat = statName
	end


	if prevItem ~= currentPopUpStat then
		InsertNewMaterialPopUp(itemTypeName, statName, amountAdded)
		prevItem = statName
		prevAmount = amountAdded

	elseif prevItem == currentPopUpStat and #itemPopUpGui:GetChildren() == 0 then
		InsertNewMaterialPopUp(itemTypeName, statName, amountAdded) --Was PopUp of stat, but expired
		prevItem = statName
		prevAmount = amountAdded

	elseif #itemPopUpGui:GetChildren() >= 1 then
		prevAmount = prevAmount + amountAdded --Update Item PopUp

		local MostRecent = 0
		for i,slot in pairs (itemPopUpGui:GetChildren()) do
			if slot.Object.Value == statName then
				if i > MostRecent then
					MostRecent = i
				end
			end
		end

		itemPopUpGui:FindFirstChild("PopUp" .. tostring(MostRecent)).Amount.Text = tostring(prevAmount)
		CountdownPopUp(itemPopUpGui, itemPopUpGui:FindFirstChild("PopUp" .. tostring(MostRecent)), 5, .2, 0)
	end
	]]
end


updateInventory.OnClientEvent:Connect(function(statName, folder, value, amountAdded, Type, itemTypeName)
	--folder = "Material", "Arcade Level", "Skill", etc...
	
	--**ADD NEWDISCOVERY PARAMETER
	
	if amountAdded ~= nil and amountAdded ~= 0 then
		if Type == "Inventory" then
			
			--see if PopUp1 is already this item (if so, update the amount)
			local tileUpdated = false
			if itemPopUpGui:FindFirstChild("PopUp1") then
				local popUp = itemPopUpGui.PopUp1
				
				if popUp:FindFirstChild("ItemName") then
					if popUp.ItemName.Text == statName then
						tileUpdated = true
						popUp.TimeLeft.Value = 0
						
						popUp.ItemAmount.Text = tostring(tonumber(popUp.ItemAmount.Text) + amountAdded)
					end
				end
			end
				
			if tileUpdated == false then
				local itemTile = guiElements.ItemPopUp:Clone()
				CreateRightSidePopUp(itemTile, "Item", statName, itemTypeName, amountAdded) 
			end

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

