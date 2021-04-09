--(LocalScript)
--Visuals for data menu associated with items inside of the tycoon's (business) storage
-----------------------------------------------------------------------------------------------------------------------------------------------
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local PlayerGui = Player:WaitForChild("PlayerGui")
local StarterGui = game:GetService("StarterGui")

local TycoonComputerGui = script.Parent
local ComputerScreen = TycoonComputerGui.ComputerScreen
local MenuSelect = ComputerScreen.MenuSelect

local StorageMenu = ComputerScreen.StorageMenu
local SelectionMenu = StorageMenu.SelectionMenu
local ItemsPreview = StorageMenu.ItemsPreview
local DataTabSelect = StorageMenu.DataTabSelect
--local BackButton = ComputerScreen.Taskbar.BackButton
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

---------------<Utility>-----------------------------------------------------------------------------------------------------------------------------

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

local function DataTabButtonActiveState(State)
	for i,button in pairs (DataTabSelect:GetChildren()) do
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
	ComputerScreen.Taskbar.Visible = true
end)

----------------------------<|Tycoon Storage GUI Functions|>---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Prepare DataTab Buttons
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
		--BackButton:TweenPosition(UDim2.new(BackButton.Position.X.Scale, 0, 0, 0), "Out", "Quint", 0.5)
		ReadySelectionMenu(StorageMenu.ItemsPreview:FindFirstChild(MenuName))
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

function UpdateTileLock (tile, StatValue)
	if StatValue == true then
		tile.LockImage.Visible = false
	else
		tile.LockImage.Visible = true
	end
end

------------------------<|Tile Selection Buttons|>------------------------------------

local CurrentMenu
function ReadySelectionMenu(Menu)
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
local SellItem = game.ReplicatedStorage.Events.Utility.SellItem

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

--[[ (Removed for now to rework GUI)
BackButton.Activated:Connect(function()
	DataTabButtonActiveState(false)
	ItemsPreview.Visible = false
	SelectionMenu.Visible = false
	SelectionMenu.SellMenu.Visible = false
	
	BackButton:TweenPosition(UDim2.new(BackButton.Position.X.Scale, 0, 1, 0), "Out", "Quint", 0.5)
	wait(.5)
	
	DataTabButtonActiveState(true)
end)
]]

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

-------------------------------------------<|Tycoon Research GUI Functions|>-----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local UpdateResearch = game.ReplicatedStorage.Events.GUI:WaitForChild("UpdateResearch")
UpdateResearch.OnClientEvent:Connect(function()
	
	--Would this also have to be updated in purchase handler or would the PlayerStatManager
	--assign the appropriate values
	
	--Basically, what will know what is purchased and to make sure the dependencies are met for what's
	--next physically and not just graphically
	
end)



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

