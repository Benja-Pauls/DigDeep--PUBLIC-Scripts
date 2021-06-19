--(LocalScript)
--Visuals for TycoonComputer GUI that handles player storage and the research menu
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local PlayerGui = Player:WaitForChild("PlayerGui")
local StarterGui = game:GetService("StarterGui")
local TycoonComputerGui = script.Parent
local GuiUtility = require(game.ReplicatedStorage:FindFirstChild("GuiUtility"))

local ComputerScreen = TycoonComputerGui.ComputerScreen
local MenuSelect = ComputerScreen.MenuSelect
local FadeOut = ComputerScreen.FadeOut

ComputerScreen.Visible = false

local Character = game.Workspace.Players:WaitForChild(tostring(Player))
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local DefaultWalkSpeed = Character.Humanoid.WalkSpeed
local DefaultJumpPower = Character.Humanoid.JumpPower

local eventsFolder = game.ReplicatedStorage.Events
local LocalLoadTycoon = eventsFolder.Tycoon:WaitForChild("LocalLoadTycoon")
local MoveAllBaseScreenUI = eventsFolder.GUI:WaitForChild("MoveAllBaseScreenUI")
local GetItemCountSum = eventsFolder.Utility:WaitForChild("GetItemCountSum")
local GetCurrentSkillLevel = eventsFolder.Utility:WaitForChild("GetCurrentSkillLevel")

local ComputerIsOn = false
local CurrentStorage

local BeepSound = script.Parent.Beep
local KeyboardClickSound = script.Parent.KeyboardClick
local StartUpSound = script.Parent.StartUp
local HoverSound = script.Parent.Hover

for i,v in pairs (ComputerScreen:GetDescendants()) do
	if v:IsA("TextButton") or v:IsA("ImageButton") then
		v.MouseEnter:Connect(function()
			HoverSound:Play()
		end)
	end
end

---------------<|Utility|>-----------------------------------------------------------------------------------------------------------------------------

local GuiUtility = require(game.ReplicatedStorage:FindFirstChild("GuiUtility"))

local function FindItemInfo(statName, bagType)
	local ItemInformation
	for i,location in pairs (game.ReplicatedStorage.ItemLocations:GetChildren()) do
		if location:FindFirstChild(statName) then
			if string.gsub(location:FindFirstChild(statName).Bag.Value, "Bag", "") .. "s" == bagType then
				ItemInformation = location:FindFirstChild(statName)
			end
		end
	end	
	return ItemInformation
end

local function MenuButtonActiveState(Menu, State)
	for i,button in pairs (Menu:GetChildren()) do
		if button:IsA("ImageButton") then
			button.Active = State
			button.Selectable = State
		end
	end
end

--------------------------<|Set Up Menu Functions|>-------------------------------------------------------------------------------------------------------------

local function StartUpComputer()
	ComputerScreen.Visible = true
	FadeOut.BackgroundTransparency = 0
	wait(.7)
	SetUpCredentials()
end

local function ShutDownComputer()
	ComputerIsOn = false
	for t = 1,20,1 do
		wait(.02)
		FadeOut.BackgroundTransparency = FadeOut.BackgroundTransparency - 0.05
	end
	ComputerScreen.Visible = false
	
	ShutDownCutscene()
end

local function PrepareAllMenuVisibility()
	for i,menu in pairs(ComputerScreen:GetChildren()) do
		if (menu:IsA("Frame") or menu:IsA("ImageLabel")) and tostring(menu) ~= "FadeOut" then
			menu.Visible = false

			if tostring(menu) == "StorageMenu" or tostring(menu) == "ResearchMenu" then
				for i,itemMenu in pairs (menu:GetChildren()) do
					if itemMenu:IsA("Frame") then
						itemMenu.Visible = false
					end
				end
			elseif tostring(menu) == "Taskbar" then
				menu.CurrentResearchButton.Visible = false
				menu.CurrentResearchButton.Active = false
				menu.PreviousResearchButton.Visible = false
				menu.PreviousResearchButton.Active = false
				
				UpdatePageDisplay(ComputerScreen.ResearchMenu.PreviousResearch, false)
				UpdatePageDisplay(ComputerScreen.ResearchMenu.AvailableResearch, false)
				UpdatePageDisplay(ComputerScreen.ResearchMenu.CostList, false)
			end
		elseif tostring(menu) == "FadeOut" then
			menu.Visible = true
		end
	end
end

function SetUpCredentials()
	local PlayerUserId = Player.UserId
	
	local stringTime = "%I:%M %p"
	local timestamp = os.time()
	ComputerScreen.CredentialsScreen.Time.Text = tostring(os.date(stringTime, timestamp))
	ComputerScreen.CredentialsScreen.User_Login.Username.Text = tostring(Player)
	
	local PlayerThumbnail = ComputerScreen.CredentialsScreen.PlayerThumbnail
	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size420x420
	local PlayerProfilePicture = Players:GetUserThumbnailAsync(PlayerUserId, thumbType, thumbSize)
	PlayerThumbnail.Image = PlayerProfilePicture
	
	PrepareAllMenuVisibility()
	
	ComputerScreen.Taskbar.Visible = false
	ComputerScreen.CredentialsScreen.Visible = true
	
	--Fade-in login screen
	local PasswordInput = ComputerScreen.CredentialsScreen.Pass_Login.Password
	for i = 1,4,1 do
		PasswordInput:FindFirstChild(tostring(i)).Visible = false
	end
	for t = 1,20,1 do
		wait(.02)
		FadeOut.BackgroundTransparency = FadeOut.BackgroundTransparency + 0.05
	end
	
	--Login sound effects
	for i = 1,4,1 do
		wait(1/i-.1)
		if KeyboardClickSound.Playing then
			KeyboardClickSound:Stop()
		end
		KeyboardClickSound:Play()
		PasswordInput:FindFirstChild(tostring(i)).Visible = true
	end
	wait(1)

	--BackButton.Position = UDim2.new(BackButton.Position.X.Scale, 0, 1, 0)
	ComputerScreen.CredentialsScreen:TweenPosition(UDim2.new(0,0,-1.3,0), "Out", "Quint", .5)
	ComputerScreen.Taskbar.Visible = true
	ComputerScreen.Taskbar.Time.Text = tostring(os.date(stringTime, timestamp))
	
	MenuSelect.Visible = true
	wait(.5)
	
	ComputerScreen.CredentialsScreen.Visible = false
	ComputerScreen.CredentialsScreen.Position = UDim2.new(0,0,0,0)
end


----------------------------<|Tycoon Storage GUI Functions|>---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local StorageMenu = ComputerScreen.StorageMenu
local SelectionMenu = StorageMenu.SelectionMenu
local ItemsPreview = StorageMenu.ItemsPreview

--Menu Selection
MenuSelect.StorageMenuButton.Activated:Connect(function()
	StorageMenu.Visible = true
	SelectionMenu.Visible = false
	ItemsPreview.Visible = false
	MenuSelect.Visible = false
	StorageMenu.TopTab.Visible = false
	StorageMenu.EmptyNotifier.Visible = false
	ManageSellMenu(false)
	BeepSound:Play()
	
	StorageMenu.TopTab.Visible = true
	OpenAffiliatedItemPreview("Materials")
end)

------------------------<|Storage Utility|>------------------------------------------------

local function FindNearbyRarity(Menu, rarityInfo, orderValue, direction)
	if orderValue + direction ~= 0 and orderValue + direction < #rarityInfo.Parent:GetChildren() then
		local checkedRarityName
		for i,rarity in pairs (rarityInfo.Parent:GetChildren()) do
			if rarity:IsA("Color3Value") and checkedRarityName == nil then
				if rarity.Order.Value == orderValue + direction then
					checkedRarityName = rarity.Name
				end
			end
		end
		
		local highPage = GetHighPage(Menu, checkedRarityName)
		--print("44444444444444 Checking if ", checkedRarityName, " is in ", Menu, " rarity high page is ", highPage)

		if highPage ~= 0 then --Page found with seeked rarity
			return highPage, checkedRarityName
		else --Not found, continue searching lower/higher rarities
			return FindNearbyRarity(Menu, rarityInfo, orderValue + direction, direction)
		end
	else
		return nil	
	end
end

local function FinalizePageCreation(itemMenu, rarityInfo, referencePageNumber, insertionDirection)
	--print("Creating a new page in ", itemMenu, " with page number: ", referencePageNumber + insertionDirection, " and rarity ", rarityInfo)

	for i,page in pairs (itemMenu:GetChildren()) do
		local pageNumber = string.gsub(page.Name, "Page", "")
		if tonumber(pageNumber) >= referencePageNumber + insertionDirection then
			page.Name = "Page" .. tostring(pageNumber + 1)
		end
	end
	
	local tycoonStoragePage = game.ReplicatedStorage.GuiElements.DataMenuPage
	local newPage = tycoonStoragePage:Clone()
	newPage.Parent = itemMenu
	newPage.BackgroundTransparency = 1
	newPage.Name = "Page" .. tostring(referencePageNumber + insertionDirection)

	local rarityReference = Instance.new("ObjectValue", newPage)
	rarityReference.Name = "Rarity"
	rarityReference.Value = rarityInfo
	
	newPage.Visible = false
	return newPage
