--(LocalScript)
--Visuals for data menu associated with items inside of the tycoon's (business) storage
-----------------------------------------------------------------------------------------------------------------------------------------------
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local LocalLoadTycoon = game.ReplicatedStorage.Events.Tycoon.LocalLoadTycoon
local MoveAllBaseScreenUI = game.ReplicatedStorage.Events.GUI.MoveAllBaseScreenUI
local ComputerIsOn = false
local TweenService = game:GetService("TweenService")
local HumanoidRootPart = game.Workspace.Players:WaitForChild(tostring(Player)):WaitForChild("HumanoidRootPart")
local CurrentStorage

local TycoonStorageGui = script.Parent
local ComputerScreen = TycoonStorageGui.ComputerScreen
local SelectionMenu = TycoonStorageGui.ComputerScreen.SelectionMenu
local BackButton = ComputerScreen.Taskbar.BackButton
local FadeOut = ComputerScreen.FadeOut

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
	TycoonStorageGui.ComputerScreen.Visible = false
	SelectionMenu.Visible = false
	
	ShutDownCutscene()
end

function SetUpCredentials()
	--Get playeruser id from interacter
	local PlayerUserId = Player.UserId
	
	local stringTime = "%I:%M %p"
	local timestamp = os.time()
	ComputerScreen.CredentialsScreen.Time.Text = tostring(os.date(stringTime, timestamp))
	
	local PlayerThumbnail = ComputerScreen.CredentialsScreen.PlayerThumbnail
	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size420x420
	local PlayerProfilePicture = Players:GetUserThumbnailAsync(PlayerUserId, thumbType, thumbSize)
	PlayerThumbnail.Image = PlayerProfilePicture
	
	ComputerScreen.DataTabSelect.Visible = false
	ComputerScreen.SelectionMenu.Visible = false
	ComputerScreen.ItemsPreview.Visible = false
	ComputerScreen.Taskbar.Visible = false
	ComputerScreen.CredentialsScreen.Visible = true
	
	ComputerScreen.CredentialsScreen.Username.Text = tostring(Player)
	
	--Fade-in login screen
	
	local PasswordInput = ComputerScreen.CredentialsScreen.Password
	local KeyboardSound = script.Parent.KeyboardClick
	for i = 1,4,1 do
		PasswordInput:FindFirstChild(tostring(i)).Visible = false
	end
	for t = 1,20,1 do
		wait(.02)
		FadeOut.BackgroundTransparency = FadeOut.BackgroundTransparency + 0.05
	end
	for i = 1,4,1 do
		wait(1/i-.1)
		if KeyboardSound.Playing then
			KeyboardSound:Stop()
		end
		KeyboardSound:Play()
		PasswordInput:FindFirstChild(tostring(i)).Visible = true
	end
	wait(1)
	
	ComputerScreen.DataTabSelect.Visible = true
	BackButton.Position = UDim2.new(BackButton.Position.X.Scale, 0, 1, 0)
	ComputerScreen.CredentialsScreen:TweenPosition(UDim2.new(-0.017,0,-1.3,0), "Out", "Quint", .5)
	ComputerScreen.Taskbar.Visible = true
	wait(.5)
	
	ComputerScreen.CredentialsScreen.Visible = false
	ComputerScreen.CredentialsScreen.Position = UDim2.new(-0.017,0,-0.031,0)
	
	OpenDataTabScreen()
end

local ItemsPreview = TycoonStorageGui.ComputerScreen.ItemsPreview
local DataTabSelect = TycoonStorageGui.ComputerScreen.DataTabSelect
function OpenDataTabScreen() --Problem, with every time it opens: repeats button press
	local stringTime = "%I:%M %p"
	local timestamp = os.time()
	ComputerScreen.Taskbar.Time.Text = tostring(os.date(stringTime, timestamp))
	
	local BeepSound = script.Parent.Beep
	SelectionMenu.Visible = false
	ItemsPreview.Visible = false
	for i,button in pairs (DataTabSelect:GetChildren()) do
		if button:IsA("ImageButton") then --and tostring(button) ~= "ShutDown" then
			button.Activated:Connect(function()
				if DataTabSelect.Visible == true and SelectionMenu.Visible == false then
					BeepSound:Play()
					OpenAffiliatedItemPreview(button)
				end
			end)
		end
	end
end

ComputerScreen.Taskbar.ShutDown.Activated:Connect(function()
	SelectionMenu.CurrentSelection.Value = ""
	SelectionMenu.CurrentRarity.Value = ""
	SelectionMenu.PreviousSelection.Value = ""
	--Move "back button" back
	ShutDownComputer()
end)

