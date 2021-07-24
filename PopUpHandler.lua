local player = game.Players.LocalPlayer
local replicatedStorage = game.ReplicatedStorage
local currentCamera = game.Workspace.CurrentCamera
local tweenService = game:GetService("TweenService")

local guiElements = replicatedStorage.GuiElements
local guiUtility = require(replicatedStorage.GuiUtility)
local eventsFolder = replicatedStorage.Events

local depositInteract = eventsFolder.HotKeyInteract:WaitForChild("DepositInteract")

local getCurrentPlayerLevel = eventsFolder.Utility:WaitForChild("GetCurrentPlayerLevel")
local getItemStatTable = eventsFolder.Utility:WaitForChild("GetItemStatTable")
local sellItem = eventsFolder.Utility:WaitForChild("SellItem")

local updateExperience = eventsFolder.GUI:WaitForChild("UpdateExperience")
local insertItemViewerInfo = eventsFolder.GUI:WaitForChild("InsertItemViewerInfo")
local updateInventory = eventsFolder.GUI:WaitForChild("UpdateInventory")
local updateItemCount = eventsFolder.GUI:WaitForChild("UpdateItemCount")

local itemPopUpGui = script.Parent.ItemPopUp
local expBarPopUpGui = script.Parent.ExpBarPopUp
local mouseoverPopUpGui = script.Parent.MouseoverPopUp

local dataMenu = script.Parent.Parent.DataMenu.DataMenu
local playerModel = game.Workspace.Players:WaitForChild(tostring(player))

local currentPopUpTweens = {}

--------------------------<|Utility Functions|>----------------------------------------------------------------------------------------------------------------------------

local function GetPopUpCount(popUpGui)
	local popUpCount = 0
	for _,popUp in pairs (itemPopUpGui:GetChildren()) do --Some PopUps will be labelled "expired"
		if string.match(popUp.Name, "PopUp") then
			popUpCount += 1
		end
	end
	return popUpCount
end

local function SimpleMoveTween(gui, tweenInfo, position)
	local tween = tweenService:Create(gui, tweenInfo, {Position = position})
	tween:Play()
	
	return tween
end

local function SimpleMoveDownTween(gui, tweenInfo, yPos)
	gui.Position = UDim2.new(gui.Position.X.Scale, 0, -1, 0)
	gui.Visible = true
	local tween = tweenService:Create(gui, tweenInfo, {Position = UDim2.new(gui.Position.X.Scale, 0, yPos, 0)})
	tween:Play()
end

local function CalculateLevelProgress(expInfo, expAmount, currentLevel, nextLevel)
	local currentLevelInfo = expInfo["Levels"][currentLevel]
	local nextLevelInfo = expInfo["Levels"][nextLevel]
	return tonumber(expAmount - currentLevelInfo["Exp Requirement"]) / tonumber(nextLevelInfo["Exp Requirement"] - currentLevelInfo["Exp Requirement"])
end

