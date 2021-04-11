--(LocalScript)
--Visuals for data menu associated with items inside of the tycoon's (business) storage and all the player's research
-----------------------------------------------------------------------------------------------------------------------------------------------
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local PlayerGui = Player:WaitForChild("PlayerGui")
local StarterGui = game:GetService("StarterGui")
local TycoonComputerGui = script.Parent

local ComputerScreen = TycoonComputerGui.ComputerScreen
local MenuSelect = ComputerScreen.MenuSelect
local FadeOut = ComputerScreen.FadeOut

ComputerScreen.Visible = false

local Character = game.Workspace.Players:WaitForChild(tostring(Player))
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local DefaultWalkSpeed = Character.Humanoid.WalkSpeed
local DefaultJumpPower = Character.Humanoid.JumpPower

local LocalLoadTycoon = game.ReplicatedStorage.Events.Tycoon:WaitForChild("LocalLoadTycoon")
local MoveAllBaseScreenUI = game.ReplicatedStorage.Events.GUI:WaitForChild("MoveAllBaseScreenUI")

local ComputerIsOn = false
local CurrentStorage

local BeepSound = script.Parent.Beep
local KeyboardClickSound = script.Parent.KeyboardClick
local StartUpSound = script.Parent.StartUp

---------------<|Utility|>-----------------------------------------------------------------------------------------------------------------------------

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

local function CountPages(Menu)
	local HighPage = 0
	for i,page in pairs (Menu:GetChildren()) do
		if page:IsA("Frame") and string.find(page.Name, "Page") then
			local PageNumber = string.gsub(page.Name, "Page", "")
			if tonumber(PageNumber) > HighPage then
				HighPage = tonumber(PageNumber)
			end
		end
	end
	return HighPage
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
		if menu:IsA("Frame") and tostring(menu) ~= "FadeOut" then
			menu.Visible = false

			if tostring(menu) == "StorageMenu" or tostring(menu) == "ResearchMenu" then
				for i,itemMenu in pairs (menu:GetChildren()) do
					if itemMenu:IsA("Frame") then
						itemMenu.Visible = false
					end
				end
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
	ComputerScreen.CredentialsScreen.Username.Text = tostring(Player)
	
	local PlayerThumbnail = ComputerScreen.CredentialsScreen.PlayerThumbnail
	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size420x420
	local PlayerProfilePicture = Players:GetUserThumbnailAsync(PlayerUserId, thumbType, thumbSize)
	PlayerThumbnail.Image = PlayerProfilePicture
	
	PrepareAllMenuVisibility()
	
	ComputerScreen.CredentialsScreen.Visible = true
	
	--Fade-in login screen
	local PasswordInput = ComputerScreen.CredentialsScreen.Password
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
	ComputerScreen.Taskbar.TimeInfo.Time.Text = tostring(os.date(stringTime, timestamp))
	
	MenuSelect.Visible = true
	wait(.5)
	
	ComputerScreen.CredentialsScreen.Visible = false
	ComputerScreen.CredentialsScreen.Position = UDim2.new(0,0,0,0)
	
	--Data tab buttons are not dynamic, but research tiles will be...
	--To be efficient, use different functions to update: UpdateResearchers, UpdateCurrentResearch, UpdateAvailableResearch
	--and UpdatePreviousResearch
	--Call ^these^ on first load and every time player gets something new in each category
end


----------------------------<|Tycoon Storage GUI Functions|>---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local StorageMenu = ComputerScreen.StorageMenu
local SelectionMenu = StorageMenu.SelectionMenu
local ItemsPreview = StorageMenu.ItemsPreview
local DataTabSelect = StorageMenu.DataTabSelect

--Prepare Storage DataTab Buttons
for i,button in pairs (DataTabSelect:GetChildren()) do
	if button:IsA("ImageButton") then
		button.Activated:Connect(function()
			if DataTabSelect.Visible == true and SelectionMenu.Visible == false then
				BeepSound:Play()
				OpenAffiliatedItemPreview(button)
				DataTabSelect.Visible = false
			end
		end)
	end
end

--Menu Selection
MenuSelect.StorageMenuButton.Activated:Connect(function()
	StorageMenu.Visible = true
	DataTabSelect.Visible = true
	SelectionMenu.Visible = false
	ItemsPreview.Visible = false
	MenuSelect.Visible = false
	BeepSound:Play()
end)

------------------------<|Storage Utility|>------------------------------------------------

local function MoveOtherRaritiesDown(RarityMenu)
	local Menu = RarityMenu.Parent
	local DisplayOrderValue = RarityMenu.DisplayOrder.Value
	for i,rarity in pairs (Menu:GetChildren()) do
		if rarity:IsA("TextLabel") then
			if rarity.DisplayOrder.Value > DisplayOrderValue then
				rarity.Position = UDim2.new(RarityMenu.Position.X.Scale, 0, rarity.Position.Y.Scale + .09, 0)
			end
		end
	end