end

local SellMenu = StorageMenu.SellMenu
function ManageSellMenu(bool)
	SellMenu.Visible = bool
	StorageMenu.EmptyNotifier.Visible = bool
	StorageMenu.BackgroundFade.Visible = bool
	
	for i,button in pairs (StorageMenu:GetChildren()) do
		if button:IsA("ImageButton") then
			button.Visible = bool
			button.Selectable = bool
			button.Active = bool
		end
	end
	
	for i,button in pairs (SelectionMenu:GetChildren()) do
		if button:IsA("ImageButton") and (string.find(button.Name, "Rarity") or string.find(button.Name, "Item")) then
			button.Active = not bool
			button.Selectable = not bool
		end
	end
end

function OpenAffiliatedItemPreview(MenuName)
	if StorageMenu.ItemsPreview:FindFirstChild(MenuName) then
		SelectionMenu.Visible = true
		ItemsPreview.Visible = true
		
		SelectionMenu.SelectItem.Active = true
		SelectionMenu.NextItem.Active = true
		SelectionMenu.PreviousItem.Active = true
		SelectionMenu.NextRarity.Active = true
		SelectionMenu.PrevRarity.Active = true
		
		for i,menu in pairs (ItemsPreview:GetChildren()) do
			if menu:IsA("Frame") then
				if tostring(menu) == MenuName then
					menu.Visible = true
				else
					menu.Visible = false
				end
			end
		end

		ReadyItemTypeMenu(StorageMenu.ItemsPreview:FindFirstChild(MenuName))
	end
end

------------------------<|Current Selection Info|>-------------------------------------

local CurrentTile
local function UpdateSelectionInfo(Page, tile)
	local Menu = Page.Parent
	local ItemInformation = FindItemInfo(tile.ItemName.Value, tostring(Menu))
	local Discovered = tile.Discovered.Value
	local rarityName = tostring(Page.Rarity.Value)
	
	SelectionMenu.Amount.Visible = Discovered
	SelectionMenu.UnitPrice.Visible = Discovered
	SelectionMenu.Hint.Visible = not Discovered
	
	if CurrentTile ~= nil then --Unhighlight previous tile
		CurrentTile.BorderSizePixel = 1
	end
	tile.BorderSizePixel = 2 --Change now selected tile to
	tile.BorderColor3 = Color3.fromRGB(255, 255, 255)
	SelectionMenu.CurrentRarity.Value = rarityName
	SelectionMenu.CurrentSelection.Value = tile
	CurrentTile = tile
	
	--Rarity Coloring
	if SelectionMenu.RarityDisplay.CurrentRarity.Text ~= rarityName then
		SelectionMenu.RarityDisplay.CurrentRarity.Text = rarityName
		local RarityInfo = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(rarityName)

		local NewGradient1 = RarityInfo.RarityGradient:Clone()
		if SelectionMenu.RarityDisplay.CurrentRarity:FindFirstChild("RarityGradient") then
			SelectionMenu.RarityDisplay.CurrentRarity.RarityGradient:Destroy()
		end
		NewGradient1.Parent = SelectionMenu.RarityDisplay.CurrentRarity

		local NewGradient2 = RarityInfo.RarityGradient:Clone()
		if SelectionMenu.RarityFrame:FindFirstChild("RarityGradient") then
			SelectionMenu.RarityFrame.RarityGradient:Destroy()
		end
		NewGradient2.Parent = SelectionMenu.RarityFrame

		SelectionMenu.Picture.BorderColor3 = RarityInfo.Value
		SelectionMenu.Picture.BackgroundColor3 = RarityInfo.TileColor.Value
		SelectionMenu.RarityFrame.BorderColor3 = RarityInfo.Value
		SelectionMenu.RarityFrame.BackgroundColor3 = RarityInfo.TileColor.Value
	end
	
	if Discovered == true then
		--SelectionMenu.Picture.Image = ItemInformation["GUI Info"].StatImage.Value
		--SelectionMenu.Picture.Visible = true
		--SelectionMenu.LockPicture.Visible = false
		--print(SelectionMenu.Picture, ItemInformation:Clone(), true, ItemInformation["GUI Info"].DisplayAngle.Value)
		GuiUtility.Display3DModels(Player, SelectionMenu.Picture, ItemInformation:Clone(), true, ItemInformation["GUI Info"].DisplayAngle.Value)
		
		SelectionMenu.Picture.BackgroundColor3 = SelectionMenu.RarityFrame.BackgroundColor3
		SelectionMenu.DisplayName.Text = tile.ItemName.Value
		SelectionMenu.Amount.Text = tostring(tile.AmountInStorage.Value)
		SelectionMenu.UnitPrice.Text = tostring(ItemInformation.CurrencyValue.Value)
		--SelectionMenu.Description.Text = 
		
		--Enabled Button
		if SelectionMenu.SelectItem.Image ~= "rbxassetid://6760390045" then
			SelectionMenu.SelectItem.Active = true
			SelectionMenu.SelectItem.Image = "rbxassetid://6760390045"
			SelectionMenu.SelectItem.HoverImage = "rbxassetid://6760391957"
			SelectionMenu.SelectItem.PressedImage = "rbxassetid://6760411821"
		end
		ManageSellMenu(false)
		
		tile.AmountInStorage.Changed:Connect(function()
			if tile == SelectionMenu.CurrentSelection.Value then
				SelectionMenu.Amount.Text = tostring(tile.AmountInStorage.Value)
			end
		end)
	else --Item not discovered
		--SelectionMenu.LockPicture.Image = "rbxassetid://6741669069"
		--SelectionMenu.Picture.Visible = false
		--SelectionMenu.LockPicture.Visible = true
		--SelectionMenu.LockPicture.BackgroundColor3 = Color3.fromRGB(5, 16, 29)
		GuiUtility.Display3DModels(Player, SelectionMenu.Picture, game.ReplicatedStorage.GuiElements.LockedBlock:Clone(), true, ItemInformation["GUI Info"].DisplayAngle.Value)
		SelectionMenu.Picture.BackgroundColor3 = Color3.fromRGB(5, 16, 29)
		SelectionMenu.DisplayName.Text = "[UnDiscovered]"
		SelectionMenu.Amount.Text = "?"
		SelectionMenu.UnitPrice.Text = "?"
		SelectionMenu.Hint.Text = "Hint: " .. tostring(ItemInformation["GUI Info"])
		
		--Disabled Button
		if SelectionMenu.SelectItem.Image ~= "rbxassetid://6760430013" then
			SelectionMenu.SelectItem.Active = false
			SelectionMenu.SelectItem.Image = "rbxassetid://6760430013"
			SelectionMenu.SelectItem.HoverImage = "rbxassetid://6760430013"
			SelectionMenu.SelectItem.PressedImage = "rbxassetid://6760430013"
		end
	end
end

local function UpdateTileLock(tile, StatValue, RarityName)
	if StatValue == true then
		tile.LockImage.Visible = false
		tile.Picture.Visible = true
		local RarityInfo = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(RarityName)
		tile.BackgroundColor3 = RarityInfo.TileColor.Value
	else
		tile.LockImage.Visible = true
		tile.Picture.Visible = false
		tile.BackgroundColor3 = Color3.fromRGB(5, 16, 29)
	end
end

------------------------<|Tile Selection Buttons|>------------------------------------

local CurrentMenu
function ReadyItemTypeMenu(Menu)
	CurrentMenu = Menu
	
	for i,page in pairs (Menu:GetChildren()) do
		if page:IsA("Frame") then
			for i,tile in pairs (page:GetChildren()) do
				if tile:IsA("TextButton") then
					tile.BorderSizePixel = 1
				end
			end
		end
	end
	
	for i,tile in pairs (Menu.Page1:GetChildren()) do
		if (tile:IsA("TextButton") or tile:IsA("ImageButton")) and string.find(tile.Name, "Slot") then
			local tileNumber = string.gsub(tile.Name, "Slot", "")
			if tileNumber == "1" then --Select first common item (for first menu open, tiles never switched yet)
				local discovered = tile.Discovered.Value
				local itemInfo = FindItemInfo(tostring(tile), tostring(Menu))

				SelectionMenu.CurrentSelection.Value = tile
				SelectionMenu.CurrentRarity.Value = "Common"
				SelectionMenu.UnitPrice.Visible = discovered
				SelectionMenu.Hint.Visible = not discovered

				if itemInfo then
					UpdateSelectionInfo(Menu.Common, tile)
				end
			end
		end
	end
end

--CurrentMenu = "Materials"
SelectionMenu.NextItem.Activated:Connect(function()
	MoveToTile(CurrentMenu, 1)
end)

SelectionMenu.PreviousItem.Activated:Connect(function()
	MoveToTile(CurrentMenu, -1)
end)

SelectionMenu.NextRarity.Activated:Connect(function()
	MoveToTile(CurrentMenu, nil, 1)
end)

