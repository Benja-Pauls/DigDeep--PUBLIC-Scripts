local GuiUtility = {}

function GuiUtility.GetItemInfo(statName, typeOnly)
	for _,itemType in pairs (game.ReplicatedStorage.InventoryItems:GetChildren()) do
		if itemType:FindFirstChild(statName) then
			if typeOnly then
				return itemType
			else
				return itemType:FindFirstChild(statName)
			end
		end
	end
end

function GuiUtility.GetStatImage(stat, itemInfo)
	if itemInfo == nil then
		itemInfo = GuiUtility.GetItemInfo(tostring(stat))
	end

	if itemInfo then
		if itemInfo["GUI Info"].StatImage then
			return itemInfo["GUI Info"].StatImage.Value
		end
	end
end

--------------<|Text Effects|>-------------------------------------------------------------

function GuiUtility.typeWrite(guiObject, text, delayBetweenChars)
	guiObject.Visible = true
	guiObject.AutoLocalize = false

	local displayText = text
	guiObject.Text = displayText

	local index = 0
	for first, last in utf8.graphemes(displayText) do
		index = index + 1
		guiObject.MaxVisibleGraphemes = index
		wait(delayBetweenChars)
	end
end

function GuiUtility.ManageSearchVisual(searchInput)
	searchInput.Text = "Search..."
	searchInput.Focused:Connect(function()
		searchInput.Text = ""
	end)
	searchInput.FocusLost:Connect(function()
		searchInput.Text = "Search..."
	end)
end

-----------<|Exclusively Calculations|>------------------------------------