end

function OpenAffiliatedItemPreview(button)
	local MenuName = button.Name
	
	if StorageMenu.ItemsPreview:FindFirstChild(MenuName) then
		SelectionMenu.Visible = true
		SelectionMenu.SellMenu.Visible = false
		ItemsPreview.Visible = true
		
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

local function UpdateSelectionInfo(RarityMenu, tile)
	local Menu = RarityMenu.Parent
	local ItemInformation = FindItemInfo(tostring(tile), tostring(Menu))
	local Discovered = tile.Discovered.Value
	
	SelectionMenu.Amount.Visible = Discovered
	SelectionMenu.UnitPrice.Visible = Discovered
	SelectionMenu.SelectItem.Visible = Discovered
	SelectionMenu.Hint.Visible = not Discovered
	
	if Discovered == true then
		SelectionMenu.Picture.Image = ItemInformation["GUI Info"].StatImage.Value
		SelectionMenu.DisplayName.Text = tostring(tile)
		SelectionMenu.Amount.Text = tostring(tile.AmountInStorage.Value)
		SelectionMenu.UnitPrice.Text = tostring(ItemInformation.CurrencyValue.Value)
		tile.AmountInStorage.Changed:Connect(function()
			if tostring(tile) == SelectionMenu.CurrentSelection.Value then
				SelectionMenu.Amount.Text = tostring(tile.AmountInStorage.Value)
			end
		end)
	else
		SelectionMenu.DisplayName.Text = "[Locked]"
		SelectionMenu.Picture.Image = "rbxgameasset://Images/lock2"
		SelectionMenu.Hint.Text = "Hint: " .. tostring(ItemInformation["GUI Info"])
	end
end

local function UpdateTileLock(tile, StatValue)
	if StatValue == true then
		tile.LockImage.Visible = false
	else
		tile.LockImage.Visible = true
	end
end

------------------------<|Tile Selection Buttons|>------------------------------------

local CurrentMenu
function ReadyItemTypeMenu(Menu)
	CurrentMenu = Menu
	
	for i,item in pairs (Menu.Common:GetChildren()) do
		if item:IsA("Frame") then
			if item.SlotNumber.Value == 1 then --Select first common item (for first menu open, tiles never switched yet)
				local Discovered = item.Discovered.Value
				local ItemInformation = FindItemInfo(tostring(item), tostring(Menu))
				
				item.BorderSizePixel = 4
				item.BorderColor3 = Color3.fromRGB(0, 170, 255)
				SelectionMenu.CurrentSelection.Value = tostring(item)
				SelectionMenu.CurrentRarity.Value = "Common"
				SelectionMenu.UnitPrice.Visible = Discovered
				SelectionMenu.Hint.Visible = not Discovered
				
				if ItemInformation then
					if Discovered then
						SelectionMenu.DisplayName.Text = tostring(item)
						SelectionMenu.Picture.Image = ItemInformation["GUI Info"].StatImage.Value
						SelectionMenu.UnitPrice.Text = tostring(ItemInformation.CurrencyValue.Value)
						
						while SelectionMenu.CurrentSelection.Value == tostring(item) do
							SelectionMenu.Amount.Text = tostring(item.AmountInStorage.Value)
							wait()
						end
					else
						SelectionMenu.DisplayName.Text = "[Locked]"
						SelectionMenu.Picture.Image = "rbxgameasset://Images/lock2"
						SelectionMenu.Hint.Text = "Hint: " .. tostring(ItemInformation["GUI Info"])
					end
				end
			end
		end
	end
end

SelectionMenu.NextItem.Activated:Connect(function()
	MoveToTile(CurrentMenu, 1)
end)

SelectionMenu.PreviousItem.Activated:Connect(function()
	MoveToTile(CurrentMenu, -1)
end)

SelectionMenu.NextRarity.Activated:Connect(function()
	MoveToTile(CurrentMenu, nil, "Next")
end)

SelectionMenu.PrevRarity.Activated:Connect(function()
	MoveToTile(CurrentMenu, nil, "Previous")
end)

local SellMenu = SelectionMenu.SellMenu
local SellItem = game.ReplicatedStorage.Events.Utility:WaitForChild("SellItem")

local function DisplaySellMenuElements(bool, bool2, ItemName)
	for i,gui in pairs (SellMenu:GetChildren()) do
		if tostring(gui) ~= "EmptyNotifier" then
			if not gui:IsA("NumberValue") and not gui:IsA("ObjectValue") then
				gui.Visible = bool
			end
		else
			gui.Visible = bool2
			if ItemName then
				gui.Text = string.gsub(gui.Text, "ITEM", ItemName)
			end
		end
	end