SelectionMenu.PrevRarity.Activated:Connect(function()
	MoveToTile(CurrentMenu, nil, -1)
end)

local SellItem = eventsFolder.Utility:WaitForChild("SellItem")

local function DisplaySellMenuElements(bool, bool2, ItemName)
	SellMenu.Visible = bool
	StorageMenu.CloseSellMenu.Visible = bool
	StorageMenu.SellButton.Visible = bool
	for i,gui in pairs (SellMenu:GetChildren()) do
		if not gui:IsA("NumberValue") and not gui:IsA("ObjectValue") and not string.find(gui.Name, "Constraint") then
			gui.Visible = bool
		end
	end
	
	local EmptyNotifier = StorageMenu.EmptyNotifier
	EmptyNotifier.Visible = bool2
	if ItemName then
		EmptyNotifier.Text = string.gsub(EmptyNotifier.Text, "ITEM", ItemName)
	end
	
	SellMenu.TotalAmount.Text = tostring(SellMenu.MaxAmount.Value)
end

SelectionMenu.SelectItem.Activated:Connect(function()
	if SelectionMenu.Visible == true then
		SelectionMenu.SelectItem.Active = false
		SelectionMenu.SelectItem.Selectable = false
		
		local itemTile = SelectionMenu.CurrentSelection.Value
		local itemAmount = tonumber(SelectionMenu.Amount.Text)
		local itemName = itemTile.ItemName.Value
		SellMenu.MaxAmount.Value = itemAmount
		
		local ItemInfo = FindItemInfo(itemName, tostring(CurrentMenu))
		if ItemInfo then
			SellMenu.SelectedItem.Value = ItemInfo
			ManageSellMenu(true)
			
			
			if itemAmount > 0 then
				SellMenu.SnapAmount.Value = math.ceil(SellMenu.SliderBar.AbsoluteSize.X/(itemAmount)) --+1 for 0th
				--SellMenu.SellAll.Text = "Sell All: $" .. tostring(tonumber(ItemAmount*SellMenu.SelectedItem.Value.CurrencyValue.Value))
				
				DisplaySellMenuElements(true, false)
				CalculateSliderPosition()
			else
				DisplaySellMenuElements(false, true, itemName)
				wait(2)
				ManageSellMenu(false)
				StorageMenu.EmptyNotifier.Text = string.gsub(StorageMenu.EmptyNotifier.Text, itemName, "ITEM")
			end
		end
	end
end)

local function ChangeToTileInMenu(Page, seekedTileSlot)
	local newTile
	if seekedTileSlot == -1 then --last tile of page
		local pageTileCount = 0
		for i,tile in pairs (Page:GetChildren()) do
			if (tile:IsA("TextButton") or tile:IsA("ImageButton")) and string.find(tile.Name, "Slot") then
				 pageTileCount += 1
			end
		end
		seekedTileSlot = pageTileCount
	end
	
	for i,tile in pairs (Page:GetChildren()) do
		if (tile:IsA("TextButton") or tile:IsA("ImageButton")) and string.find(tile.Name, "Slot") then
			local tileSlotCount = string.gsub(tile.Name, "Slot", "")
			if tonumber(tileSlotCount) == seekedTileSlot then
				UpdateSelectionInfo(Page, tile)
			end
		end
	end
end

function MoveToTile(Menu, tileDirection, rarityDirection)
	--amount is for tile change direction
	--RaritySkip is rarity change direction
	
	if SelectionMenu.Visible == true then
		local currentTile = SelectionMenu.CurrentSelection.Value
		local tileNumber = string.gsub(currentTile.Name, "Slot", "")
		tileNumber = tonumber(tileNumber)
		
		local currentPage = currentTile.Parent
		local pageNumber = string.gsub(currentPage.Name, "Page", "")
		pageNumber = tonumber(pageNumber)

		--Tile Count on page
		local pageTileCount = 0
		for i,tile in pairs (currentPage:GetChildren()) do
			if tile:IsA("TextButton") then
				pageTileCount += 1
			end
		end

		local pageCount = GetHighPage(Menu)
		
		local currentPage = Menu:FindFirstChild("Page" .. tostring(pageCount))
		local changedToPage
		if tileDirection then --change tile selection
			if tileNumber + tileDirection > pageTileCount or tileNumber + tileDirection <= 0 then			
				if pageNumber + tileDirection > pageCount then 
					changedToPage = Menu.Page1
					ChangeToTileInMenu(Menu.Page1, 1) --Moving to start of first page
				elseif pageNumber + tileDirection <= 0 then
					changedToPage = Menu:FindFirstChild("Page" .. tostring(pageCount))
					ChangeToTileInMenu(Menu:FindFirstChild("Page" .. tostring(pageCount)), 0)--Moving to end of last page
				else
					changedToPage = Menu:FindFirstChild("Page" .. tostring(pageNumber + tileDirection))
					ChangeToTileInMenu(changedToPage, tileDirection)
				end
			else --Move to next/prev tile
				ChangeToTileInMenu(currentPage, tileNumber + tileDirection)
			end
		elseif rarityDirection then
			if pageNumber + rarityDirection > pageCount or pageNumber + rarityDirection <= 0 then
				if rarityDirection == 1 then
					changedToPage = Menu.Page1
					ChangeToTileInMenu(Menu.Page1, 1) --Moving to first page
				else
					changedToPage = Menu:FindFirstChild("Page" .. tostring(pageCount))
					ChangeToTileInMenu(Menu:FindFirstChild("Page" .. tostring(pageCount)), 1) --Moving to last page
				end
			else --Move to next/prev page
				changedToPage = Menu:FindFirstChild("Page" .. tostring(pageNumber + rarityDirection))
				ChangeToTileInMenu(Menu:FindFirstChild("Page" .. tostring(pageNumber + rarityDirection)), 1)
			end
		end
		
		if changedToPage then
			currentPage.Visible = false
			changedToPage.Visible = true
			
			--*****do a tween effect depending on the direction of the change
		end
	end
end

---------------------------<|SellMenu Slider Interaction|>---------------------------------------

local sliderBar = SellMenu.SliderBar
local slider = sliderBar:WaitForChild("Slider")
local movingSlider = false
local Mouse = game.Players.LocalPlayer:GetMouse()

slider.MouseButton1Down:Connect(function()
	movingSlider = true
end)
slider.MouseButton1Up:Connect(function()
	movingSlider = false
end)
Mouse.Button1Up:Connect(function()
	movingSlider = false
end)

if SelectionMenu.Visible == true then
	Mouse.Move:Connect(function()
		if movingSlider == true then
			CalculateSliderPosition()
		end
	end)
	
	SellMenu.SelectedAmount.FocusLost:Connect(function(enterPressed, otherInput)
		if tonumber(SellMenu.SelectedAmount.Text) > SellMenu.MaxAmount.Value then
			SellMenu.SelectedAmount.Text = tostring(SellMenu.MaxAmount.Value)
		elseif tonumber(SellMenu.SelectedAmount.Text) < 0 then
			SellMenu.SelectedAmount.Text = "0"
		end
		print(SellMenu.MaxAmount.Value)
		print(SellMenu.SelectedAmount.Text)
		CalculateSliderPosition(tonumber(SellMenu.SelectedAmount.Text)) 
	end)
end


local snapAmount
local amountToSellPercent
function CalculateSliderPosition(amount)
	local Percentage
	if amount == nil then
		local xOffsetClamped
		snapAmount = SellMenu.SnapAmount.Value
		local xOffset = math.floor((Mouse.X - sliderBar.AbsolutePosition.X) / snapAmount) * snapAmount
		xOffsetClamped = math.clamp(xOffset, 0, sliderBar.AbsoluteSize.X - slider.AbsoluteSize.X) --pos, min, max

		local sliderPosNew = UDim2.new(0, xOffsetClamped, slider.Position.Y.Scale, 0) --Snap slider bar in place
		slider.Position = sliderPosNew
		
		local roundedAbsSize = math.ceil(sliderBar.AbsoluteSize.X / snapAmount) * snapAmount or 0
		local roundedOffsetClamped = (xOffsetClamped / snapAmount) * snapAmount --highest amount slider can achieve
		Percentage = roundedOffsetClamped / roundedAbsSize
	else
		Percentage = amount/SellMenu.MaxAmount.Value
		slider.Position = UDim2.new(Percentage - slider.Size.X.Scale/2, 0, slider.Position.Y.Scale, 0)
	end
	
	amountToSellPercent = Percentage
	local GUIamountToSell = math.ceil(Percentage*SellMenu.MaxAmount.Value)

	SellMenu.SelectedAmount.Text = tostring(GUIamountToSell)
	SellMenu.CashValue.Text = "$" .. tostring(SellMenu.SelectedItem.Value.CurrencyValue.Value*GUIamountToSell)
end

