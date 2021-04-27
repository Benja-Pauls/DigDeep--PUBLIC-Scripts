--(LocalScript)
--Visuals for TycoonComputer GUI that handles player storage and the research menu
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
local GetItemCountSum = game.ReplicatedStorage.Events.Utility:WaitForChild("GetItemCountSum")
local GetCurrentSkillLevel = game.ReplicatedStorage.Events.Utility:WaitForChild("GetCurrentSkillLevel")

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

local PurchaseResearch = game.ReplicatedStorage.Events.Utility:WaitForChild("PurchaseResearch")
local CompleteResearch = game.ReplicatedStorage.Events.Utility:WaitForChild("CompleteResearch")

local SelectedResearch
local SelectedResearchType

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

local function InsertTileInfo(Tile, ResearchData, ResearchType, FinishTime, StatTable)
	if StatTable == nil then
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
				ResearchersList.ChangeResearchView.Visible = false
				
				TileDebounce = false
			end
		end)
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
		end
		CostTile.StatType.Text = StatType
		CostTile.ResearchCost.Text = tostring(StatAmount)
		ColorTileRarity(CostTile, Tile.Rarity.Value)

		if not Discovered then
			CostTile.StatName.Text = "[UNKNOWN]" 
			CostTile.DisplayImage.Image = "rbxgameasset://Images/lock2"
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

function ManageResearchTile(Menu, ResearchData, ResearchType, FinishTime, StatTable)
	if Menu == CurrentResearch and FinishTime then --Guaranteed to only be one page
		local ParentTile
		for i,outlineTile in pairs (CurrentResearch:GetChildren()) do
			if outlineTile:IsA("Frame") or outlineTile:IsA("ImageLabel") then
				if not outlineTile:FindFirstChild("ResearchSlot") and ParentTile == nil then
					ParentTile = outlineTile
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
			
			InsertTileInfo(NewTile, ResearchData, ResearchType, FinishTime)
			
			--Delete tile from available research menu
			local AvailPage,AvailTile = FindPrevAvailableTile(ResearchData)
			if AvailPage and AvailTile then
				CurrentResearch.Visible = true
				AvailableResearch.Visible = true
				CostList.Visible = false
				InfoMenu.Visible = false
				print("TruePosition:",AvailTile.TruePosition.Value)
				ManageTileTruePosition(AvailableResearch, AvailPage, AvailTile, AvailTile.TruePosition.Value, 5, -1)
			end
			
			local ProgressBar = NewTile.ResearchTile.TimerBar.ProgressBar
			ProgressBar.CompleteResearch.Activated:Connect(function()
				CompleteResearch:FireServer(ResearchData["Research Name"], ResearchType)
			end)
			
			ProgressBar.SkipTime.Activated:Connect(function()
				print("skip research activated")
				--robux amount will be updated in ManageTileTimer
				--this will bring up robux charge popup for player to pay robux
			end)
		else
			warn("No tile available for a current research!",ResearchData)
		end
	else --Previous and Available Research
		local NewTile = FindMenuPage(Menu, 5, ResearchData, StatTable)
		NewTile.Active = true
		NewTile.Selectable = true
		InsertTileInfo(NewTile, ResearchData, ResearchType, nil, StatTable)
		
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
							
							if Change == -1 then
								print(tile,"is above the affected tile")
							end
							
							if tile ~= AffectingTile then
								tile.TruePosition.Value = tile.TruePosition.Value + Change
								SlotCount = GetTileSlotCount(page, tile.TruePosition.Value, AffectingTile, Change)
								
								if Change == -1 then
									print(tile.TruePosition.Value,SlotCount)
								end
								
								if SlotCount >= MaxTileAmount then
									if Menu:FindFirstChild("Page" .. tostring(tonumber(CurrentPageNumber) + 1)) then
										Page = Menu:FindFirstChild("Page" .. tostring(tonumber(CurrentPageNumber) + 1))
									else
										Page = game.ReplicatedStorage.GuiElements.ResearchPage:Clone()
										Page.Visible = false
										Page.Name = "Page" .. tostring(tonumber(CurrentPageNumber) + 1)
										Page.Parent = Menu
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
		Menu.NextPage.Active = bool
		Menu.PreviousPage.Active = bool
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