function OpenAffiliatedItemPreview(button)
	local MenuName = button.Name
	if TycoonStorageGui.ComputerScreen.ItemsPreview:FindFirstChild(MenuName) then
		TycoonStorageGui.ComputerScreen.SelectionMenu.Visible = true
		local ItemsPreview = TycoonStorageGui.ComputerScreen.ItemsPreview
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
		BackButton:TweenPosition(UDim2.new(BackButton.Position.X.Scale, 0, 0, 0), "Out", "Quint", 0.5)
		ReadySelectionMenu(TycoonStorageGui.ComputerScreen.ItemsPreview:FindFirstChild(MenuName))
	end
end

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


--------------<Current Selection Info>----------------------------------------------------------------------------------------------------------------

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
		SelectionMenu:FindFirstChild("Name").Text = tostring(tile)
		SelectionMenu.Amount.Text = tostring(tile.AmountInStorage.Value)
		SelectionMenu.UnitPrice.Text = tostring(ItemInformation.CurrencyValue.Value)
		tile.AmountInStorage.Changed:Connect(function()
			if tostring(tile) == SelectionMenu.CurrentSelection.Value then
				SelectionMenu.Amount.Text = tostring(tile.AmountInStorage.Value)
			end
		end)
	else
		SelectionMenu:FindFirstChild("Name").Text = "[Locked]"
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


--------------<Tile Selection Buttons>---------------------------------------------------------------------
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
				
				SelectionMenu:FindFirstChild("Name").Visible = Discovered
				SelectionMenu.UnitPrice.Visible = Discovered
				SelectionMenu.Hint.Visible = not Discovered
				
				if ItemInformation then
					if Discovered then
						SelectionMenu:FindFirstChild("Name").Text = tostring(item)
						SelectionMenu.Picture.Image = ItemInformation["GUI Info"].StatImage.Value
						SelectionMenu.UnitPrice.Text = tostring(ItemInformation.CurrencyValue.Value)
						
						while SelectionMenu.CurrentSelection.Value == tostring(item) do
							SelectionMenu.Amount.Text = tostring(item.AmountInStorage.Value)
							wait()
						end
					else
						SelectionMenu:FindFirstChild("Name").Text = "[LOCKED]"
						SelectionMenu.Picture.Image = "rbxgameasset://Images/lock1"
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

local SellMenu = ComputerScreen.SelectionMenu.SellMenu
local SellItem = game.ReplicatedStorage.Events.Utility.SellItem

SelectionMenu.SelectItem.Activated:Connect(function()
	if SelectionMenu.Visible == true then
		local ItemName = SelectionMenu.CurrentSelection.Value
		local ItemAmount = tonumber(SelectionMenu.Amount.Text)
		SellMenu.MaxAmount.Value = ItemAmount
		
		local ItemInfo = FindItemInfo(ItemName, tostring(CurrentMenu))
		
		if ItemInfo then
			SellMenu.SelectedItem.Value = ItemInfo
			SellMenu.Visible = true	
			SellMenu.SnapAmount.Value = math.ceil(SellMenu.SliderBar.AbsoluteSize.X/(ItemAmount)) --+1 for 0th
			SellMenu.SellAll.Text = "Sell All: $" .. tostring(tonumber(ItemAmount*SellMenu.SelectedItem.Value.CurrencyValue.Value))
			
			CalculateSliderPosition()
		end
	end
end)