end

SelectionMenu.SelectItem.Activated:Connect(function()
	if SelectionMenu.Visible == true then
		SelectionMenu.SelectItem.Active = false
		local ItemName = SelectionMenu.CurrentSelection.Value
		local ItemAmount = tonumber(SelectionMenu.Amount.Text)
		SellMenu.MaxAmount.Value = ItemAmount
		
		local ItemInfo = FindItemInfo(ItemName, tostring(CurrentMenu))
		if ItemInfo then
			SellMenu.SelectedItem.Value = ItemInfo
			SellMenu.Visible = true	
			
			if ItemAmount > 0 then
				SellMenu.SnapAmount.Value = math.ceil(SellMenu.SliderBar.AbsoluteSize.X/(ItemAmount)) --+1 for 0th
				SellMenu.SellAll.Text = "Sell All: $" .. tostring(tonumber(ItemAmount*SellMenu.SelectedItem.Value.CurrencyValue.Value))
				
				DisplaySellMenuElements(true, false)
				CalculateSliderPosition()
			else
				DisplaySellMenuElements(false, true, ItemName)
				wait(2)
				SellMenu.Visible = false
				SellMenu.EmptyNotifier.Text = string.gsub(SellMenu.EmptyNotifier.Text, ItemName, "ITEM")
			end
		end
		SelectionMenu.SelectItem.Active = true
	end
end)

local function ChangeToTileInMenu(Menu, CurrentSelection, SeekedSlotValue)
	if SeekedSlotValue == 0 then
		local CurrentMenuOrderValue = Menu.DisplayOrder.Value
		for i,rarity in pairs (Menu.Parent:GetChildren()) do
			if rarity:IsA("TextLabel") then
				if rarity.DisplayOrder.Value == CurrentMenuOrderValue then
					for i,item in pairs (rarity:GetChildren()) do
						if item:IsA("Frame") then
							if item.SlotNumber.Value > SeekedSlotValue then
								SeekedSlotValue = item.SlotNumber.Value
							end
						end
					end
				end
			end
		end
	end
	for i,tile in pairs (Menu:GetChildren()) do
		if tile:IsA("Frame") then
			if tile.SlotNumber.Value == SeekedSlotValue then
				CurrentSelection.BorderSizePixel = 2 --Change Previous tile to
				CurrentSelection.BorderColor3 = Color3.fromRGB(27, 42, 53)
				tile.BorderSizePixel = 4 --Change now selected tile to
				tile.BorderColor3 = Color3.fromRGB(0, 170, 255)
				SelectionMenu.CurrentRarity.Value = tostring(Menu)
				SelectionMenu.CurrentSelection.Value = tostring(tile)
				UpdateSelectionInfo(Menu, tile)
			end
		end
	end
end