function GuiUtility.ConvertShort(Filter_Num) --this function is also in PlayerStatManager for server
	local x = tostring(Filter_Num)
	
	if #x>=10 then
		local important = (#x-9)
		return x:sub(0,(important)).."."..(x:sub(#x-7,(#x-7))).."B"
	elseif #x>=7 then
		local important = (#x-6)
		return x:sub(0,(important)).."."..(x:sub(#x-5,(#x-5))).."M"
	elseif #x>=4 then
		local important = (#x-3)
		return x:sub(0,(important)).."."..(x:sub(#x-2,(#x-2)))..(x:sub(#x-1,(#x-1))) .. "K"
	else
		return Filter_Num
	end
end

function GuiUtility.SlotCountToXY(PageSlotCount, tilesPerRow)
	local tileNumber = PageSlotCount
	local rowValue = math.floor(tileNumber / tilesPerRow)
	local columnValue = (PageSlotCount % (tilesPerRow))
	return columnValue, rowValue
end

function GuiUtility.ToDHMS(sec, tileTimePreview)
	local Days = math.floor(sec/(24*3600))
	local Hours = math.floor(sec%(24 * 3600) / 3600)
	local Minutes = math.floor(sec/60%60)
	local Seconds = sec%60

	local TimeTable = {Days, "d", Hours, "h", Minutes, "m",Seconds, "s"}
	local FormatString = ""
	
	local Display1
	local Display2
	local Display3
	for i,t in pairs (TimeTable) do
		if type(t) == "number" and t ~= 0 then
			local LetterRefernece = TimeTable[i+1]
			if Display1 == nil then
				FormatString = FormatString .. "%01i" .. LetterRefernece
				Display1 = t
			elseif Display2 == nil then
				FormatString = FormatString .. " %01i" .. LetterRefernece
				Display2 = t
			elseif Display3 == nil and tileTimePreview then --Preview is more exact
				FormatString = FormatString .. " %01i" .. LetterRefernece
				Display3 = t
			end
		end
	end

	if Display1 then
		return string.format(FormatString, Display1, Display2, Display3)
	else
		return string.format("%01is", 0)
	end
end

function GuiUtility.FindStatLevel(statInfo, expValue)
	local currentLevel = 0

	if statInfo["Levels"] then
		for l = 1,#statInfo["Levels"],1 do
			if statInfo["Levels"][l] then
				local levelInfo = statInfo["Levels"][l]

				if tonumber(expValue) >= levelInfo["Exp Requirement"] and l > currentLevel then
					currentLevel = l
				end
			end
		end
	end

	local nextLevel
	if statInfo["Levels"][currentLevel + 1] then
		nextLevel = currentLevel + 1
	else
		nextLevel = currentLevel
	end

	return currentLevel,nextLevel
end

-------------<|Tween Functions|>------------------------------------------------------
local TweenService = game:GetService("TweenService")

local buttonDebounces = {}
local currentTweens = {}
local function PressGUIButton(button, newPosition, newSize, moveType)
	if button.Visible == true then
		if buttonDebounces[button.Parent.Name .. button.Name] == false then
			buttonDebounces[button.Parent.Name .. button.Name] = true
			
			if button.Position ~= newPosition and button.Size ~= newSize then

				local opposingMoveType
				if moveType == "neutral" then
					opposingMoveType = "press"
				else
					opposingMoveType = "neutral"
				end
				
				if currentTweens[tostring(button.Parent) .. tostring(button) .. opposingMoveType] then
					local opposingTween = currentTweens[tostring(button.Parent) .. tostring(button) .. opposingMoveType]
					opposingTween:Pause()
				end

				if currentTweens[tostring(button.Parent) .. tostring(button) .. moveType] then
					local tween = currentTweens[tostring(button.Parent) .. tostring(button) .. moveType]
					tween:Pause()
					tween:Play()
				else
					local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					local tween = TweenService:Create(button, tweenInfo, {Position = newPosition, Size = newSize})

					tween:Play()
					currentTweens[tostring(button.Parent) .. tostring(button) .. moveType] = tween
				end
			end
			
			buttonDebounces[button.Parent.Name .. button.Name] = false
		end
	end
end

function GuiUtility.SetUpPressableButton(button, scaleChange)
	local neutralPosition = button.Position
	local neutralSize = button.Size
	local pressPosition = UDim2.new(neutralPosition.X.Scale, 0, neutralPosition.Y.Scale + (scaleChange + scaleChange*.2), 0)
	local pressSize = UDim2.new(neutralSize.X.Scale, 0, neutralSize.Y.Scale - scaleChange, 0)
	
	buttonDebounces[button.Parent.Name .. button.Name] = false
	
	button.MouseButton1Down:Connect(function()
		PressGUIButton(button, pressPosition, pressSize, "press")
	end)
	button.Activated:Connect(function()
		PressGUIButton(button, neutralPosition, neutralSize, "neutral")
	end)
	button.MouseLeave:Connect(function()
		PressGUIButton(button, neutralPosition, neutralSize, "neutral")
	end)
end




-----------------------<|Info Display Functions|>---------------------------------------------------------------------------------------------

local function ChangeNotifySymbol(gui)
	if gui then
		if gui:FindFirstChild("NotifySymbol") then
			gui.NotifySymbol.Visible = true
		end
	end
end

function GuiUtility.UpdateNotifySymbols(itemMenu, itemTile)
	ChangeNotifySymbol(itemTile)
	
	ChangeNotifySymbol(itemMenu.Parent:FindFirstChild(tostring(itemMenu) .. "Button"))
	
	if itemMenu.Parent.Parent.Name == "DataMenu" then
		ChangeNotifySymbol(itemMenu.Parent.Parent:FindFirstChild(tostring(itemMenu.Parent) .. "Button"))
	end
end

function GuiUtility.CleanupMenuDefaults(player, menu)
	local dataMenu = player.PlayerGui.DataMenu.DataMenu
	
	--Prep Default Menus
	if menu.Name == "DataMenu" or menu.Name == "PlayerMenu" then
		for _,gui in pairs (dataMenu.PlayerMenu:GetChildren()) do
			gui.Visible = false
			
			if gui:IsA("ImageButton") then
				gui.Visible = true
				gui.Active = true
			end
		end
		dataMenu.PlayerMenu.PlayerInfo.Visible = true
	end

	for _,button in pairs(menu:GetChildren()) do
		if (button:IsA("TextButton") or button:IsA("ImageButton")) and button:FindFirstChild("Menu") then
			local associatedMenuName = button.Menu.Value
			local buttonMenu = menu:FindFirstChild(associatedMenuName)

			buttonMenu.Visible = false
		end
	end

	if menu.Name == "ExperienceMenu" then
		menu.SkillsMenu.Visible = true
		menu.SideButtonBar.Visible = true
	end
end

function GuiUtility.OpenDataMenu(player, playerModel, dataMenu, overallMenuName, displayMenu)
	local openDataMenuButton = dataMenu.Parent.OpenDataMenuButton
	local menuTabs = {
		dataMenu.PlayerMenuButton, 
		dataMenu.InventoryMenuButton, 
		dataMenu.ExperienceMenuButton,
		dataMenu.JournalMenuButton
	}
	
	dataMenu.Position = UDim2.new(0.5, 0, -0.8, 0)
	dataMenu.Visible = true
	dataMenu.PlayerMenu.EmptyNotifier.Visible = false
	dataMenu.TopTabBar.CloseMenu.Active = true
	openDataMenuButton.Active = false

	--CheckForNewItems()

	--Reset Tab Selection
	for _,tab in pairs (menuTabs) do
		if tab.Name == overallMenuName .. "Button" then
			local currentButton = dataMenu:FindFirstChild(overallMenuName .. "Button")
			local tabSelection = dataMenu.TopTabBar.TabSelection
			local tabWidth = currentButton.Size.X.Scale
			local tsWidth = tabSelection.Size.X.Scale

			local newSelectPos = math.abs(tabWidth - tsWidth)/2 + currentButton.Position.X.Scale
			tabSelection.Position = UDim2.new(newSelectPos, 0, 0.888, 0)
			currentButton.Image = currentButton.SelectedImage.Value
			currentButton.Active = true
		else
			tab.Image = tab.StaticImage.Value
		end
	end

	GuiUtility.CleanupMenuDefaults(player, dataMenu)
	
	if dataMenu:FindFirstChild(overallMenuName) then
		local overallMenu = dataMenu:FindFirstChild(overallMenuName)
		GuiUtility.CleanupMenuDefaults(player, overallMenu)
		overallMenu.Visible = true
		
		if displayMenu == nil then
			local found = false
			for _,gui in pairs (overallMenu:GetChildren()) do
				if gui:FindFirstChild("FirstSeeMenu") and not found then
					found = true
					displayMenu = gui
				end
			end
		end
		
		--Page Display Management
		if displayMenu then
			local pageManager = dataMenu.PageManager
			if displayMenu:FindFirstChild("Page1") then
				pageManager.Visible = true
				displayMenu.Visible = true
				displayMenu.Page1.Visible = true
				overallMenu.EmptyNotifier.Visible = false
				
				pageManager.FullBottomDisplay.Visible = false
				if overallMenu:FindFirstChild("QuickViewMenu") then
					pageManager.PartialBottomDisplay.Visible = true
				else
					pageManager.PartialBottomDisplay.Visible = false
				end
			else
				pageManager.Visible = false
				displayMenu.Visible = false
				overallMenu.EmptyNotifier.Visible = true
			end
		end
		
		if overallMenuName == "Experience" then
			--Display reward menu
			
			--Should the reward menu be a full screen menu, a text appearance, or the highlighting of what
			--level the player just reached
			
		end
	end

	GuiUtility.Display3DModels(player, dataMenu.PlayerMenu.PlayerInfo.PlayerView, playerModel:Clone(), true, 178)
	
	dataMenu:TweenPosition(UDim2.new(0.5, 0, 0.525, 0), "Out", "Quint", 0.5)
	
	wait(0.5)
	openDataMenuButton.Active = true
end

function GuiUtility.Display3DModels(Player, viewport, displayModel, bool, displayAngle)
	--possibly clear all viewports once menu is closed? (or once viewport is not visible?)
	--print("Display3DModels: ", Player, viewport, displayModel, bool, displayAngle)
	if bool == true then
		GuiUtility.Display3DModels(Player, viewport, displayModel:Clone(), false) --reset current viewPort

		local rootPart
		if displayModel.Name == tostring(Player) then
			displayModel.Parent = viewport.Physics
			rootPart = displayModel.HumanoidRootPart

			local idleAnimation = displayModel.Humanoid:LoadAnimation(displayModel.Animate.idle.Animation1)
			idleAnimation:Play()
		else
			local ParentModel = Instance.new("Model", viewport.Physics)
			displayModel.Parent = ParentModel
			
			if displayModel:IsA("Model") then --Multi-part item
				rootPart = displayModel.Target
				
				if displayModel:FindFirstChild("GenerationPosition") then
					displayModel.GenerationPosition:Destroy()
				end
				
			else
				rootPart = displayModel
			end
			
			displayModel = ParentModel
		end
		
		if viewport:FindFirstChild("Camera") then
			viewport.Camera:Destroy()
		end
		local vpCamera = Instance.new("Camera",viewport)

		rootPart.Name = "RootPart"
		rootPart.Anchored = true
		viewport.CurrentCamera = vpCamera

		--Move Camera Around Object & Auto FOV
		local referenceAngle = Instance.new("NumberValue", rootPart)
		referenceAngle.Name = "ReferenceAngle"
		referenceAngle.Value = displayAngle
		
		if viewport.Physics:FindFirstChild("Model") then
			local parentModel = viewport.Physics.Model
			parentModel.PrimaryPart = rootPart
			parentModel:SetPrimaryPartCFrame(parentModel:GetPrimaryPartCFrame()*CFrame.fromEulerAnglesXYZ(math.rad(referenceAngle.Value),0,0))
		end
		
		local modelCenter, modelSize = displayModel:GetBoundingBox()	

		local rotInv = (modelCenter - modelCenter.p):inverse()
		modelCenter = modelCenter * rotInv
		modelSize = rotInv * modelSize
		modelSize = Vector3.new(math.abs(modelSize.x), math.abs(modelSize.y), math.abs(modelSize.z))

		local diagonal = 0
		local maxExtent = math.max(modelSize.x, modelSize.y, modelSize.z)
		local tan = math.tan(math.rad(vpCamera.FieldOfView/2))

		if (maxExtent == modelSize.x) then
			diagonal = math.sqrt(modelSize.y*modelSize.y + modelSize.z*modelSize.z)/2
		elseif (maxExtent == modelSize.y) then
			diagonal = math.sqrt(modelSize.x*modelSize.x + modelSize.z*modelSize.z)/2
		else
			diagonal = math.sqrt(modelSize.x*modelSize.x + modelSize.y*modelSize.y)/2
		end

		local minDist = (maxExtent/4)/tan + diagonal
		game:GetService("RunService").RenderStepped:Connect(function(dt)
			referenceAngle.Value += (1*dt*60)/3
			vpCamera.CFrame = modelCenter * CFrame.fromEulerAnglesYXZ(0, math.rad(referenceAngle.Value), 0) * CFrame.new(0, 0, minDist + 3)
		end)
	else
		viewport.CurrentCamera = nil
		for i,view in pairs (viewport.Physics:GetChildren()) do
			view:Destroy()
		end
	end
end

function GuiUtility.Reset3DObject(Player, viewport, displayModel, angle)
	viewport.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then
			if displayModel == nil then
				local differentDisplayModel = viewport.Physics.Model.RootPart
				local differentAngle = viewport.Physics.Model.RootPart.ReferenceAngle.Value
				if differentDisplayModel ~= nil then
					GuiUtility.Display3DModels(Player, viewport, differentDisplayModel:Clone(), true, differentAngle)
				end
			else
				GuiUtility.Display3DModels(Player, viewport, displayModel:Clone(), true, angle)
			end
		end
	end)
end

function GuiUtility.ManageTextBoxSize(frame, inputText, charactersPerRow, rowSize)
	local characterAmount = string.len(inputText)
	local rowCount = characterAmount/charactersPerRow

	if rowCount < 1 then
		rowCount = 1
	--else
		--rowCount = math.ceil(rowCount)
	end

	frame.Size = UDim2.new(frame.Size.X.Scale, 0, rowSize * rowCount, 0)
end

---------------<|Page Manager Functions|>--------------------

function GuiUtility.CommitPageChange(changedToPage, delayAmount)
	changedToPage.ZIndex += 1
	changedToPage.Visible = true
	changedToPage:TweenPosition(UDim2.new(0,0,0,0), "Out", "Quint", delayAmount)
	wait(delayAmount)

	--Manage Page Invisibility
	for _,page in pairs (changedToPage.Parent:GetChildren()) do
		if page:IsA("Frame") and string.match(page.Name, "Page") then
			if page ~= changedToPage then
				page.Visible = false
			else
				page.Visible = true
			end
			page.Position = UDim2.new(0, 0, 0, 0)
		end
	end
	changedToPage.ZIndex -= 1
	
	return false --for page debounce
end

local function MoveTopDownPage(pageManager, pages, newPagePos, currentPagePos, previousPageNumber)
	if previousPageNumber then
		local newPageNumber = pageManager.CurrentPage.Value
		local newPage = pages:FindFirstChild("Page" .. tostring(newPageNumber))
		local currentPage = pages:FindFirstChild("Page" .. tostring(previousPageNumber))

		newPage.ZIndex += 1
		newPage.Position = UDim2.new(0, 0, newPagePos, 0)
		newPage.Visible = true

		newPage:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quint", 0.3)
		currentPage:TweenPosition(UDim2.new(0, 0, currentPagePos, 0), "Out", "Quint", 0.3)
		pageManager.CurrentPage.Value = newPageNumber

		wait(0.3)
		newPage.ZIndex -= 1
		currentPage.Visible = false
		currentPage.Position = UDim2.new(0, 0, 0, 0)
	else
		local currentPage = currentPagePos
		currentPage:TweenPosition(UDim2.new(0, 0, 0.03*newPagePos, 0), "Out", "Quint", 0.1)
		wait(0.1)
		currentPage:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Bounce", 0.25)
		wait(0.25)
	end
end

function GuiUtility.ChangeToNextPage(pageManager, pages)
	local currentPageNumber = pageManager.CurrentPage.Value
	local pageCount = #pages:GetChildren() --possibly make GuiUtility wide gethighpage in future

	if pageCount > 1 then
		if pageManager.CurrentPage.Value + 1 > pageCount then
			pageManager.CurrentPage.Value = 1
		else
			pageManager.CurrentPage.Value += 1
		end

		MoveTopDownPage(pageManager, pages, 1, -1, currentPageNumber)
	else
		local currentPage = pages:FindFirstChild("Page" .. tostring(currentPageNumber))
		MoveTopDownPage(pageManager, pages, 1, currentPage)
	end
end

function GuiUtility.ChangeToPreviousPage(pageManager, pages)
	local currentPageNumber = pageManager.CurrentPage.Value
	local pageCount = #pages:GetChildren() --possibly make GuiUtility wide gethighpage in future

	if pageCount > 1 then
		if pageManager.CurrentPage.Value - 1 <= 0 then
			pageManager.CurrentPage.Value = pageCount
		else
			pageManager.CurrentPage.Value -= 1
		end

		MoveTopDownPage(pageManager, pages, -1, 1, currentPageNumber)
	else
		local currentPage = pages:FindFirstChild("Page" .. tostring(currentPageNumber))
		MoveTopDownPage(pageManager, pages, -1, currentPage)
	end
end

--Make page change function that can be used everywhere, checking all directions with the only difference between
--next and previous in terms of function but then using local GuiUtility functions to tween since that is so similar








return GuiUtility