local function GetHighestSlotOfRarity(Page, RarityName)
	local HighestSlotValue = 0
	for i,slot in pairs (Page:GetChildren()) do
		if slot:IsA("TextButton") and string.find(slot.Name, "Slot") then
			if slot.Rarity.Value.Name == RarityName then
				local SlotValue = string.gsub(slot.Name, "Slot", "")
				if tonumber(SlotValue) > HighestSlotValue then
					HighestSlotValue = tonumber(SlotValue)
				end
			end
		end
	end
	return HighestSlotValue
end

local function SeekSlotAvailability(Menu, CheckedPageNumber, RarityName, MaxTileAmount)
	local Page
	local TruePosition
	local SlotCount = 0

	local PossiblePage = Menu:FindFirstChild("Page" .. tostring(CheckedPageNumber))
	local HighestSlotValue = GetHighestSlotOfRarity(PossiblePage, RarityName)

	if HighestSlotValue < MaxTileAmount then --Slot available on rarity page
		Page = PossiblePage
		SlotCount = HighestSlotValue
		TruePosition = GetTileTruePosition(Page, SlotCount, MaxTileAmount)
	else 
		if Menu:FindFirstChild("Page" .. tostring(CheckedPageNumber + 1)) then --go to next page and insert on top
			Page = Menu:FindFirstChild("Page" .. tostring(CheckedPageNumber + 1))
		else --no next page, make a new page
			local NewPage = game.ReplicatedStorage.GuiElements.ResearchPage:Clone()
			NewPage.Visible = false
			NewPage.Name = "Page" .. tostring(CheckedPageNumber + 1)
			NewPage.Parent = Menu
			Page = NewPage
		end
		SlotCount = 0
		TruePosition = GetTileTruePosition(Page, SlotCount, MaxTileAmount)
	end
	
	return Page,TruePosition,SlotCount
end


function GetHighPage(Menu, RarityName)
	local HighPage = 0
	for i,page in pairs (Menu:GetChildren()) do
		if page:IsA("Frame") and string.find(page.Name, "Page") then
			if RarityName then
				local RarityIsPresent = false
				for i,tile in pairs (page:GetChildren()) do
					if not RarityIsPresent then
						if tile:IsA("TextButton") and string.find(tile.Name, "Slot") then
							local TileRarityInfo = tile.Rarity.Value
							if TileRarityInfo.Name == RarityName then
								RarityIsPresent = true
							end
						end 
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

local function FindNearbyRarity(Menu, RarityInfo, OrderValue, Change)
	local CheckedRarity
	for i,rarity in pairs (RarityInfo.Parent:GetChildren()) do
		if rarity:IsA("Color3Value") and CheckedRarity == nil then
			if rarity.Order.Value == OrderValue + Change then
				CheckedRarity = rarity.Name
			end
		end
	end
	
	local HighPage = GetHighPage(Menu, CheckedRarity)
	if HighPage ~= 0 then --tile of rarity exists
		return HighPage,CheckedRarity
	else --Continue searching lower/higher rarities
		if OrderValue ~= 0 or OrderValue ~= GetHighPage(Menu) then
			return FindNearbyRarity(Menu, RarityInfo, OrderValue + Change, Change)
		else
			return nil
		end
	end
end