SellMenu.Parent.SellButton.Activated:Connect(function()
	local ItemInfo = tostring(SellMenu.SelectedItem.Value) --Keep as string to prevent RS exploiting
	SellItem:FireServer(CurrentMenu, ItemInfo, amountToSellPercent)
	wait(0.2)
	ManageSellMenu(false)
	
	--Possibly do a statValue vs MaxAmount check to see if certain player is exploiting
	--maybe have a saved stat in each player that is amount of exploiter warnings. If exploiter warnings count is too high, they
	--will be notified&kicked/banned
	
	--******Sell GUI animation*********
end)

--SellMenu.SellAll.Activated:Connect(function()
	--local ItemInfo = SellMenu.SelectedItem.Value
	--SellItem:FireServer(CurrentMenu, ItemInfo, 1)
	--ManageSellMenu(false)
	
	--Sell GUI animation
--end)

StorageMenu.CloseSellMenu.Activated:Connect(function()
	ManageSellMenu(false)
end)

---------------------------<|Storage Menu Tile Management|>-------------------------------------------

local tilesPerRow = 5 --this number was 10 with old sorting
local tilesPerPage = 20
function ManageStorageTiles(MenuName)
	ItemsPreview.Visible = false
	if ItemsPreview:FindFirstChild(MenuName) then
		local itemMenu = ItemsPreview:FindFirstChild(MenuName)
		
		local itemDataFolder
		for i,location in pairs (game.ReplicatedStorage.ItemLocations:GetChildren()) do
			if string.find(location:GetAttribute("ItemTypesPresent"), tostring(MenuName)) then
				for i,item in pairs (location:GetChildren()) do
					if string.gsub(item.Bag.Value, "Bag", "") .. "s" == tostring(MenuName) then
						itemDataFolder = location
					end
				end
			end
		end	
		
		local tycoonStorageTile = game.ReplicatedStorage.GuiElements.TycoonStorageTile
		
		if itemDataFolder then
			for i,item in pairs (itemDataFolder:GetChildren()) do --make tile for every item
				local itemRarity = item["GUI Info"].RarityName.Value
				local rarityInfo = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(itemRarity)
				local orderValue = rarityInfo.Order.Value
				
				local pageCount = GetHighPage(itemMenu)
				
				local Page
				if pageCount > 0 then
					local highRarityPage = GetHighPage(itemMenu, itemRarity)
					
					print("High rarity page for " .. itemRarity .. " is " .. tostring(highRarityPage))
					if highRarityPage > 0 then --page found, check slot availability
						local possiblePage = itemMenu:FindFirstChild("Page" .. tostring(highRarityPage))
						
						local tileCount = 0
						for i,tile in pairs (possiblePage:GetChildren()) do
							if (tile:IsA("ImageButton") or tile:IsA("TextButton")) and string.find(tile.Name, "Slot") then
								tileCount += 1
							end
						end
						
						if tileCount >= tilesPerPage then
							Page = FinalizePageCreation(itemMenu, rarityInfo, highRarityPage, 1)
						else
							Page = possiblePage
						end
					else --no page with item's rarity, make new page

						local insertDirection
						local referencePageNumber
						local rarityReferenceFound = false
						for i,page in pairs (itemMenu:GetChildren()) do
							if rarityReferenceFound then --close in on "edge" page
								if page.Rarity.Value == itemMenu:FindFirstChild("Page" .. tostring(referencePageNumber)) then
									local pageNumber = string.gsub(page.Name, "Page", "")
									if page.Rarity.Value.Order.Value > rarityInfo.Order.Value then
										if tonumber(pageNumber) < referencePageNumber then
											referencePageNumber = tonumber(pageNumber) --higher rarity, look for lowest of high
										end
									else
										if tonumber(pageNumber) > referencePageNumber then
											referencePageNumber = tonumber(pageNumber) --lower rarity, look for highest of low
										end
									end
								end
								
							else
								local lesserRarityPage,lesserRarityName = FindNearbyRarity(itemMenu, rarityInfo, orderValue, -1)
								if lesserRarityPage then
									rarityReferenceFound = true
									referencePageNumber = lesserRarityPage
									insertDirection = 1
								else
									local higherRarityPage,higherRarityName = FindNearbyRarity(itemMenu, rarityInfo, orderValue, 1)
									if higherRarityPage then
										rarityReferenceFound = true
										referencePageNumber = higherRarityPage
										insertDirection = 0 --is 0 for page creation
									end
								end
							end
						end
						
						if referencePageNumber then
							--print("Using another page (Page ", referencePageNumber, ") with rarity ", referenceRarityName, " and insertion direction ", insertDirection, " for a tile that is rarity ", rarityInfo)
							Page = FinalizePageCreation(itemMenu, rarityInfo, referencePageNumber, insertDirection)
						end
					end
				else --no pages, make first
					Page = FinalizePageCreation(itemMenu, rarityInfo, 0, 1)
				end
				
				--Finally, position tile onto page
				local slotCount = 0
				for i,slot in pairs (Page:GetChildren()) do
					if (slot:IsA("ImageButton") or slot:IsA("TextButton")) and string.find(slot.Name, "Slot") then
						local slotNumber = string.gsub(slot.Name, "Slot", "")
						if tonumber(slotNumber) > slotCount then
							slotCount = tonumber(slotNumber)
						end
					end
				end
				
				local newTile = tycoonStorageTile:Clone()
				newTile.Parent = Page
				newTile.Name = "Slot" .. tostring(slotCount + 1)
				newTile.ItemName.Value = tostring(item)
				
				local columnValue, rowValue = GuiUtility.SlotCountToXY(slotCount, tilesPerRow)
				newTile.Position = UDim2.new(0.021+0.204*columnValue, 0, 0.153+0.176*rowValue, 0)
				newTile.Size = UDim2.new(0.175, 0, 0.148, 0)
				
				newTile.Activated:Connect(function()
					UpdateSelectionInfo(Page, newTile)
				end)
			end
			
			itemMenu.Page1.Visible = true
		end
	end
end

						
		--[[
		if ItemDataFolder then
			for i,item in pairs (ItemDataFolder:GetChildren()) do
				local ItemType = string.gsub(item.Bag.Value, "Bag", "") .. "s"
				if ItemType == MenuName then
					local ItemRarity = item["GUI Info"].RarityName.Value
					--local RarityMenu = AffiliatedItemsPreview:FindFirstChild(ItemRarity)
					local RarityChildCount = 0
					local PrevTile
					for i,tile in pairs (RarityMenu:GetChildren()) do
						if tile:IsA("TextButton") then
							if tile.SlotNumber.Value > RarityChildCount then
								RarityChildCount = tile.SlotNumber.Value
								PrevTile = tile
							end
						end
					end
					local RarityInfo = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(ItemRarity)
					
					local NewTile = TycoonStorageTile:Clone()
					NewTile.SlotNumber.Value = RarityChildCount + 1
					NewTile.Name = tostring(item)
					NewTile.BackgroundColor3 = RarityInfo.TileColor.Value
					NewTile.BorderColor3 = RarityInfo.Value
					NewTile.Picture.Image = item["GUI Info"].StatImage.Value --Put in check for discovered remotefunction for image/lock
					
					NewTile.Parent = RarityMenu
					
					if RarityChildCount == 0 then
						NewTile.Position = UDim2.new(0.05, 0, 1, 0)
						MoveOtherRaritiesDown(RarityMenu)
						
					elseif (RarityChildCount)/AmountPerRow ~= math.floor(RarityChildCount/AmountPerRow) then
						NewTile.Position = UDim2.new(PrevTile.Position.X.Scale + .3, 0, PrevTile.Position.Y.Scale, 0)
						
					elseif RarityChildCount/AmountPerRow == math.floor(RarityChildCount/AmountPerRow) then
						--Starting a new row
						local RowStarterTile
						for i,tile in pairs (RarityMenu:GetChildren()) do
							if tile:IsA("TextButton") then
								if tile.SlotNumber.Value == NewTile.SlotNumber.Value - AmountPerRow then
									RowStarterTile = tile
								end
							end
						end
						NewTile.Position = UDim2.new(RowStarterTile.Position.X.Scale, 0, RowStarterTile.Position.Y.Scale + 1.67, 0)
						MoveOtherRaritiesDown(RarityMenu)
					end
					]]
					

------------------<|Event Functions|>-------------------------------

local UpdateTycoonStorage = eventsFolder.GUI:WaitForChild("UpdateTycoonStorage")
UpdateTycoonStorage.OnClientEvent:Connect(function(File, Stat, StatValue, AmountAdded, AcquiredLocation)
	local rarityName
	if typeof(StatValue) == "string" then
		File = string.gsub(File, "TycoonStorage", "")
		Stat = string.gsub(Stat, "TycoonStorage", "")
	else --Bool for Discovered
		wait(1)
		Stat = string.gsub(Stat, "Discovered", "")
		local itemInfo = game.ReplicatedStorage.ItemLocations:FindFirstChild(tostring(AcquiredLocation)):FindFirstChild(tostring(Stat))
		rarityName = itemInfo["GUI Info"].RarityName.Value
	end
	
	--Find tile representation of stat
	local foundTile
	for i,page in pairs (ItemsPreview:FindFirstChild(File):GetChildren()) do
		if page:IsA("Frame") and string.find(page.Name, "Page") then
			if tostring(page.Rarity.Value) == rarityName then
				for i,tile in pairs (page:GetChildren()) do
					if (tile:IsA("TextButton") or tile:IsA("ImageButton")) and string.find(tile.Name, "Slot") then
						if tile.ItemName.Value == Stat then
							foundTile = tile
						end
					end
				end
			end
		end
	end
	
	--Update info on stat
	if foundTile then
		if typeof(StatValue) == "boolean" then
			foundTile.Discovered.Value = StatValue
			UpdateTileLock(foundTile, StatValue, rarityName)
		else
			foundTile.AmountInStorage.Value = StatValue
		end
	end
end)