function MoveToTile(Menu, amount, RaritySkip)
	if SelectionMenu.Visible == true then
		local CurrentSelectionName = SelectionMenu.CurrentSelection.Value
		local CurrentRarityName = SelectionMenu.CurrentRarity.Value
		local CurrentRarityMenu = ItemsPreview:FindFirstChild(tostring(Menu)):FindFirstChild(CurrentRarityName)
		local CurrentSelection = CurrentRarityMenu:FindFirstChild(CurrentSelectionName)
		
		local AmountOfSlots = 0
		for i,item in pairs (CurrentRarityMenu:GetChildren()) do
			if item:IsA("Frame") then
				AmountOfSlots = AmountOfSlots + 1
			end
		end
		
		local LowestRarityMenu = CurrentRarityMenu
		local HighestRarityMenu = CurrentRarityMenu
		local NextRarityMenu = CurrentRarityMenu
		local PreviousRarityMenu = CurrentRarityMenu
		
		for i,rarity in pairs (ItemsPreview:FindFirstChild(tostring(Menu)):GetChildren()) do
			if rarity:IsA("TextLabel") then
				if rarity.DisplayOrder.Value < LowestRarityMenu.DisplayOrder.Value then
					LowestRarityMenu = rarity
				end
				if rarity.DisplayOrder.value > HighestRarityMenu.DisplayOrder.Value then
					HighestRarityMenu = rarity
				end
				if rarity.DisplayOrder.Value + 1 == CurrentRarityMenu.DisplayOrder.Value then
					PreviousRarityMenu = rarity
				end
				if rarity.DisplayOrder.Value - 1 == CurrentRarityMenu.DisplayOrder.Value then
					NextRarityMenu = rarity
				end
			end
		end
		
		local HighestTileOfHighRarity = 0
		for i,tile in pairs (HighestRarityMenu:GetChildren()) do
			if tile:IsA("Frame") then
				if tile.SlotNumber.Value > HighestTileOfHighRarity then
					HighestTileOfHighRarity = tile.SlotNumber.Value
				end
			end
		end

		local CurrentSelectionSlotValue = CurrentSelection.SlotNumber.Value
		if amount then
			if CurrentSelectionSlotValue + amount > AmountOfSlots or CurrentSelectionSlotValue + amount <= 0 then --Moving to next rarity menu			
					--Move to lowest rarity 
				if CurrentRarityMenu.DisplayOrder.Value == NextRarityMenu.DisplayOrder.Value and amount > 0 then
					ChangeToTileInMenu(LowestRarityMenu, CurrentSelection, 1)
					
					--Move to highest rarity
				elseif CurrentRarityMenu.DisplayOrder.Value == LowestRarityMenu.DisplayOrder.Value and amount < 0 then
					ChangeToTileInMenu(HighestRarityMenu, CurrentSelection, HighestTileOfHighRarity)
					
				else
					if amount > 0 then
						--First of next rarity
						ChangeToTileInMenu(NextRarityMenu, CurrentSelection, 1)
					else 
						--Highest of 'previous' rarity
						ChangeToTileInMenu(PreviousRarityMenu, CurrentSelection, 0)
					end
				end
			else --Just move to next tile in the rarity
				ChangeToTileInMenu(CurrentRarityMenu, CurrentSelection, CurrentSelectionSlotValue + amount)
			end
		elseif RaritySkip then
			if RaritySkip == "Next" then
				if CurrentRarityMenu.DisplayOrder.Value ~= NextRarityMenu.DisplayOrder.Value then
					ChangeToTileInMenu(NextRarityMenu, CurrentSelection, 1)
				else --Moving to lowest rarity
					ChangeToTileInMenu(LowestRarityMenu, CurrentSelection, 1)
				end
			elseif RaritySkip == "Previous" then
				if CurrentRarityMenu.DisplayOrder.Value ~= PreviousRarityMenu.DisplayOrder.Value then
					ChangeToTileInMenu(PreviousRarityMenu, CurrentSelection, 1)
				else --Moving to highest rarity
					ChangeToTileInMenu(HighestRarityMenu, CurrentSelection, 1)
				end
			end
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
end

local snapAmount
local amountToSellPercent
function CalculateSliderPosition(bool)
	snapAmount = SellMenu.SnapAmount.Value
	local xOffset = math.floor((Mouse.X - sliderBar.AbsolutePosition.X) / snapAmount) * snapAmount
	local xOffsetClamped = math.clamp(xOffset, 0, sliderBar.AbsoluteSize.X - slider.AbsoluteSize.X) --pos, min, max

	local sliderPosNew = UDim2.new(0, xOffsetClamped, slider.Position.Y.Scale, 0) --Snap slider bar in place
	slider.Position = sliderPosNew

	local roundedAbsSize = math.ceil(sliderBar.AbsoluteSize.X / snapAmount) * snapAmount or 0
	local roundedOffsetClamped = (xOffsetClamped / snapAmount) * snapAmount --highest amount slider can achieve
	local Percentage = roundedOffsetClamped / roundedAbsSize
	
	amountToSellPercent = Percentage
	local GUIamountToSell = math.ceil(Percentage*SellMenu.MaxAmount.Value)

	SellMenu.SelectedAmount.Text = tostring(GUIamountToSell)
	SellMenu.ItemName.Text = tostring(SellMenu.SelectedItem.Value)
	
	SellMenu.CashValue.Text = "$" .. tostring(SellMenu.SelectedItem.Value.CurrencyValue.Value*GUIamountToSell)
end

SellMenu.SellItem.Activated:Connect(function()
	local ItemInfo = tostring(SellMenu.SelectedItem.Value) --Keep as string to prevent RS exploiting
	SellItem:FireServer(CurrentMenu, ItemInfo, amountToSellPercent)
	SellMenu.Visible = false
	
	--Possibly do a statValue vs MaxAmount check to see if certain player is exploiting
	--maybe have a saved stat in each player that is amount of exploiter warnings. If exploiter warnings count is too high, they
	--will be notified&kicked/banned
	
	--Sell GUI animation
end)

SellMenu.SellAll.Activated:Connect(function()
	local ItemInfo = SellMenu.SelectedItem.Value
	SellItem:FireServer(CurrentMenu, ItemInfo, 1)
	SellMenu.Visible = false
	
	--Sell GUI animation
end)