function FindMenuPage(Menu, MaxTileAmount, ResearchData, StatTable)
	--PAGE SORTING STRATEGY:
	--if 0 pages, make the first page
	--Otherwise, look for pages with rarity in them
	--if one is available, check if slot available
	--(function)
	--if slot, insert and move tiles below
	--if no slot, put in next page
	--if no next page, make a new page

	--if no pages with rarity, look for page with order value less
	--if found, put tile at end and move any with higher order value (do slot checks above)
	--if none available, look for one with order value more
	--if found, put tile at top and move any with higher order value
	
	local Pages = Menu:GetChildren()
	
	local RarityName
	local StatInfo
	if StatTable == nil then
		StatInfo = ResearchData
		RarityName = StatInfo["Rarity"]
	else
		StatInfo = StatTable[1]
		if StatInfo["GUI Info"]:FindFirstChild("RarityName") then
			RarityName = StatInfo["GUI Info"].RarityName.Value
		else
			RarityName = "DisplayFirst"
		end
	end
	local RarityInfo = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(RarityName)
	local RarityOrderValue = RarityInfo.Order.Value
	
	local PageCount = GetHighPage(Menu)
	
	local Page
	local TruePosition
	local SlotCount = 0 --Position reference, +1 for name (Count=0: "Slot1")
	if PageCount > 0 then
		local HighRarityPage = GetHighPage(Menu, RarityName)
		
		if HighRarityPage ~= 0 then --Tile already exists for rarity
			Page,TruePosition,SlotCount = SeekSlotAvailability(Menu, HighRarityPage, RarityName, MaxTileAmount)
		else --No tiles with rarity exist, connect with associated rarities
			--Look for lesser rarity to reference
			local LesserRarityPage,LesserRarityName = FindNearbyRarity(Menu, RarityInfo, RarityOrderValue, -1)
			if LesserRarityPage then
				Page,TruePosition,SlotCount = SeekSlotAvailability(Menu, LesserRarityPage, LesserRarityName, MaxTileAmount)
			else
				--Look for higher rarity to reference
				local HigherRarityPage,HigherRarityName = FindNearbyRarity(Menu, RarityInfo, RarityOrderValue, 1)
				if HigherRarityPage then
					Page,TruePosition,SlotCount = SeekSlotAvailability(Menu, HigherRarityPage, HigherRarityName, MaxTileAmount)
				end
			end
		end
	else --No pages even available, make new page
		local NewPage = game.ReplicatedStorage.GuiElements.ResearchPage:Clone()
		NewPage.Visible = true
		NewPage.Name = "Page1"
		NewPage.Parent = Menu
		Page = NewPage
		SlotCount = 0
		TruePosition = 0
	end
	print("Final slot identifier values for " .. RarityName .. " are: PTS -->",Page,TruePosition,SlotCount)

	local NewTile = game.ReplicatedStorage.GuiElements.ResearchSlot:Clone()
	NewTile.Name = "Slot" .. tostring(SlotCount + 1)
	NewTile.Rarity.Value = RarityInfo
	NewTile.TruePosition.Value = TruePosition
	NewTile.Parent = Page
	
	ManageTileTruePosition(Menu, Page, NewTile, TruePosition, MaxTileAmount, 1)
	
	return NewTile
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

ResearchersList.ChangeResearchView.Activated:Connect(function()
	if CurrentResearch.Visible then
		CurrentResearch.Visible = false
		PreviousResearch.Visible = true
		UpdatePageDisplay(PreviousResearch, true)
		ResearchersList.PreviousResearchPages.Visible = true
		
		ResearchersList.CurrentMenuLabel.Visible = false
		ResearchersList.PreviousMenuLabel.Visible = true
		ResearchersList.ChangeResearchView.ButtonLabel.Text = "Current Research"
	else
		CurrentResearch.Visible = true
		PreviousResearch.Visible = false
		UpdatePageDisplay(PreviousResearch, false)
		ResearchersList.PreviousResearchPages.Visible = false
		
		ResearchersList.CurrentMenuLabel.Visible = true
		ResearchersList.PreviousMenuLabel.Visible = false
		ResearchersList.ChangeResearchView.ButtonLabel.Text = "Previous Research"
	end
end)

InfoMenu.ResearchButton.Activated:Connect(function()
	InfoMenu.ResearchButton.Active = false
	--Disable research button and reenable it when event is fired back to client
	
	PurchaseResearch:FireServer(SelectedResearch["Research Name"], SelectedResearchType)
	
	
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

ComputerScreen.Taskbar.Shutdown.Activated:Connect(function()
	SelectionMenu.CurrentSelection.Value = ""
	SelectionMenu.CurrentRarity.Value = ""
	SelectionMenu.PreviousSelection.Value = ""

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

for i,button in pairs (StorageMenu.DataTabSelect:GetChildren()) do
	if button:IsA("ImageButton") then
		SetupTycoonStorageTiles(button)
	end
end