-------------------------------------------<|Tycoon Research GUI Functions|>-----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local ResearchMenu = ComputerScreen.ResearchMenu
local AvailableResearch = ResearchMenu.AvailableResearch
local CurrentResearch = ResearchMenu.CurrentResearch
local PreviousResearch = ResearchMenu.PreviousResearch
local CostList = ResearchMenu.CostList
local InfoMenu = ResearchMenu.InfoMenu
local ResearchersList = ResearchMenu.ResearchersList
local Taskbar = ComputerScreen.Taskbar

local CheckResearchDepends = eventsFolder.Utility:WaitForChild("CheckResearchDepends")

local PurchaseResearch = eventsFolder.Utility:WaitForChild("PurchaseResearch")
local CompleteResearch = eventsFolder.Utility:WaitForChild("CompleteResearch")

local SelectedResearch
local SelectedResearchType

MenuSelect.ResearchMenuButton.Activated:Connect(function()
	ResearchMenu.Visible = true
	CurrentResearch.Visible = true
	ResearchersList.Visible = true
	AvailableResearch.Visible = true
	ResearchersList.AvailableResearchPages.Visible = true
	
	Taskbar.PreviousResearchButton.Visible = true
	Taskbar.PreviousResearchButton.Active = true
	Taskbar.CurrentResearchButton.Visible = false
	Taskbar.CurrentResearchButton.Active = false
	
	PreviousResearch.Visible = false
	ResearchersList.PreviousResearchPages.Visible = false
	CostList.Visible = false
	ResearchersList.CostListPages.Visible = false
	InfoMenu.Visible = false
	
	ResetPageOrder(AvailableResearch)
	ResetPageOrder(PreviousResearch)
	CostList.CurrentPage.Value = 1
	
	ResearchersList.InfoMenuLabel.Visible = false
	ResearchersList.CostMenuLabel.Visible = false
	ResearchersList.CurrentMenuLabel.Visible = true
	ResearchersList.AvailableMenuLabel.Visible = true
	ResearchersList.PreviousMenuLabel.Visible = false
	
	UpdatePageDisplay(AvailableResearch, true)
	UpdatePageDisplay(PreviousResearch, false)
	UpdatePageDisplay(CostList, false)
	
	MenuSelect.Visible = false
	BeepSound:Play()
end)

local function CalculateGemCost(FinishTime)
	local SecondsLeft = FinishTime - os.time()
	local h = SecondsLeft/3600

	local GemCost
	if h < 1 then
		GemCost = math.ceil(16.296*h)
	elseif 1 <= h <= 24 then
		GemCost = math.ceil(8.491*h + 7.8053)
	elseif 24 < h then
		GemCost = math.ceil(4.189*h + 111.0432)
	end
	
	return GemCost
end

------------------------<|Time Management|>-----------------------------

local function toDHMS(Sec, TileTimePreview)
	local Days = math.floor(Sec/(24*3600))
	local Hours = math.floor(Sec%(24 * 3600) / 3600)
	local Minutes = math.floor(Sec/60%60)
	local Seconds = Sec%60
	
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
			elseif Display3 == nil and TileTimePreview then --Preview is more exact
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

local function ManageTileTimer(Tile, ResearchData, FinishTime)
	local ProgressBar = Tile.TimerBar.ProgressBar
	ProgressBar.SkipTime.Visible = true
	ProgressBar.SkipTime.Active = true
	ProgressBar.CompleteResearch.Visible = false
	ProgressBar.CompleteResearch.Active = false
	
	coroutine.resume(coroutine.create(function()
		while Tile do
			wait(1) --update every second
			if os.time() <= FinishTime then
				local SecondsLeft = FinishTime - os.time()
				local RoundedPercentage = math.ceil(100 * (1 - (SecondsLeft / ResearchData["Research Length"])))
				local PercentFinished = RoundedPercentage/100
						
				ProgressBar.Timer.Text = toDHMS(SecondsLeft)
				ProgressBar.Progress:TweenSize(UDim2.new(PercentFinished, 0, 1, 0), "Out", "Quint", 0.8)

				local GemCost = CalculateGemCost(FinishTime)
				ProgressBar.SkipTime.PaymentAmount.Text = GuiUtility.ConvertShort(GemCost)
				
				
				--SOME EFFECT TO LOOK LIKE PROGRESS IS BEING MADE, EVEN WITH HUGE TIMERS (something moving)?
				--Some gradient shine effect for progress bar? (like windows progress bar)
				--Rotate hand on clock to left of progress bar (like CoC timer, 4 points it rotates two going around)
			else
				ProgressBar.Progress.Size = UDim2.new(1, 0, 1, 0)
				ProgressBar.Timer.Text = "Completed!"
				
				ProgressBar.SkipTime.Visible = false
				ProgressBar.SkipTime.Active = false
				ProgressBar.CompleteResearch.Visible = true
				ProgressBar.CompleteResearch.Active = true

				break
			end
		end
	end))
end

-----------------------<|Tile Info Functions|>-----------------------

local function ChangeCostColor(Tile, PlayerAmount, Cost)
	if PlayerAmount >= Cost then
		Tile.ResearchCost.TextColor3 = Color3.fromRGB(85, 255, 0)
	else
		Tile.ResearchCost.TextColor3 = Color3.fromRGB(208, 0, 0)
	end
end

local function ColorTileRarity(Tile, RarityInfo)
	local Main = RarityInfo.Value
	local Accent = RarityInfo.TileColor.Value
	
	Tile.Parent.BorderColor3 = Main
	Tile.DisplayImage.BorderColor3 = Main
	Tile.RarityFrame.BorderColor3 = Main
	Tile.RarityFrame.BackgroundColor3 = Accent
	Tile.DisplayImage.BackgroundColor3 = Accent
	RarityInfo.RarityGradient:Clone().Parent = Tile.Parent
	RarityInfo.RarityGradient:Clone().Parent = Tile.RarityFrame
end