BackButton.Activated:Connect(function()
	ItemsPreview.Visible = false
	SelectionMenu.Visible = false
	SelectionMenu.SellMenu.Visible = false
	BackButton:TweenPosition(UDim2.new(BackButton.Position.X.Scale, 0, 1, 0), "Out", "Quint", 0.5)
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
		
		--local NumberOfRarities = #ItemsPreview:FindFirstChild(tostring(Menu)):GetChildren()
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
				--end
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


--------------<Slider Interaction>-----------------------------------------------------------------------------

local sliderBar = SellMenu.SliderBar
local slider = sliderBar:WaitForChild("Slider")
local Mouse = game.Players.LocalPlayer:GetMouse()
local selectedAmount = SellMenu.SelectedAmount

local movingSlider = false

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

	local roundedAbsSize = math.ceil(sliderBar.AbsoluteSize.X / snapAmount) * snapAmount
	local roundedOffsetClamped = (xOffsetClamped / snapAmount) * snapAmount --highest amount slider can achieve
	local Percentage = roundedOffsetClamped / roundedAbsSize
	
	amountToSellPercent = Percentage
	local GUIamountToSell = math.ceil(Percentage*SellMenu.MaxAmount.Value)

	selectedAmount.Text = tostring(GUIamountToSell) .. " " .. tostring(SellMenu.SelectedItem.Value)
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


--------------<Tile Management>--------------------------------------------------------------------------------

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

function MoveOtherRaritiesDown(RarityMenu)
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

-------------------------------------------------<|Storage Depositing|>---------------------------------------------------------------------------------------------------------------

local DepositInteract = game.ReplicatedStorage.Events.HotKeyInteract:WaitForChild("DepositInteract")
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
		TycoonStorageGui.DepositNotify.Visible = true
		TycoonStorageGui.DepositNotify:TweenPosition(UDim2.new(0.358,0,0.85,0), "Out", "Quint", 1)
		wait(1)
		TycoonStorageGui.DepositNotify:TweenPosition(UDim2.new(0.358,0,1.1,0), "In", "Quint", 1.5)
		wait(3)
		TycoonStorageGui.DepositNotify.Visible = false

		repeatDebounce = false	
	end	
end

DepositInteract.Event:Connect(HandleDepositInventory)

-------------<E Interaction>---------------------------------------------------------------------------
local UIS = game:GetService("UserInputService")
local Mouse = Player:GetMouse()

--[[
function EInteract()
	local debounce2 = false
	UIS.InputBegan:Connect(function(input)
		if debounce2 == true and not ComputerIsOn then
			if input.KeyCode == Enum.KeyCode.E then
				if Mouse.Target and (Mouse.Target.Position - HumanoidRootPart.Position).magnitude < 20 then
					if Mouse.Target:IsDescendantOf(CurrentStorage) then
						ComputerIsOn = true
						CurrentStorage.InteractedModel:WaitForChild("E GUI").Enabled = false
						local InteractedModel = Mouse.Target
						StartUpCutscene()
						CurrentStorage.InteractedModel:WaitForChild("E GUI").Enabled = true
					end
				end
			end
		end
	end)

	--Graphical
	while true do
		wait(.1)
		
		if debounce2 == true and CurrentStorage.InteractedModel:WaitForChild("E GUI").Enabled == true then
			CurrentStorage.InteractedModel:WaitForChild("E GUI").Enabled = false
			debounce2 = false
		end
		
		if Mouse.Target then
			if (Mouse.Target.Position - HumanoidRootPart.Position).magnitude < 20 then
				if Mouse.Target:IsDescendantOf(workspace.Storages.Computers) then
					for i,storage in pairs (workspace.Storages.Computers:GetChildren()) do
						if Mouse.Target:IsDescendantOf(storage) then
							CurrentStorage = storage
							if debounce2 == false then
								debounce2 = true
								CurrentStorage.InteractedModel:WaitForChild("E GUI").Enabled = true
							end
						end
					end
				end
			end
		end
	end
end
]]

---------------------------------------------------<|Cutscene Manager|>-----------------------------------------------------------------------------------------------------------
local Camera = game.Workspace.CurrentCamera

function MoveCamera(StartPart, EndPart, Duration, EasingStyle, EasingDirection)
	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.CFrame = StartPart.CFrame
	local Cutscene = TweenService:Create(Camera, TweenInfo.new(Duration, EasingStyle, EasingDirection), {CFrame = EndPart.CFrame})
	Cutscene:Play()
	wait(Duration)
end

--CUTSCENE VIDEO TUTORIAL:
--https://www.bing.com/videos/search?q=roblox+2020+cutscene+editor&&view=detail&mid=BEC7BCBD747366BD75C8BEC7BCBD747366BD75C8&rvsmid=E7AB6D6F25AAAC254ED0E7AB6D6F25AAAC254ED0&FORM=VDRVRV
local StorageInteract = game.ReplicatedStorage.Events.HotKeyInteract:WaitForChild("StorageInteract")

function StartUpCutscene(promptObject)
	CurrentStorage = promptObject.Parent.Parent.Parent
	promptObject.Enabled = false
	
	local CutsceneFolder = CurrentStorage:FindFirstChild("CutsceneCameras")
	MoveCamera(Camera, CutsceneFolder.Camera1, 1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	MoveAllBaseScreenUI:Fire("Hide") --Move "surface screen" tiles away
	MoveCamera(CutsceneFolder.Camera1, CutsceneFolder.Camera2, .7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	
	StartUpComputer()
end

StorageInteract.Event:Connect(StartUpCutscene)

function ShutDownCutscene()
	local CutsceneFolder = CurrentStorage:FindFirstChild("CutsceneCameras")
	MoveCamera(CutsceneFolder.Camera2, CutsceneFolder.Camera1, .7, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	MoveAllBaseScreenUI:Fire("Show")

	wait(.8)
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = game.Players.LocalPlayer.Character:WaitForChild("Humanoid")
	CurrentStorage.InteractedModel.Main.DisplayButtonGUI.Enabled = true
	
end

for i,button in pairs (TycoonStorageGui.ComputerScreen.DataTabSelect:GetChildren()) do
	if button:IsA("ImageButton") then
		SetupTycoonStorageTiles(button)
	end
end