SellMenu.ExitButton.Activated:Connect(function()
	SellMenu.Visible = false
end)

---------------------------<|Storage Menu Tile Management|>-------------------------------------------

local AmountPerRow = 10
function SetupTycoonStorageTiles(button)
	ItemsPreview.Visible = false
	local MenuName = button.Name
	if ItemsPreview:FindFirstChild(MenuName) then
		local AffiliatedItemsPreview = ItemsPreview:FindFirstChild(MenuName)
		
		local ItemDataFolder 
		for i,location in pairs (game.ReplicatedStorage.ItemLocations:GetChildren()) do
			if string.find(location:GetAttribute("ItemTypesPresent"), tostring(MenuName)) then
				for i,item in pairs (location:GetChildren()) do
					if string.gsub(item.Bag.Value, "Bag", "") .. "s" == tostring(MenuName) then
						ItemDataFolder = location
					end
				end
			end
		end	
		
		local TycoonStorageTile = game.ReplicatedStorage.GuiElements:FindFirstChild("TycoonStorageTile")
		
		if ItemDataFolder then
			for i,item in pairs (ItemDataFolder:GetChildren()) do
				local ItemType = string.gsub(item.Bag.Value, "Bag", "") .. "s"
				if ItemType == button.Name then
					local ItemRarity = item["GUI Info"].RarityName.Value
					local RarityMenu = AffiliatedItemsPreview:FindFirstChild(ItemRarity)
					local RarityChildCount = 0
					local PrevTile
					for i,tile in pairs (RarityMenu:GetChildren()) do
						if tile:IsA("Frame") then
							if tile.SlotNumber.Value > RarityChildCount then
								RarityChildCount = tile.SlotNumber.Value
								PrevTile = tile
							end
						end
					end
					
					local NewTile = TycoonStorageTile:Clone()
					NewTile.SlotNumber.Value = RarityChildCount + 1
					NewTile.Name = tostring(item)
					--NewTile.BorderColor3 = Color3.fromRGB(RarityMenu.TextStrokeColor3)
					
					NewTile.Picture.Image = item["GUI Info"].StatImage.Value --Put in check for discovered remotefunction for image/lock
					
					NewTile.Parent = RarityMenu
					--print(RarityChildCount, RarityChildCount/AmountPerRow, math.floor(RarityChildCount/AmountPerRow))
					
					if RarityChildCount == 0 then
						NewTile.Position = UDim2.new(0.05, 0, 1, 0)
						MoveOtherRaritiesDown(RarityMenu)
						
					elseif (RarityChildCount)/AmountPerRow ~= math.floor(RarityChildCount/AmountPerRow) then
						NewTile.Position = UDim2.new(PrevTile.Position.X.Scale + .3, 0, PrevTile.Position.Y.Scale, 0)
						
					elseif (RarityChildCount)/AmountPerRow == math.floor(RarityChildCount/AmountPerRow) then
						--Starting a new row
						local RowStarterTile
						for i,tile in pairs (RarityMenu:GetChildren()) do
							if tile:IsA("Frame") then
								if tile.SlotNumber.Value == NewTile.SlotNumber.Value - AmountPerRow then
									RowStarterTile = tile
								end
							end
						end
						NewTile.Position = UDim2.new(RowStarterTile.Position.X.Scale, 0, RowStarterTile.Position.Y.Scale + 1.67, 0)
						MoveOtherRaritiesDown(RarityMenu)
					end
				end	
			end
		end
	end
end

------------------<|Event Functions|>-------------------------------