local function InsertTileInfo(Menu, Tile, ResearchData, ResearchType, FinishTime, StatTable)
	if StatTable == nil then --Available and Previous Research
		Tile.ResearchTile.Visible = true
		Tile.CostTile.Visible = false
		local ResearchTile = Tile.ResearchTile
		
		ResearchTile.ResearchName.Text = ResearchData["Research Name"]
		ResearchTile.ResearchType.Text = ResearchType
		ColorTileRarity(ResearchTile, Tile.Rarity.Value)
		
		if FinishTime then
			ResearchTile.ResearchTime.Visible = false
			ResearchTile.ResearchType.Visible = false
			ResearchTile.TimerBar.Visible = true
			ResearchTile.TimerSymbol.Visible = true
			ManageTileTimer(ResearchTile, ResearchData, FinishTime)
		else
			ResearchTile.TimerBar.Visible = false
			ResearchTile.TimerSymbol.Visible = false
			ResearchTile.ResearchTime.Visible = true
			ResearchTile.ResearchType.Visible = true
			ResearchTile.ResearchTime.Text = toDHMS(ResearchData["Research Length"], true)
		end
		
		if Menu ~= PreviousResearch then
			local TileDebounce = false
			Tile.Activated:Connect(function()
				if TileDebounce == false then
					TileDebounce = true

					ResearchersList.InfoMenuLabel.Visible = true
					ResearchersList.CostMenuLabel.Visible = true
					ResearchersList.CurrentMenuLabel.Visible = false
					ResearchersList.AvailableMenuLabel.Visible = false
					ResearchersList.PreviousMenuLabel.Visible = false
					
					UpdatePageDisplay(AvailableResearch, false)
					UpdatePageDisplay(PreviousResearch, false)
					UpdatePageDisplay(CostList, true)

					--Delete Previous Tiles
					for i,page in pairs (CostList:GetChildren()) do
						if page:IsA("Frame") and string.find(page.Name, "Page") then
							page:Destroy()
						end
					end

					--Insert experience and material costs into cost list
					for i,expRequire in pairs (ResearchData["Experience Cost"]) do
						ManageResearchTile(CostList, ResearchData, ResearchType, nil, expRequire)
					end
					
					for i,matRequire in pairs (ResearchData["Material Cost"]) do
						ManageResearchTile(CostList, ResearchData, ResearchType, nil, matRequire)
					end
					
					CostList.Visible = true
					InfoMenu.Visible = true
					AvailableResearch.Visible = false
					CurrentResearch.Visible = false
					PreviousResearch.Visible = false
					
					if CostList:FindFirstChild("Page1") then
						CostList.Page1.Visible = true
					end
					
					Taskbar.CurrentResearchButton.Visible = false
					Taskbar.CurrentResearchButton.Active = false
					Taskbar.PreviousResearchButton.Visible = false
					Taskbar.PreviousResearchButton.Active = false
					
					local NameCharacterCount = string.len(ResearchData["Research Name"])
					if NameCharacterCount > 20 then
						local ShortResearchName = string.sub(ResearchData["Research Name"], 1, 20) .. "..."
						InfoMenu.ResearchName.Text = ShortResearchName
					else
						InfoMenu.ResearchName.Text = ResearchData["Research Name"]
					end
					
					InfoMenu.DisplayImage.Image = ResearchData["Research Image"]
					InfoMenu.ResearchType.Text = ResearchType
					InfoMenu.ResearchTime.Text = toDHMS(ResearchData["Research Length"], true)
					
					--change size of description box based on character count
					local NameCharacterCount = string.len(ResearchData["Description"])
					local NewYScale = math.ceil(NameCharacterCount/37)*.069
					InfoMenu.Description.Size = UDim2.new(InfoMenu.Description.Size.X.Scale, 0, NewYScale, 0)
					InfoMenu.Description.Text = ResearchData["Description"]
					
					InfoMenu.Rarity.Text = ResearchData["Rarity"]
					local RarityInfo = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(ResearchData["Rarity"])
					InfoMenu.RarityFrame.BackgroundColor3 = RarityInfo.TileColor.Value
					InfoMenu.RarityFrame.BorderColor3 = RarityInfo.Value
					InfoMenu.DisplayImage.BackgroundColor3 = RarityInfo.TileColor.Value
					InfoMenu.DisplayImage.BorderColor3 = RarityInfo.Value
					
					if InfoMenu.RarityFrame:FindFirstChild("RarityGradient") then
						InfoMenu.RarityFrame.RarityGradient:Destroy()
					end
					local RarityFrameGradient = RarityInfo.RarityGradient:Clone()
					RarityFrameGradient.Parent = InfoMenu.RarityFrame
					RarityFrameGradient.Rotation = -90
					
					if InfoMenu.Rarity:FindFirstChild("RarityGradient") then
						InfoMenu.Rarity.RarityGradient:Destroy()
					end
					RarityInfo.RarityGradient:Clone().Parent = InfoMenu.Rarity
					
					TileDebounce = false
				end
			end)
		end
	else --Material Tile
		Tile.ResearchTile.Visible = false
		Tile.CostTile.Visible = true
		local CostTile = Tile.CostTile
		
		local StatInfo = StatTable[1]
		local StatAmount = StatTable[2]
		local Discovered = false
		
		local StatType
		if StatInfo:FindFirstChild("Levels") then --ExpRequirement
			StatType = tostring(StatInfo.Parent)
			StatAmount = "Level " .. tostring(StatAmount) 
			Discovered = true
			
			local PlayerLevel = GetCurrentSkillLevel:InvokeServer(StatInfo)
			ChangeCostColor(CostTile, PlayerLevel, StatTable[2])
		else
			StatType = string.gsub(StatInfo.Bag.Value, "Bag", "") .. "s"

			local RarityName = tostring(Tile.Rarity.Value)
			Discovered = ItemsPreview:FindFirstChild(StatType):FindFirstChild(RarityName):WaitForChild(tostring(StatInfo)).Discovered.Value
			
			local PlayerItemCount = GetItemCountSum:InvokeServer(tostring(StatInfo))
			ChangeCostColor(CostTile, PlayerItemCount, StatAmount)
			StatAmount = GuiUtility.ConvertShort(StatAmount) --simplify for display
		end
		CostTile.StatType.Text = StatType
		CostTile.ResearchCost.Text = StatAmount
		ColorTileRarity(CostTile, Tile.Rarity.Value)

		if not Discovered then
			CostTile.StatName.Text = "[UnDiscovered]" 
			CostTile.StatName.TextColor3 = Color3.fromRGB(204, 204, 204)
			CostTile.DisplayImage.Image = "rbxassetid://6741669069" --lock icon
			CostTile.DisplayImage.BackgroundColor3 = Color3.fromRGB(5, 16, 29)
		else
			CostTile.StatName.Text = string.gsub(tostring(StatInfo), "Skill", "")
			CostTile.DisplayImage.Image = StatInfo["GUI Info"].StatImage.Value
			
			--local TileDebounce = false
			--Tile.Activated:Connect(function()
				--Select item in storage menu and display storage menu
			--end)
		end

	end
end

--------------------<|Research Tile Management|>---------------------

local function FindPrevAvailableTile(ResearchData)
	local Page
	local Tile
	for i,page in pairs (AvailableResearch:GetChildren()) do
		for i,tile in pairs (page:GetChildren()) do
			if tile.ResearchTile.ResearchName.Text == ResearchData["Research Name"] then
				Page = page
				Tile = tile
			end
		end
	end
	
	return Page,Tile
end

local ManageTilePlacementFunction = eventsFolder.GUI:FindFirstChild("ManageTilePlacement")

function ManageResearchTile(Menu, ResearchData, ResearchType, FinishTime, StatTable)
	if Menu == CurrentResearch and FinishTime then --Guaranteed to only be one page
		local ParentTile
		for i,outlineTile in pairs (CurrentResearch:GetChildren()) do
			if outlineTile:IsA("ImageLabel") then
				if string.find(tostring(outlineTile), "ResearchOutline") then
					if not outlineTile:FindFirstChild("ResearchSlot") and ParentTile == nil then
						ParentTile = outlineTile
					end
				end
			end
		end
		
		if ParentTile then
			local NewTile = game.ReplicatedStorage.GuiElements.ResearchSlot:Clone()
			NewTile.Name = "ResearchSlot"
			NewTile.Position = UDim2.new(0, 0, 0, 0)
			NewTile.Size = UDim2.new(1, 0, 1, 0)
			NewTile.Active = false
			NewTile.Selectable = false
			NewTile.Parent = ParentTile
			
			local RarityName = ResearchData["Rarity"]
			local RarityInfo = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(RarityName)
			NewTile.Rarity.Value = RarityInfo
			
			InsertTileInfo(Menu, NewTile, ResearchData, ResearchType, FinishTime)
			
			--Delete tile from available research menu
			local AvailPage,AvailTile = FindPrevAvailableTile(ResearchData)
			if AvailPage and AvailTile then
				CurrentResearch.Visible = true
				AvailableResearch.Visible = true
				CostList.Visible = false
				InfoMenu.Visible = false
				ManageTileTruePosition(AvailableResearch, AvailPage, AvailTile, AvailTile.TruePosition.Value, 5, -1)
			end
			
			local ProgressBar = NewTile.ResearchTile.TimerBar.ProgressBar
			ProgressBar.CompleteResearch.MouseEnter:Connect(function()
				HoverSound:Play()
			end)
			ProgressBar.CompleteResearch.Activated:Connect(function()
				CompleteResearch:FireServer(ResearchData["Research Name"], ResearchType)
			end)
			
			ProgressBar.SkipTime.MouseEnter:Connect(function()
				HoverSound:Play()
			end)
			ProgressBar.SkipTime.Activated:Connect(function()
				--Current based off CoC gem calculations
				--<1h = 16.296x
				--1<x<24 = 8.491x + 7.8053
				--24<x<inf = 4.189x + 111.0432
				
				--Move this gem calculation to a server script so value is guaranteed safe
				--(use, in local script, everytime player progress updates to update visual; however, when this button
				--is activated, the final robux purchase will be conducted by a server script)
				local SecondsLeft = FinishTime - os.time()
				local h = math.floor(SecondsLeft%(24 * 3600) / 3600) --HoursLeft
				
				local GemCost
				if h < 1 then
					GemCost = math.ceil(16.296*h)
				elseif 1 <= h <= 24 then
					GemCost = math.ceil(8.491*h + 7.8053)
				elseif 24 < h then
					GemCost = math.ceil(4.189*h + 111.0432)
				end
				
				
				--player will pay to skip time with premium currency that is bought in the
				--premium currency shop. This is because you cannot code in a robux charge,
				--you must pre set it up
			end)
		else
			warn("No tile available for a current research!",ResearchData)
		end
	else --Previous and Available Research
		--local NewTile = ManageTilePlacement(Menu, 5, ResearchData, StatTable)
		
		local RarityName
		if StatTable == nil then
			local StatInfo = ResearchData
			RarityName = StatInfo["Rarity"]
		else
			local StatInfo = StatTable[1]
			if StatInfo["GUI Info"]:FindFirstChild("RarityName") then
				RarityName = StatInfo["GUI Info"].RarityName.Value
			else
				RarityName = "DisplayFirst"
			end
		end
		local RarityInfo = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(RarityName)
		
		local NewTile = ManageTilePlacementFunction:Invoke(Menu, "Research", RarityInfo)
		NewTile.Active = true
		NewTile.Selectable = true
		InsertTileInfo(Menu, NewTile, ResearchData, ResearchType, nil, StatTable)
		
		if NewTile.Parent.Parent == CostList then
			SelectedResearch = ResearchData
			SelectedResearchType = ResearchType
		else
			SelectedResearch = nil
			SelectedResearchType = nil
		end
	end