local currentShines = {}
local function AnimateShineEffect(gui, gradient)
	local shineEffectInfo = TweenInfo.new(1.5, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
	local shineTween = tweenService:Create(gradient, shineEffectInfo, {Offset = Vector2.new(0, 3)})
	local startPos = Vector2.new(0, -3)
	
	if currentShines[gui] then
		currentShines[gui]:Pause()
	end
	
	currentShines[gui] = shineTween
	gradient.Offset = startPos
	shineTween:Play()
	shineTween.Completed:Wait()
	currentShines[gui]:Destroy()

	--wait(1)
	
	--**Would be used to repeat the shine effect at a certain pace
	--if gui then
	--AnimateShineEffect(gui, gradient)
	--end
end

----------------------------<|Countdown Functions|>--------------------------------------------------------------------------------------------------------------------------
local coinDisplay = script.Parent.Parent.MoneyDisplay["Coin Display"]
local jumpDistance = coinDisplay.Size.Y.Scale/5.25
local movePopUpTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local xPos = 0.99
local yPos = coinDisplay.Position.Y.Scale + coinDisplay.Size.Y.Scale + jumpDistance


local function CountdownPopUp(popUp, expireTime, dontDestroy, specialHide) --xJump, yJump, xJump2, yJump2
	local timer = popUp.TimeLeft
	timer.Value = 0
	
	coroutine.resume(coroutine.create(function()
		for sec = 1,expireTime do
			wait(1)
			
			if sec == timer.Value + 1 then
				timer.Value = sec
				if sec == expireTime then
					if popUp.Name ~= "Expired" then
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
									
									
									--**Was not working properly because I was not using tween.PlaybackState == Enum.PlaybackState.Playing
									
									
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
						
						if specialHide then
							if specialHide == "ExpBar" then
								--HideExpBar()
							elseif specialHide == "Difference" then
								local xSize = popUp.Size.X.Scale
								local differenceTween = tweenService:Create(popUp, movePopUpTweenInfo, {Size = UDim2.new(xSize, 0, 1, 0)})
								differenceTween:Play()
								differenceTween.Completed:Wait()
								
								if popUp.Parent then --If not levelup
									local progressTween = tweenService:Create(popUp.Parent.Progress, movePopUpTweenInfo, {Size = UDim2.new(xSize, 0, 1, 0)})
									progressTween:Play()
									progressTween.Completed:Wait()
								end
							elseif specialHide == "ExpAmount" then
								local imageBox = popUp.Parent.ImageBox
								local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
								local moveTween = tweenService:Create(popUp, tweenInfo, {Position = UDim2.new(imageBox.Position.X.Scale, 0, imageBox.Position.Y.Scale, 0)})
								local resizeTween = tweenService:Create(popUp, tweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
								
								moveTween:Play()
								resizeTween:Play()
								
								coroutine.resume(coroutine.create(function()
									AnimateShineEffect(popUp.Parent, imageBox.UIStroke.UIGradient)
								end))
								wait(0.5)
							end
						else
							local currentXSize = popUp.Size.X.Scale
							local currentYPos = popUp.Position.Y.Scale
							local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
							local hideTween = tweenService:Create(popUp, tweenInfo, {Position = UDim2.new(1 + currentXSize, 0, currentYPos, 0)})
							hideTween:Play()
							
							wait(0.3)
						end
					end

					if dontDestroy ~= nil then
						popUp.Visible = dontDestroy
					else
						popUp:Destroy()
					end
				end
			end
		end
	end))
end

local differenceExpSum = 0
local lastProgressAmount = 0

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

-----------------------------<|Frequent-Use Tweens|>-----------------------------------------------------------------------------------------

local function ShakePopUp(popUp, expireTime)
	if currentPopUpTweens[popUp] then
		currentPopUpTweens[popUp]:Pause()
	end

	popUp.Position = UDim2.new(xPos, 0, yPos, 0)
	local outXPos = xPos - popUp.Size.X.Scale/20

	CountdownPopUp(popUp, expireTime)

	local outShakeTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local outShakeTween = tweenService:Create(popUp, outShakeTweenInfo, {Position = UDim2.new(outXPos, 0, yPos, 0)})
	outShakeTween:Play()
	currentPopUpTweens[popUp] = outShakeTween

	wait(0.2)

	local inShakeTweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
	local inShakeTween = tweenService:Create(popUp, inShakeTweenInfo, {Position = UDim2.new(xPos, 0, yPos, 0)})
	inShakeTween:Play()
	currentPopUpTweens[popUp] = inShakeTween
end



----------------------------<|EXPBar PopUp Functions|>------------------------------------------------------------------------------------------------------------

local function NewExpAmountPopUp(expBar, expAmount)
	--Possibly color expAmountPopUps based on rarity of item acquired or expColors
	
	local expAmountPopUp = guiElements.ExpAmountPopUp:Clone()
	
	expAmountPopUp.Parent = expBar
	expAmountPopUp.Visible = true
	expAmountPopUp.Text = "+" .. tostring(expAmount)
	
	expAmountPopUp.Position = UDim2.new(math.random(3, 8)/10, 0, math.random(-1, 11)/10, 0)
	expAmountPopUp.Size = UDim2.new(0, 0, 0, 0)
	
	local showAmountTween = tweenService:Create(expAmountPopUp, movePopUpTweenInfo, {Size = UDim2.new(0.36, 0, 0.785, 0)})
	showAmountTween:Play()
	
	CountdownPopUp(expAmountPopUp, 2, nil, "ExpAmount")
end

local function LevelUp(expBar, expName, newLevel)
	local background = expBar.ClipDescendantsFrame.Background
	local currentLevel = background.CurrentLevel
	local nextLevel = background.NextLevel
	local startupInfo = background.StartupInfo
	local progressBar = background.ProgressBar
	local progress = progressBar.Progress
	local difference = progressBar.Difference
	
	expBar.TimeLeft.Value = 0
	difference.TimeLeft.Value = 0

	local progressTweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local progressTween = tweenService:Create(progress, progressTweenInfo, {Size = UDim2.new(1, 0, 1, 0)})
	if currentPopUpTweens[progress] then
		currentPopUpTweens[progress]:Pause()
		currentPopUpTweens[progress]:Destroy()
	end
	
	progressTween:Play()
	--Sound Effect of Bar Completing
	progressTween.Completed:Wait()
	difference.Size = UDim2.new(0, 0, 0, 0)
	
	--Sound Effect/Visual of Bar Completed
	
	--Flip ProgressBar with Startup to display Level
	progressBar.Visible = true
	progressBar.Position = UDim2.new(progressBar.Position.X.Scale, 0, 0.5, 0)
	SimpleMoveTween(progressBar, movePopUpTweenInfo, UDim2.new(progressBar.Position.X.Scale, 0, -1.5, 0))
	
	currentLevel.Visible = true
	currentLevel.Position = UDim2.new(currentLevel.Position.X.Scale, 0, 0.5, 0)
	SimpleMoveTween(currentLevel, movePopUpTweenInfo, UDim2.new(currentLevel.Position.X.Scale, 0, -1.5, 0))
	
	nextLevel.Visible = true
	nextLevel.Position = UDim2.new(nextLevel.Position.X.Scale, 0, 0.5, 0)
	SimpleMoveTween(nextLevel, movePopUpTweenInfo, UDim2.new(nextLevel.Position.X.Scale, 0, -1.5, 0))
	
	startupInfo.Visible = true
	startupInfo.StatName.Text = expName .. " Level " .. tostring(newLevel) .. "!"
	startupInfo.StatNameShadow.Text = expName .. " Level " .. tostring(newLevel) .. "!"
	startupInfo.Position = UDim2.new(startupInfo.Position.X.Scale, 0, 1.5, 0)
	local startupInfoTween = SimpleMoveTween(startupInfo, movePopUpTweenInfo, UDim2.new(startupInfo.Position.X.Scale, 0, 0.5, 0))
	startupInfoTween.Completed:Wait()
	
	wait(3)
	
	SimpleMoveTween(startupInfo, movePopUpTweenInfo, UDim2.new(startupInfo.Position.X.Scale, 0, 1.5, 0))
	SimpleMoveTween(currentLevel, movePopUpTweenInfo, UDim2.new(currentLevel.Position.X.Scale, 0, 0.5, 0))
	SimpleMoveTween(nextLevel, movePopUpTweenInfo, UDim2.new(nextLevel.Position.X.Scale, 0, 0.5, 0))
	currentLevel.Text = tostring(newLevel)
	nextLevel.Text = tostring(newLevel + 1)
	
	local showProgressTween = SimpleMoveTween(progressBar, movePopUpTweenInfo, UDim2.new(progressBar.Position.X.Scale, 0, 0.5, 0))
	startupInfo.Visible = false
	startupInfo.Position = UDim2.new(startupInfo.Position.X.Scale, 0, 0.5, 0)
end

local function ShowExpChange(levelProgress, expInfo, amountAdded)
	local expBar = expBarPopUpGui.ExperienceBar
	local progressBar = expBar.ClipDescendantsFrame.Background.ProgressBar
	
	if levelProgress and progressBar:FindFirstChild("Difference") then --Difference Bar Check
		local difference = progressBar.Difference
		
		if currentPopUpTweens[difference] then
			currentPopUpTweens[difference]:Pause()
		end
		
		local differenceTween = tweenService:Create(difference, movePopUpTweenInfo, {Size = UDim2.new(levelProgress, 0, 1, 0)})
		currentPopUpTweens[difference] = differenceTween
		differenceTween:Play()
		CountdownPopUp(difference, 5, nil, "Difference")
		NewExpAmountPopUp(expBar, amountAdded)
		--CountdownExpDifference(difference, progressBar.Progress, levelProgress, amountAdded)

	else
		--**Need to recognize is difference is in the process of being shut down (label expire but keep in progbar)
		--(See if progress bar is being shut down)
		
		local difference = progressBar.Progress:Clone()
		difference.ZIndex = 5
		difference.Name = "Difference"
		difference.Parent = progressBar
		difference.BackgroundColor3 = expInfo["SecondaryColor"]

		local timeLeft = Instance.new("IntValue", difference)
		timeLeft.Name = "TimeLeft"	

		local differenceTween = tweenService:Create(difference, movePopUpTweenInfo, {Size = UDim2.new(levelProgress, 0, 1, 0)})
		currentPopUpTweens[difference] = differenceTween
		differenceTween:Play()
		
		
		
		--**Need to create the +EXP sum number (number gets bigger as sum gets bigger, or will that make people nervous?)
		--Create the text label that will show a numerical value for how much exp the player is getting
		
		
		CountdownPopUp(difference, 5, nil, "Difference")
		--CountdownExpDifference(difference, progressBar.Progress, levelProgress, levelProgress, amountAdded)
	end
end

local function InsertNewEXPBar(expInfo, statName, levelProgress, currentLevel, nextLevel, replaceOldPopUp)

	if replaceOldPopUp then
		expBarPopUpGui.ExperienceBar.TimeLeft.Value = 0
		--HideExpBar()
		--set TimeLeft of old exp bar to 0 and Countdown should handle it quickly
	end
	
	local newExpBar = guiElements.ExperienceBar:Clone()
	newExpBar.StatName.Value = statName
	newExpBar.Parent = expBarPopUpGui
	newExpBar.Position = UDim2.new(0.088, 0, -0.1, 0)
	
	--Manage Visibility
	local background = newExpBar.ClipDescendantsFrame.Background
	background.Visible = false
	background.ProgressBar.Visible = false
	background.CurrentLevel.Visible = false
	background.NextLevel.Visible = false
	background.StartupInfo.Visible = true
	background.StartupInfo.StatName.Visible = true
	background.StartupInfo.StatNameShadow.Visible = true
	newExpBar.ImageBox.UIStroke.UIGradient.Offset = Vector2.new(0, -3)
	
	--Manage Colors
	background.ProgressBar.Progress.BackgroundColor3 = expInfo["PrimaryColor"]
	background.UIStroke.Color = expInfo["SecondaryColor"]
	newExpBar.ImageBox.BackgroundColor3 = expInfo["ThirdColor"]
	newExpBar.ImageBox.StatImage.Image = expInfo["StatImage"]
	
	--Show ExpImage
	local moveExpTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local quickMoveExpTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local expBarTween = tweenService:Create(newExpBar, moveExpTweenInfo, {Position = UDim2.new(0.088, 0, 0.023, 0)})
	expBarTween:Play()
	currentPopUpTweens[newExpBar] = expBarTween
	
	wait(0.55) --Image Box Moving Down
	
	coroutine.resume(coroutine.create(function()
		AnimateShineEffect(newExpBar, newExpBar.ImageBox.UIStroke.UIGradient)
	end))
	
	wait(0.1)
	
	background.Position = UDim2.new(-0.5, 0, 0.5, 0)
	background.Visible = true
	SimpleMoveTween(background, quickMoveExpTweenInfo, UDim2.new(0.48, 0, 0.5, 0))
	
	wait(3)
	
	background.ProgressBar.Progress.Size = UDim2.new(levelProgress, 0, 1, 0)

	SimpleMoveTween(background.StartupInfo, quickMoveExpTweenInfo, UDim2.new(background.StartupInfo.Position.X.Scale, 0, 1.5, 0))
	SimpleMoveDownTween(background.ProgressBar, quickMoveExpTweenInfo, 0.5)
	
	background.CurrentLevel.Text = currentLevel
	SimpleMoveDownTween(background.CurrentLevel, quickMoveExpTweenInfo, 0.5)
	background.NextLevel.Text = nextLevel
	SimpleMoveDownTween(background.NextLevel, quickMoveExpTweenInfo, 0.5)
	
	wait(0.5)
	
	--[[
	wait(0.5)
	background:TweenSize(UDim2.new(0.895, 0, 1, 0), "Out", "Quint", 0.5)
	wait(0.2)
	
	--Show Experience Info
	background.StartupInfo.Visible = true
	local statNameGui = background.StartupInfo.StatName
	SimpleMoveDownTween(statNameGui, quickMoveExpTweenInfo, 0.042)
	statNameGui.Text = statName

	local statNameShadow = background.StartupInfo.StatNameShadow
	SimpleMoveDownTween(statNameShadow, quickMoveExpTweenInfo, 0.084)
	statNameShadow.Text = statName
	wait(0.1)
	
	local currentLevelGui = background.StartupInfo.CurrentLevel
	currentLevelGui.Visible = true
	SimpleMoveDownTween(currentLevelGui, quickMoveExpTweenInfo, 0.5)
	currentLevelGui.Text = currentLevel
	
	--Load Arrow Image
	local toLevelArrow = background.StartupInfo.ToLevelArrow
	toLevelArrow.Position = UDim2.new(toLevelArrow.Position.X.Scale, 0, -1, 0)
	toLevelArrow.Visible = true
	wait(0.05)
	
	SimpleMoveDownTween(toLevelArrow, quickMoveExpTweenInfo, 0.5)
	wait(0.05)
	
	local upcomingLevel = background.UpcomingLevel
	upcomingLevel.Visible = true
	SimpleMoveDownTween(upcomingLevel, quickMoveExpTweenInfo, 0.5)
	upcomingLevel.Text = nextLevel
	wait(3)
	
	--Swap StartupInfo with ProgressBar
	local startupInfo = background.StartupInfo
	SimpleMoveTween(startupInfo, moveExpTweenInfo, UDim2.new(startupInfo.Position.X.Scale, 0, -1, 0))
	
	local progressBar = background.ProgressBar
	progressBar.Visible = true
	progressBar.Position = UDim2.new(progressBar.Position.X.Scale, 0, 1.5, 0)
	SimpleMoveTween(progressBar, moveExpTweenInfo, UDim2.new(progressBar.Position.X.Scale, 0, 0.5, 0))
	]]
	
	CountdownPopUp(newExpBar, 10, nil, true) --Start Countdown
end

local function ManageExpPopUp(expInfo, levelType, statName, expAmount, amountAdded, levelUp)
	local nonPluralType = levelType
	if string.sub(levelType, -1) == "s" then
		nonPluralType = string.sub(nonPluralType, 1, -2)
	end
	local simpleStatName = string.gsub(statName, " " .. nonPluralType, "")
	
	local currentLevel,nextLevel,levelProgress
	if levelUp then
		currentLevel = levelUp - 1
		nextLevel = levelUp
		levelProgress = 1
	else
		currentLevel, nextLevel = guiUtility.FindStatLevel(expInfo, expAmount)
		levelProgress = CalculateLevelProgress(expInfo, expAmount, currentLevel, nextLevel)
	end
	
	if expBarPopUpGui:FindFirstChild("ExperienceBar") then
		local expBar = expBarPopUpGui.ExperienceBar
		
		if expBar.StatName.Value == simpleStatName then --Old Exp Bar
			--coroutine.resume(coroutine.create(function()
				--AnimateShineEffect(expBar, expBar.ImageBox.UIStroke.UIGradient)
			--end))
			
			ShowExpChange(levelProgress, expInfo, amountAdded)
			CountdownPopUp(expBarPopUpGui.ExperienceBar, 10, nil, true)
		else
			InsertNewEXPBar(expInfo, simpleStatName, levelProgress, currentLevel, nextLevel, true)
		end

	else
		InsertNewEXPBar(expInfo, simpleStatName, levelProgress, currentLevel, nextLevel)
	end
end


local rarityTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function AnimateRarityShine(popUp, rarityInfo)
	for _,rarityFrame in pairs (popUp:GetChildren()) do
		if string.match(rarityFrame.Name, "RarityFrame") then
			rarityFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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

local function ShowDataMenu(itemInfo, itemName, rarityInfo, overallMenu, displayMenu, value, itemType)
	--value is required for equipment and exp while itemType is only equipment
	
	if dataMenu.Visible == false then
		guiUtility.OpenDataMenu(player, playerModel, dataMenu, tostring(overallMenu), displayMenu)
	end
	
	if itemInfo then
		--**Possibly make this a wide use function in GuiUtility to use with menu pages and replicatedstorage folders
		local pageFound
		local tileFound
		for _,page in pairs (displayMenu:GetChildren()) do
			if tileFound == nil then
				if page:IsA("Frame") and string.match(page.Name, "Page") then
					if tileFound == nil then
						for _,tile in pairs (page:GetChildren()) do
							local item = tile.StatName.Value

							if item == itemName then
								pageFound = page
								tileFound = tile
							end
						end
					end	
				end
			end
		end
		
		local statMenu
		if overallMenu:FindFirstChild("QuickViewMenu") then
			statMenu = overallMenu.QuickViewMenu.QuickViewMenu
		else
			statMenu = overallMenu.ExpInfoViewerMenu
		end
		
		local displayMenuName = string.gsub(overallMenu.Name, "Menu", "")
		insertItemViewerInfo:Fire(tileFound, statMenu, displayMenuName, itemName, itemInfo, value, itemType)
		
		if rarityInfo then --Highlight tile containing item
			tileFound.Image = rarityInfo.TileImages.SelectedRarityTile.Value
			
			local previousTile = overallMenu.QuickViewMenu.QuickViewMenu.PreviousTile
			if previousTile.Value then
				local prevRarityInfo = previousTile.Value.Rarity.Value
				previousTile.Value.Image = prevRarityInfo.TileImages.StaticRarityTile.Value
			end
			previousTile.Value = tileFound
		end
		
		--**May have to make a different if statement for experience (and possibly journal)
		--since their tiles will likely directly open their "item's" info menu
		
		--Change to page with tile of item
		local pageManager = dataMenu.PageManager
		if displayMenu:FindFirstChild("Page1") and pageFound then
			displayMenu.Visible = true
			pageFound.Visible = true
			
			pageManager.CurrentPage.Value = pageFound
			pageManager.Menu.Value = displayMenu
			
			if pageFound.Name ~= "Page1" then
				displayMenu.Page1.Visible = false
			end
		end
	end
end

---------------------<|RightSide PopUp Management|>---------------------------------------------------------------------

local function CreateRightSidePopUp(newPopUp, popUpType, statName, itemTypeName, amountAdded)
	
	--Insert Tile Info
	local newTweenInfo
	local expireTime
	if popUpType == "Item" then
		statName = string.gsub(statName, "Discovered", "") --in case newly discovered
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
			ShowDataMenu(itemInfo, statName, rarityInfo, dataMenu.InventoryMenu, dataMenu.InventoryMenu.MaterialsMenu)
		end)
		
	elseif string.match(popUpType, "Notify") then --LevelUp, ItemsSold, BagCapacity, EquipBag, ItemsStored
		if popUpType == "LevelUpNotify" then
			local statInfo = getItemStatTable:InvokeServer("Experience", nil, itemTypeName, statName)
			newPopUp.StatImage.Image = statInfo["StatImage"]
			newPopUp.RarityFrame.BackgroundColor3 = statInfo["SecondaryColor"]
			newPopUp.RarityFrame2.BackgroundColor3 = statInfo["SecondaryColor"]
			
			local nonPluralType = itemTypeName
			if string.sub(itemTypeName, -1) == "s" then
				nonPluralType = string.sub(nonPluralType, 1, -2)
			end
			newPopUp.ExpName.Text = string.gsub(statName, " " .. nonPluralType, "")
			
			newPopUp.Activated:Connect(function()
				ShowDataMenu(statInfo, statName, nil, dataMenu.ExperienceMenu, dataMenu.ExperienceMenu:FindFirstChild(itemTypeName .. "Menu"), itemTypeName)
			end)
			
		elseif popUpType == "EquipBagNotify" then
			newPopUp.Activated:Connect(function()
				ShowDataMenu(nil, nil, nil, dataMenu.PlayerMenu, dataMenu.PlayerMenu.MaterialBagsMenu)
			end)
			
		else --BagCapacityNotify, ItemsStoredNotify
			newPopUp.Activated:Connect(function()
				ShowDataMenu(nil, nil, nil, dataMenu.InventoryMenu, dataMenu.InventoryMenu.MaterialsMenu)
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

updateInventory.OnClientEvent:Connect(function(statName, itemTypeName, value, amountAdded, Type)
	
	if amountAdded ~= nil and amountAdded ~= 0 then
		if Type == "Inventory" then

			local tileUpdated = false
			if itemPopUpGui:FindFirstChild("PopUp1") and itemPopUpGui.PopUp1:FindFirstChild("ItemAmount") then
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
			statName = string.gsub(statName, Type, "")
			itemTypeName = string.gsub(itemTypeName, Type, "")
			
			wait(0.1)
			CreateRightSidePopUp(newItemTile, "Item", statName, itemTypeName)
		end
	end
end)

local levelUpDebounce = false
updateExperience.OnClientEvent:Connect(function(expName, expTypeName, value, amountAdded, Type, levelUp)
	if amountAdded ~= nil and amountAdded ~= 0 then
		local expInfo = getItemStatTable:InvokeServer("Experience", nil, expTypeName, expName)

		if levelUp then
			levelUpDebounce = true
			
			--Way to prevent LevelUp function stacking so, if the player gains a ton of exp at an early level,
			--the levelup animations don't interfere with each other (even a simple skip of numbers would work)
			
			coroutine.resume(coroutine.create(function()
				ManageExpPopUp(expInfo, expTypeName, expName, value, amountAdded, levelUp)
				ShowExpChange(nil, expInfo, amountAdded)
			end))
			
			CreateRightSidePopUp(guiElements.NotifyPopUps.LevelUpNotify:Clone(), "LevelUpNotify", expName, expTypeName, levelUp)
			
			local expBar = expBarPopUpGui.ExperienceBar
			LevelUp(expBar, expName, levelUp)
			
			local expAmount = getCurrentPlayerLevel:InvokeServer(expInfo, true)
			local currentLevel = tonumber(expBar.ClipDescendantsFrame.Background.CurrentLevel.Text)
			local nextLevel = tonumber(expBar.ClipDescendantsFrame.Background.NextLevel.Text)
			local levelProgress = CalculateLevelProgress(expInfo, expAmount, currentLevel, nextLevel)
			
			local progress = expBar.ClipDescendantsFrame.Background.ProgressBar.Progress
			progress.Size = UDim2.new(0, 0, 1, 0)
			wait(0.2) --ProgressBar move down
			
			if progress.Parent:FindFirstChild("Difference") then
				progress.Parent.Difference.Size = UDim2.new(levelProgress, 0, 1, 0)
			end
			
			
			levelUpDebounce = false
			
		elseif levelUpDebounce == false then
			ManageExpPopUp(expInfo, expTypeName, expName, value, amountAdded)
		elseif levelUpDebounce and expBarPopUpGui:FindFirstChild("ExperienceBar") then
			if expBarPopUpGui.ExperienceBar.StatName.Value == expName then
				NewExpAmountPopUp(expBarPopUpGui.ExperienceBar, amountAdded)
			end
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
			if fillPercent-previousFillPercent >= 0 then
				for _,poi in pairs (bagInterestCapacities) do
					if (fillPercent > poi and previousFillPercent < poi) or fillPercent == poi then
						local interestPoint = tostring(poi*100)
						local bagNotify = guiElements.NotifyPopUps:FindFirstChild("Bag" .. interestPoint .. "%Notify") 
						
						local popUpDebounce = false
						if interestPoint == "100" then
							if itemPopUpGui:FindFirstChild("PopUp1") then --Ensure capacity pop up is not already on screen
								if itemPopUpGui.PopUp1:FindFirstChild("CapacityText") then
									if itemPopUpGui.PopUp1.CapacityText.Text == "100%" then
										popUpDebounce = true
										
										--Shake 100% PopUp
										ShakePopUp(itemPopUpGui.PopUp1, 5)
									end
								end
							end
						end
						
						wait(0.1)
						if not popUpDebounce then
							CreateRightSidePopUp(bagNotify:Clone(), "Notify")
						end
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