local UpdateTycoonStorage = game.ReplicatedStorage.Events.GUI:WaitForChild("UpdateTycoonStorage")
UpdateTycoonStorage.OnClientEvent:Connect(function(File, Stat, StatValue, AmountAdded, AcquiredLocation)
	if typeof(StatValue) == "string" then
		File = string.gsub(File, "TycoonStorage", "")
		Stat = string.gsub(Stat, "TycoonStorage", "")
	else --Bool for Discovered
		Stat = string.gsub(Stat, "Discovered", "")
		--print(AcquiredLocation, game.ReplicatedStorage.ItemLocations:FindFirstChild(tostring(AcquiredLocation)))
		local RarityName = game.ReplicatedStorage.ItemLocations:FindFirstChild(tostring(AcquiredLocation)):FindFirstChild(tostring(Stat)):FindFirstChild("GUI Info").RarityName.Value
		ItemsPreview:FindFirstChild(tostring(File)):FindFirstChild(RarityName):WaitForChild(tostring(Stat)).Discovered.Value = StatValue
	end

	wait() --Allow ItemPreview tiles to be made
	for i,rarity in pairs (ItemsPreview:FindFirstChild(File):GetChildren()) do
		if rarity:IsA("TextLabel") then
			if rarity:FindFirstChild(Stat) then
				if typeof(StatValue) == "boolean" then
					rarity:FindFirstChild(Stat).Discovered.Value = StatValue
					UpdateTileLock(rarity:FindFirstChild(Stat),StatValue)
				else
					rarity:FindFirstChild(Stat).AmountInStorage.Value = StatValue
				end
			end
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

local CheckResearchDepends = game.ReplicatedStorage.Events.Utility:WaitForChild("CheckResearchDepends")

--Prepare all always-available buttons: like previous research and add researchers buttons (not research slots!)

MenuSelect.ResearchMenuButton.Activated:Connect(function()
	ResearchMenu.Visible = true
	CurrentResearch.Visible = true
	ResearchersList.Visible = true
	AvailableResearch.Visible = true
	ResearchersList.AvailableResearchPages.Visible = true
	ResearchersList.ChangeResearchView.Visible = true
	
	PreviousResearch.Visible = false
	ResearchersList.PreviousResearchPages.Visible = false
	CostList.Visible = false
	ResearchersList.CostListPages.Visible = false
	InfoMenu.Visible = false
	
	ResetPageOrder(AvailableResearch)
	ResetPageOrder(PreviousResearch)
	CostList.CurrentPage.Value = 1
	
	ResearchersList.LeftMenuLabel.Text = "Current Research"
	ResearchersList.RightMenuLabel.Text = "Available Research"
	
	UpdatePageDisplay(AvailableResearch, true)
	UpdatePageDisplay(PreviousResearch, false)
	UpdatePageDisplay(CostList, false)
	
	ChangeTimerActivity(true)
	
	MenuSelect.Visible = false
	BeepSound:Play()
end)

------------------------<|Time Management|>-----------------------------

function ChangeTimerActivity(bool)
	for i,outlineTile in pairs (CurrentResearch:GetChildren()) do
		if outlineTile:IsA("Frame") then
			for i,tile in pairs (outlineTile:GetChildren()) do
				if tile:IsA("TextButton") then
					tile.ProgressBar.Active.Value = bool
				end
			end
		end
	end
end

local function toHMS(Sec)
	return string.format("%02i:%02i:%02i", Sec/60^2, Sec/60%60, Sec%60)
end

local function ManageTileTimers(Tile, ResearchData, FinishTime)
	print(ResearchData["Research Length"],ResearchData,FinishTime,ResearchData["Research Name"])
	local SecondLength = FinishTime - ResearchData["Research Length"]
	coroutine.resume(coroutine.create(function()
		while Tile.ProgressBar.Active.Value == true do
			wait(1)
			local PercentFinished = os.time() - ResearchData["Research Length"] / SecondLength
			local SecondsLeft = FinishTime - os.time()
			Tile.ProgressBar.Timer.Text = toHMS(SecondsLeft)
			
			--Tween Progress Bar
			--Rotate hand on clock to left of progress bar (like CoC timer, 4 points it rotates two going around)
		end
	end))
end

-----------------------<|Tile Info Functions|>-----------------------

local function InsertTileInfo(Tile, ResearchData, ResearchType, FinishTime, StatTable)
	if StatTable == nil then
		Tile.ResearchName.Text = ResearchData["Research Name"]
		Tile.ResearchType.Text = ResearchType
		
		--later do rarity coloring when rarity sorting is implemented
		
		if FinishTime then
			Tile.ResearchTime.Visible = false
			Tile.ProgressBar.Visible = true
			
			ManageTileTimers(Tile, ResearchData, FinishTime)
		else
			Tile.ProgressBar.Visible = false
			Tile.ResearchTime.Visible = true
			
			Tile.ResearchTime.Text = toHMS(ResearchData["Research Length"])
		end
		
		Tile.Activated:Connect(function()
			ResearchersList.LeftMenuLabel.Text = "Research Information"
			ResearchersList.RightMenuLabel.Text = "Research Cost"

			CostList.Visible = true
			InfoMenu.Visible = true
			ResearchersList.CostListPages.Visible = true

			AvailableResearch.Visible = false
			ResearchersList.AvailableResearchPages.Visible = false
			CurrentResearch.Visible = false
			PreviousResearch.Visible = false
			ResearchersList.PreviousResearchPages.Visible = false
			ResearchersList.ChangeResearchView.Visible = false
			
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
		end)
	else --Material Tile
		local StatInfo = StatTable[1]
		local StatAmount = StatTable[2]
		
		Tile.ResearchName.Text = tostring(StatInfo)
		local StatType
		if StatInfo:FindFirstChild("Levels") then --ExpRequirement
			StatType = tostring(StatInfo.Parent)
			StatAmount = "Level " .. tostring(StatAmount) 
		else
			StatType = string.gsub(StatInfo.Bag.Value, "Bag", "") .. "s"
		end
		Tile.ResearchType.Text = StatType
		Tile.ResearchTime.Text = tostring(StatAmount)
		Tile.ResearchImage.Image = StatInfo["GUI Info"].StatImage.Value
		
		--Color ResearchTime red or green if player has met the requirements for the stat cost
		--Do similar way as tycoon purchase menu checks player data
		
		Tile.ResearchName.Position = UDim2.new(0.162, 0, -0.08, 0)
		Tile.ResearchName.Size = UDim2.new(0.8, 0, 0.55, 0)
		Tile.ResearchType.Position = UDim2.new(0.162, 0, 0.3, 0)
		Tile.ResearchType.Size = UDim2.new(0.377, 0, 0.35, 0)
		
		Tile.ProgressBar.Visible = false
		Tile.ResearchTime.Visible = true
		
		--Tile.Activated:Connect(function()
			--Possibly send to storage menu?
			--Or make an ItemInfo menu
		--end)
	end
end

--------------------<|Research Tile Management|>---------------------

local function RearrangeAvailableTiles(ResearchData, MoveType)
	--Can finally be implemented once rarity sorting is handled
	--Find page actually grabs the page that the tile will go into, but this functions job is to move the tiles
	--into their appropriate positions once this tile's position has been affected
	
	local AffectedPage
	local AffectedTileNumber
	for i,page in pairs (AvailableResearch:GetChildren()) do
		for i,tile in pairs (page:GetChildren()) do
			if tile.ResearchName.Text == ResearchData["Research Name"] then
				AffectedPage = page
				AffectedTileNumber = tonumber(string.gsub(tile.Name, "Slot", ""))
				tile:Destroy()
			end
		end
	end
	
	--Move Tiles To Fill Gap (or move tiles away from new tile)
	local AffectedPageNumber = tonumber(string.gsub(AffectedPage.Name, "Page", ""))
	for i,page in pairs (AvailableResearch:GetChildren()) do
		local PageNumber = tonumber(string.gsub(AffectedPage.Name, "Page", ""))
		if PageNumber >= AffectedPageNumber then
			
		end
	end
end

function ManageResearchTile(Menu, ResearchData, ResearchType, FinishTime, StatTable)
	if Menu == CurrentResearch and FinishTime then --Guaranteed to only be one page
		local ParentTile
		for i,outlineTile in pairs (CurrentResearch:GetChildren()) do
			if not outlineTile:FindFirstChild("ResearchSlot") and not ParentTile then
				ParentTile = outlineTile
			end
		end
		
		if ParentTile then
			local NewTile = game.ReplicatedStorage.GuiElements.ResearchSlot:Clone()
			NewTile.Name = "ResearchSlot"
			NewTile.Position = UDim2.new(0, 0, 0, 0)
			NewTile.Size = UDim2.new(1, 0, 1, 0)
			NewTile.Parent = ParentTile
			
			--RearrangeAvailableTiles(Menu, "Destroy")
			InsertTileInfo(NewTile, ResearchData, ResearchType, FinishTime)
		end
	else --Previous and Available Research
		local Page,SlotCount = FindResearchPage(Menu, 5) --number may change for each menu
		
		local NewTile = game.ReplicatedStorage.GuiElements.ResearchSlot:Clone()
		NewTile.Name = "Slot" .. tostring(SlotCount + 1)
		NewTile.Position = UDim2.new(0.05, 0, 0.059+0.173*SlotCount, 0)
		NewTile.Size = UDim2.new(0.9, 0, 0.14, 0)
		NewTile.Parent = Page
		
		--RearrangeAvailableTiles(Menu, "Add")
		InsertTileInfo(NewTile, ResearchData, ResearchType, nil, StatTable)
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
	local HighPage = CountPages(Menu)
	
	if HighPage == 0 then
		HighPage = 1
	end
	if bool then
		Menu.NextPage.Active = bool
		Menu.PreviousPage.Active = bool
		PageDisplay.Visible = bool
	end

	PageDisplay.Text = tostring(Menu.CurrentPage.Value) .. "/" .. tostring(HighPage)
end

function FindResearchPage(Menu, MaxTileAmount)
	local Pages = Menu:GetChildren()
	local PageCount = CountPages(Menu)

	local Page
	local Over
	local SlotCount = 0
	if Menu:FindFirstChild("Page" .. tostring(PageCount)) then
		local CheckedPage = Menu:FindFirstChild("Page" .. tostring(PageCount))

		for i,slot in pairs (CheckedPage:GetChildren()) do
			if slot:IsA("TextButton") then
				SlotCount += 1
			end
		end
		if SlotCount < MaxTileAmount then
			Page = CheckedPage
		else
			Over = CheckedPage
		end
	end
	
	--Sort by rarity later (if rarity, because experience tiles are not (put non-rarities on top))
	
	if Page == nil then --Make new page
		local NewPage = game.ReplicatedStorage.GuiElements.ResearchPage:Clone()
		if Over then
			NewPage.Visible = false
			SlotCount = 0
		else
			NewPage.Visible = true
		end
		NewPage.Name = "Page" .. tostring(PageCount+1)
		NewPage.Parent = Menu
		Page = NewPage
	end

	return Page,SlotCount
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
		local HighPage = CountPages(Menu)

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

ResearchersList.ChangeResearchView.Activated:Connect(function()
	if CurrentResearch.Visible then
		CurrentResearch.Visible = false
		PreviousResearch.Visible = true
		UpdatePageDisplay(PreviousResearch, true)
		ResearchersList.PreviousResearchPages.Visible = true
		
		ResearchersList.LeftMenuLabel.Text = "Previous Research"
		ResearchersList.ChangeResearchView.Text = "Current Research"
	else
		CurrentResearch.Visible = true
		PreviousResearch.Visible = false
		UpdatePageDisplay(PreviousResearch, false)
		ResearchersList.PreviousResearchPages.Visible = false
		
		ResearchersList.LeftMenuLabel.Text = "Current Research"
		ResearchersList.ChangeResearchView.Text = "Previous Research"
	end
end)

AvailableResearch.NextPage.Activated:Connect(function()
	ChangePage(AvailableResearch, 1, -1, 0.02)
end)

AvailableResearch.PreviousPage.Activated:Connect(function()
	ChangePage(AvailableResearch, -1, 1, -0.02)
end)

PreviousResearch.NextPage.Activated:Connect(function()
	ChangePage(PreviousResearch, 1, -1, 0.02)
end)

PreviousResearch.PreviousPage.Activated:Connect(function()
	ChangePage(PreviousResearch, -1, 1, -0.02)
end)

CostList.NextPage.Activated:Connect(function()
	ChangePage(CostList, 1, -1, 0.02)
end)

CostList.PreviousPage.Activated:Connect(function()
	ChangePage(CostList, -1, 1, -0.02)
end)

--------------------<|Event Functions|>------------------------------
local UpdateResearch = game.ReplicatedStorage.Events.GUI:WaitForChild("UpdateResearch")
UpdateResearch.OnClientEvent:Connect(function(ResearchData, ResearchType, Completed, Purchased, FinishTime)
	if Purchased and Completed then --Previous
		--ManageResearchTile(PreviousResearch, ResearchData, ResearchType)
		
	elseif Purchased and not Completed then --Current
		ManageResearchTile(CurrentResearch, ResearchData, ResearchType, FinishTime)
	else --Check If Can Be Available
		local AllDependenciesMet = CheckResearchDepends:InvokeServer(ResearchData)
		if AllDependenciesMet then
			ManageResearchTile(AvailableResearch, ResearchData, ResearchType)
		end	
	end
end)


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------<|Interaction Functions|>-------------------------------------------------------------------------------------------------------

local DepositInteract = game.ReplicatedStorage.Events.HotKeyInteract:WaitForChild("DepositInteract")
local StorageInteract = game.ReplicatedStorage.Events.HotKeyInteract:WaitForChild("StorageInteract")
local DepositInventory = game.ReplicatedStorage.Events.Utility:WaitForChild("DepositInventory")

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

ComputerScreen.Taskbar.UtilityButtons.ShutDown.Activated:Connect(function()
	SelectionMenu.CurrentSelection.Value = ""
	SelectionMenu.CurrentRarity.Value = ""
	SelectionMenu.PreviousSelection.Value = ""

	--Move "back button" back
	ShutDownComputer()
end)

ComputerScreen.Taskbar.UtilityButtons.Home.Activated:Connect(function()
	PrepareAllMenuVisibility()
	MenuSelect.Visible = true
	ChangeTimerActivity(false)
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
	
	ChangeTimerActivity(false)

	wait(.8)
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = game.Players.LocalPlayer.Character:WaitForChild("Humanoid")
	CurrentStorage.InteractedModel.Main.DisplayButtonGUI.Enabled = true
	
	Character.Humanoid.WalkSpeed = DefaultWalkSpeed
	Character.Humanoid.JumpPower = DefaultJumpPower
end

for i,button in pairs (StorageMenu.DataTabSelect:GetChildren()) do
	if button:IsA("ImageButton") then
		SetupTycoonStorageTiles(button)
	end
end