end

local function GetTileTruePosition(Page, SlotCount, MaxTileAmount)
	local PageNumber = string.gsub(Page.Name, "Page", "")
	local TruePosition = SlotCount + ((tonumber(PageNumber) - 1) * MaxTileAmount)
	return TruePosition
end

local function GetTileSlotCount(Page, TileTruePosition, AffectingTile, Change)
	--Count other slots on page
	local SlotCount = 0
	for i,slot in pairs (Page:GetChildren()) do
		if slot:IsA("TextButton") and string.find(slot.Name, "Slot") then
			if slot.TruePosition.Value < TileTruePosition then
				if Change == -1 and slot == AffectingTile then
					SlotCount = SlotCount --When moving down, don't count tile yet to be removed from list
				else
					SlotCount += 1
				end
			end
		end
	end
	
	return SlotCount
end

function ManageTileTruePosition(Menu, Page, AffectingTile, TruePosition, MaxTileAmount, Change)
	--Change is how higher TruePosition tiles should move (up 1 or down 1)
	local PageNumber = string.gsub(Page.Name, "Page", "")
	
	for i,page in pairs (Menu:GetChildren()) do
		if page:IsA("Frame") and string.find(page.Name, "Page") then
		local CurrentPageNumber = string.gsub(page.Name, "Page", "")
			
			if tonumber(CurrentPageNumber) >= tonumber(PageNumber) then
				for i,tile in pairs (page:GetChildren()) do
					if tile:IsA("TextButton") and string.find(tile.Name, "Slot") then
						if tile.TruePosition.Value >= TruePosition then --Every tile "above" affecting tile
							local SlotCount = 0
							local Page
							
							if tile ~= AffectingTile then
								tile.TruePosition.Value += Change
								SlotCount = GetTileSlotCount(page, tile.TruePosition.Value, AffectingTile, Change)
								
								if SlotCount >= MaxTileAmount then
									if Menu:FindFirstChild("Page" .. tostring(tonumber(CurrentPageNumber) + 1)) then
										Page = Menu:FindFirstChild("Page" .. tostring(tonumber(CurrentPageNumber) + 1))
									else
										local newPage = game.ReplicatedStorage.GuiElements.ResearchPage:Clone()
										newPage.Visible = false
										newPage.Name = "Page" .. tostring(tonumber(CurrentPageNumber) + 1)
										newPage.Parent = Menu
										Page = newPage
									end
									SlotCount = 0
								elseif SlotCount < 0 then
									Page = Menu:FindFirstChild("Page" .. tostring(tonumber(CurrentPageNumber) - 1))
								else
									Page = page
								end
								tile.Name = "Slot" .. tostring(SlotCount + 1)
							else
								if Change == -1 then
									tile:Destroy()
								else
									--Will guaranteed be on this page since it was calculated earlier
									SlotCount = GetTileSlotCount(page, tile.TruePosition.Value)
									Page = page
								end
							end	
							
							if Page then
								tile.Parent = Page
								
								local PageNumber = string.gsub(Page.Name, "Page", "")
								local TruePositionValue = SlotCount + (tonumber(PageNumber)-1)*MaxTileAmount
								tile.TruePosition.Value = TruePositionValue

								tile.Position = UDim2.new(0.05, 0, 0.054+0.173*SlotCount, 0)
								tile.Size = UDim2.new(0.9, 0, 0.14, 0)
							end
						end
					end
				end
			end
		end
	end
end

--------------------<|Page Manager Functions|>------------------------

function ResetPageOrder(Menu)
	for i,page in pairs (Menu:GetChildren()) do
		if page:IsA("Frame") and string.find(page.Name, "Page") then
			page.Position = UDim2.new(0, 0, 0, 0)
			if page.Name == "Page1" then
				page.Visible = true
			else
				page.Visible = false
			end
		end
	end
	Menu.CurrentPage.Value = 1
end

function UpdatePageDisplay(Menu, bool)
	local PageDisplay = ResearchersList:FindFirstChild(tostring(Menu) .. "Pages")
	local HighPage = GetHighPage(Menu)
	
	if HighPage == 0 then
		HighPage = 1
	end
	if bool ~= nil then
		local PageManager = Taskbar:FindFirstChild(tostring(Menu) .. "PM")
		PageManager.NextPage.Active = bool
		PageManager.PreviousPage.Active = bool
		PageManager.Visible = bool
		PageDisplay.Visible = bool
	end

	PageDisplay.Text = tostring(Menu.CurrentPage.Value) .. "/" .. tostring(HighPage)
end

local function CompareHighPage(Page, HighPage)
	local PageNumber = string.gsub(Page.Name, "Page", "")
	if tonumber(PageNumber) > HighPage then
		return tonumber(PageNumber)
	else
		return HighPage
	end
end

function GetHighPage(Menu, rarityName)
	local HighPage = 0
	for i,page in pairs (Menu:GetChildren()) do
		if page:IsA("Frame") and string.find(page.Name, "Page") then
			if rarityName then
				local RarityIsPresent = false
				
				if not RarityIsPresent then
					if tostring(page.Rarity.Value) == rarityName then
						RarityIsPresent = true
					end
				end

				if RarityIsPresent then
					HighPage = CompareHighPage(page, HighPage)
				end
			else
				HighPage = CompareHighPage(page, HighPage)
			end
		end
	end
	
	return HighPage
end

local function ManagePageInvis(VisiblePage)
	for i,page in pairs (VisiblePage.Parent:GetChildren()) do
		if page:IsA("Frame") then
			if page ~= VisiblePage then
				page.Visible = false
			else
				page.Visible = true
			end
		end
	end
end

local PageDebounce = false
local function FinalizePageChange(NewPage, OldPage, NewXValue)
	NewPage.Visible = true
	OldPage:TweenPosition(UDim2.new(NewXValue, 0, 0, 0), "Out", "Quint", .4)
	NewPage:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quint", .4)
	wait(.4)

	ManagePageInvis(NewPage)
end

local function ChangePage(Menu, X1, X2, X3)
	local OldPage = Menu:FindFirstChild("Page" .. tostring(Menu.CurrentPage.Value))
	
	if PageDebounce == false then
		PageDebounce = true
		local HighPage = GetHighPage(Menu)

		if HighPage ~= 1 then
			local NewPage
			if Menu.CurrentPage.Value + 1 > HighPage then
				NewPage = Menu:FindFirstChild("Page1")
				Menu.CurrentPage.Value = 1
			else
				NewPage = Menu:FindFirstChild("Page" .. tostring(Menu.CurrentPage.Value + 1))
				Menu.CurrentPage.Value = Menu.CurrentPage.Value + 1
			end
			
			UpdatePageDisplay(Menu)
			
			if NewPage then
				NewPage.Position = UDim2.new(X1,0,0,0)
				FinalizePageChange(NewPage, OldPage, X2)
			end
			PageDebounce = false
		else --Bounce effect
			UpdatePageDisplay(Menu)
			
			Menu:FindFirstChild("Page1"):TweenPosition(UDim2.new(X3,0,0,0), "Out", "Quint", .1)
			wait(.1)
			Menu:FindFirstChild("Page1"):TweenPosition(UDim2.new(0,0,0,0), "Out" , "Bounce", .25)
			wait(.25)
			PageDebounce = false
		end
	end
end

--------------------<|Button Activations|>-------------------------------
Taskbar.PreviousResearchButton.Activated:Connect(function()
	CurrentResearch.Visible = false
	PreviousResearch.Visible = true
	UpdatePageDisplay(PreviousResearch, true)
	ResearchersList.PreviousResearchPages.Visible = true

	ResearchersList.CurrentMenuLabel.Visible = false
	ResearchersList.PreviousMenuLabel.Visible = true

	Taskbar.CurrentResearchButton.Visible = true
	Taskbar.CurrentResearchButton.Active = true
	Taskbar.PreviousResearchButton.Visible = false
	Taskbar.PreviousResearchButton.Active = false
end)

Taskbar.CurrentResearchButton.Activated:Connect(function()
	CurrentResearch.Visible = true
	PreviousResearch.Visible = false
	UpdatePageDisplay(PreviousResearch, false)
	ResearchersList.PreviousResearchPages.Visible = false

	ResearchersList.CurrentMenuLabel.Visible = true
	ResearchersList.PreviousMenuLabel.Visible = false
	
	Taskbar.CurrentResearchButton.Visible = false
	Taskbar.CurrentResearchButton.Active = false
	Taskbar.PreviousResearchButton.Visible = true
	Taskbar.PreviousResearchButton.Active = true
end)

--[[
ComputerScreen.Taskbar.ChangeResearchView.Activated:Connect(function()
	if CurrentResearch.Visible then
		CurrentResearch.Visible = false
		PreviousResearch.Visible = true
		UpdatePageDisplay(PreviousResearch, true)
		ResearchersList.PreviousResearchPages.Visible = true
		
		ResearchersList.CurrentMenuLabel.Visible = false
		ResearchersList.PreviousMenuLabel.Visible = true
		
		Taskbar.CurrentResearch.Visible = false
		Taskbar.CurrentResearch.Active = false
		Taskbar.PreviousResearch.Visible = true
		Taskbar.ChangeResearchView.ButtonLabel.Text = "Current Research"
	else
		CurrentResearch.Visible = true
		PreviousResearch.Visible = false
		UpdatePageDisplay(PreviousResearch, false)
		ResearchersList.PreviousResearchPages.Visible = false
		
		ResearchersList.CurrentMenuLabel.Visible = true
		ResearchersList.PreviousMenuLabel.Visible = false
		Taskbar.ChangeResearchView.ButtonLabel.Text = "Previous Research"
	end
end)
]]

InfoMenu.ResearchButton.Activated:Connect(function()
	InfoMenu.ResearchButton.Active = false
	--Disable research button and reenable it when event is fired back to client
	
	PurchaseResearch:FireServer(SelectedResearch["Research Name"], SelectedResearchType)
	
	
end)

Taskbar.AvailableResearchPM.NextPage.Activated:Connect(function()
	ChangePage(AvailableResearch, 1, -1, 0.02)
end)

Taskbar.AvailableResearchPM.PreviousPage.Activated:Connect(function()
	ChangePage(AvailableResearch, -1, 1, -0.02)
end)

Taskbar.PreviousResearchPM.NextPage.Activated:Connect(function()
	ChangePage(PreviousResearch, 1, -1, 0.02)
end)

Taskbar.PreviousResearchPM.PreviousPage.Activated:Connect(function()
	ChangePage(PreviousResearch, -1, 1, -0.02)
end)

Taskbar.CostListPM.NextPage.Activated:Connect(function()
	ChangePage(CostList, 1, -1, 0.02)
end)

Taskbar.CostListPM.PreviousPage.Activated:Connect(function()
	ChangePage(CostList, -1, 1, -0.02)
end)

--------------------<|Event Functions|>------------------------------
local UpdateResearch = eventsFolder.GUI:WaitForChild("UpdateResearch")
UpdateResearch.OnClientEvent:Connect(function(ResearchData, ResearchType, Completed, Purchased, FinishTime, Researchers)
	if Researchers == nil then
		if Purchased and Completed then --Previous
			ManageResearchTile(PreviousResearch, ResearchData, ResearchType)
		elseif Purchased and not Completed then --Current
			ManageResearchTile(CurrentResearch, ResearchData, ResearchType, FinishTime)
		else --Check If Can Be Available
			local AllDependenciesMet = CheckResearchDepends:InvokeServer(ResearchData)
			if AllDependenciesMet then
				ManageResearchTile(AvailableResearch, ResearchData, ResearchType)
			end	
		end
	else
		for slot = 1,5 do
			if slot <= Researchers then
				CurrentResearch:FindFirstChild("ResesarchOutline" .. tostring(slot)).Visible = true
			else
				CurrentResearch:FindFirstChild("ResesarchOutline" .. tostring(slot)).Visible = false
			end
		end
		
	end
end)

PurchaseResearch.OnClientEvent:Connect(function(ResearchData) --Error with purchase
	if ResearchData then
		print("Player can afford to purchase this research")
		
		--put tile in current research and remove from available, moving the tiles below the
		--up visually, but down in trueposition
		--reenable button
	else	
		print("Player cannot afford this research")
		--Warning message
		--reenable button
	end
	InfoMenu.ResearchButton.Active = true
end)

CompleteResearch.OnClientEvent:Connect(function(ResearchData)
	local RemovedSlotCount
	for i,tile in pairs (CurrentResearch:GetChildren()) do
		if tile:FindFirstChild("ResearchSlot") then
			if tile.ResearchSlot.ResearchTile.ResearchName.Text == ResearchData["Research Name"] and RemovedSlotCount == nil then
				tile.ResearchSlot:Destroy()
				RemovedSlotCount = string.gsub(tile.Name, "ResearchOutline", "")
				--PurchaseHandler created tile for previous research menu
			end
		end
	end
	
	if RemovedSlotCount then
		for i,tile in pairs (CurrentResearch:GetChildren()) do
			if tile:FindFirstChild("ResearchSlot") then
				local SlotCount = string.gsub(tile.Name, "ResearchOutline", "")
				local NewSlotCount = tonumber(SlotCount) - 1
				if NewSlotCount >= tonumber(RemovedSlotCount) then
					tile.ResearchSlot.Parent = CurrentResearch:FindFirstChild("ResearchOutline" .. tostring(NewSlotCount))
				end
			end
		end
	end
	
	--Little GUI animation with "show me" written on bottom to play cutscene if player wants to
	--(likely a blueprint somewhere or a shop with new items!)
	
	--Must lookvector towards the object, but must not be too close or too far, along with not being at
	--an angle where some other object gets in the way
end)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------<|Interaction Functions|>-------------------------------------------------------------------------------------------------------

local DepositInteract = eventsFolder.HotKeyInteract:WaitForChild("DepositInteract")
local StorageInteract = eventsFolder.HotKeyInteract:WaitForChild("StorageInteract")
local DepositInventory = eventsFolder.Utility:WaitForChild("DepositInventory")

local repeatDebounce = false
local function HandleDepositInventory()
	if not repeatDebounce and not ComputerIsOn then
		repeatDebounce = true
		
		--Delete the tiles from the inventory (or set their amounts to zero)
		for i,menu in pairs (PlayerGui.DataMenu.DataMenu.InventoryMenu:GetChildren()) do
			if menu:IsA("Frame") then
				for i,page in pairs (menu:GetChildren()) do
					for i,tile in pairs (page:GetChildren()) do
						if tile:IsA("TextButton") then
							tile:Destroy()
						end
					end
				end
			end
		end

		local finished = DepositInventory:FireServer(Player)
		wait(finished)

		--notify player that they deposited their inventory
		TycoonComputerGui.DepositNotify.Visible = true
		TycoonComputerGui.DepositNotify:TweenPosition(UDim2.new(0.358,0,0.85,0), "Out", "Quint", 1)
		wait(1)
		TycoonComputerGui.DepositNotify:TweenPosition(UDim2.new(0.358,0,1.1,0), "In", "Quint", 1.5)
		wait(3)
		TycoonComputerGui.DepositNotify.Visible = false

		repeatDebounce = false	
	end	
end

DepositInteract.Event:Connect(HandleDepositInventory)

StorageInteract.Event:Connect(function(promptObject)
	StartUpCutscene(promptObject)
end)

----------------------------<|General Button Functions|>-----------------------------------------------------------------------------------------------

ComputerScreen.Taskbar.Shutdown.Activated:Connect(function()
	SelectionMenu.CurrentSelection.Value = nil
	SelectionMenu.CurrentRarity.Value = ""

	--Move "back button" back
	ShutDownComputer()
end)

ComputerScreen.Taskbar.Home.Activated:Connect(function()
	PrepareAllMenuVisibility()
	MenuSelect.Visible = true
	ComputerScreen.Taskbar.Visible = true
end)

--Back button to return to current menu type's main menu, instead of the menu type selection menu?

---------------------------------------------------<|Cutscene Manager|>-----------------------------------------------------------------------------------------------------------
local Camera = game.Workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

function MoveCamera(StartPart, EndPart, Duration, EasingStyle, EasingDirection)
	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.CFrame = StartPart.CFrame
	
	local Cutscene = TweenService:Create(Camera, TweenInfo.new(Duration, EasingStyle, EasingDirection), {CFrame = EndPart.CFrame})
	Cutscene:Play()
	wait(Duration)
end

function StartUpCutscene(promptObject)
	Character.Humanoid.WalkSpeed = 0
	Character.Humanoid.JumpPower = 0
	
	CurrentStorage = promptObject.Parent.Parent.Parent
	promptObject.Enabled = false
	
	local CutsceneFolder = CurrentStorage:FindFirstChild("CutsceneCameras")
	MoveCamera(Camera, CutsceneFolder.Camera1, 1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	MoveAllBaseScreenUI:Fire("Hide") --Move "surface screen" tiles away
	MoveCamera(CutsceneFolder.Camera1, CutsceneFolder.Camera2, .7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StartUpComputer()
end

function ShutDownCutscene()
	local CutsceneFolder = CurrentStorage:FindFirstChild("CutsceneCameras")
	MoveCamera(CutsceneFolder.Camera2, CutsceneFolder.Camera1, .7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	MoveAllBaseScreenUI:Fire("Show")
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)

	wait(.8)
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = game.Players.LocalPlayer.Character:WaitForChild("Humanoid")
	CurrentStorage.InteractedModel.Main.DisplayButtonGUI.Enabled = true
	
	Character.Humanoid.WalkSpeed = DefaultWalkSpeed
	Character.Humanoid.JumpPower = DefaultJumpPower
end

ManageStorageTiles("Materials")

