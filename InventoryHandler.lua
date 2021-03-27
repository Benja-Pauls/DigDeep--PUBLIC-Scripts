--(LocalScript)
--Inventory graphical menu handler
-------------------------------------------------------------------------------------------------------------------------------------------------
local Player = game.Players.LocalPlayer
local PlayerUserId = Player.UserId
local OpenDataMenuButton = script.Parent.OpenDataMenuButton
local DataMenu = script.Parent.DataMenu
local TweenService = game:GetService("TweenService")
local GuiElements = game.ReplicatedStorage.GuiElements
local PageManager = DataMenu.PageManager

local EventsFolder = game.ReplicatedStorage.Events
local MoveAllBaseScreenUI = EventsFolder.GUI:WaitForChild("MoveAllBaseScreenUI")

if DataMenu.Visible == true then
	DataMenu.Visible = false
end

OpenDataMenuButton.Active = false --re-enable when script is ready

for i,v in pairs (DataMenu:GetChildren()) do
	if v:IsA("Frame") and tostring(v) ~= "TopTabBar" then
		v.Visible = false
	end
end

local InventoryOpens = 0
OpenDataMenuButton.Activated:Connect(function()
	if DataMenu.Visible == false then
		DataMenu.Position = UDim2.new(0.126, 0, -.8, 0)
		DataMenu.Visible = true
		DataMenu.PlayerMenu.Visible = true
		OpenDataMenuButton.Active = false
		DataMenu.PlayerMenu.Visible = true
		DataMenu:TweenPosition(UDim2.new(0.126, 0, 0.141, 0), "Out", "Quint", .5)
		wait(.5)
		
		--Manage Tabs
		if InventoryOpens == 0 then
			InventoryOpens = 1
			DataMenu.InventoryMenu.SelectedBagInfo.Visible = false
			ReadyMenuButtons(DataMenu)
			ReadyMenuButtons(DataMenu.PlayerMenu) --Prep menu buttons on default screen
		else
			CleanupMenuTabs(DataMenu)
		end
		
		DataMenu.PlayerMenu.Visible = true
		for i,menu in pairs (DataMenu.PlayerMenu["Default Menu"]:GetChildren()) do
			menu.Visible = true
		end
		
		OpenDataMenuButton.Active = true
		
	elseif DataMenu.Visible == true then
		OpenDataMenuButton.Active = false
		DataMenu:TweenPosition(UDim2.new(0.126, 0, -0.8, 0), "Out", "Quint", .5)
		wait(.5)
		DataMenu.Visible = false
		DataMenu.Position = UDim2.new(0.126, 0, 0.141, 0)
		PageManager.Visible = false
		DataMenu.ItemViewer.Visible = false
		
		OpenDataMenuButton.Active = true
	end
end)

MoveAllBaseScreenUI.Event:Connect(function(ChangeTo)
	DataMenu.Visible = false
	if ChangeTo == "Hide" then
		OpenDataMenuButton:TweenPosition(UDim2.new(-.1, 0, OpenDataMenuButton.Position.Y.Scale, 0), "Out", "Quint", 1)
	else
		OpenDataMenuButton:TweenPosition(UDim2.new(0.01, 0, 0.8, 0), "Out", "Quint", 1)
	end
end)

--------------<|Utility Functions|>-----------------------------------------------------------------------------

local ItemViewerOpen = false
local PageDebounce = false
local ButtonPresses = {}

local MenuAcceptance = true
function ReadyMenuButtons(Menu)
	if MenuAcceptance == true then
		MenuAcceptance = false
		for i,button in pairs(Menu:GetChildren()) do
			if (button:IsA("TextButton") or button:IsA("ImageButton")) and button:FindFirstChild("Menu") then
				ButtonPresses[button] = 0
				local AssociatedMenuName = button:FindFirstChild("Menu").Value
				local ButtonMenu = Menu:FindFirstChild(AssociatedMenuName)
				
				--Prep Default Menu 
				if ButtonMenu.Name ~= "PlayerMenu" then
					ButtonMenu.Visible = false
				else
					ButtonMenu.Visible = true
					UpdateBagDisplays(Menu, ButtonMenu)		
				end
				
				button.Activated:Connect(function()
					print(tostring(button) .. " has been activated")
					DataMenu.InventoryMenu.EmptyNotifier.Visible = false
					for i,v in pairs (ButtonMenu.Parent:GetChildren()) do
						if not v:IsA("TextButton") and not v:IsA("ImageButton") and not v:IsA("Folder") and not v:FindFirstChild("Menu") then
							if tostring(v) ~= "TopTabBar" then
								v.Visible = false
							end
						end
					end

					ButtonMenu.Visible = true
					if Menu.Name == "InventoryMenu" then --Display Bag Info
						local BagCapacity = ButtonMenu:GetAttribute("BagCapacity")
						local ItemCount = ButtonMenu:GetAttribute("ItemCount")
						Menu.SelectedBagInfo.Text = tostring(ItemCount) .. "/" .. tostring(BagCapacity)
						Menu.SelectedBagInfo.BagType.Text = string.gsub(tostring(ButtonMenu), "Menu", "")
						Menu.SelectedBagInfo.Visible = true
					elseif Menu.Name == "PlayerMenu" then
						for i,gui in pairs (Menu:GetChildren()) do
							if gui:IsA("ImageButton") and string.find(tostring(gui), "Bag") then
								gui.Visible = false	
							end
						end
					end

					if tostring(ButtonMenu) == "PlayerMenu" then
						for i,gui in pairs (ButtonMenu:GetChildren()) do
							if gui:IsA("ImageButton") and string.find(tostring(gui), "Bag") then
								gui.Visible = true
							end
						end
					end

					if Menu.Parent == DataMenu then --Menu of button
						PageManager.Menu.Value = ButtonMenu
						local PageCount = CountPages()
						if PageCount > 0 then
							PageManager.Visible = true
							if ButtonMenu:FindFirstChild("Page1") then
								FinalizePageChange(ButtonMenu.Page1)
							end
						else --Player has no items of this type
							print("Menu has no pages!")
							ButtonMenu.Parent.EmptyNotifier.Visible = true
							
							--if button:IsDescendantOf(DataMenu.PlayerMenu) then
								--Empty notifier specific for PlayerMenu
							--else
							--	DataMenu.InventoryMenu.EmptyNotifier.Visible = true
							--end
						end
					else
						--PageManager.Menu.Value = nil
						PageManager.Visible = false
					end

					DataMenu.ItemViewer.Visible = false
					ItemViewerOpen = false
					PageManager.CurrentPage.Value = 1

					if ButtonPresses[button] == 0 then
						ButtonPresses[button] = 1
						ReadyMenuButtons(ButtonMenu)
					else
						CleanupMenuTabs(ButtonMenu)
					end
				end)
				
			end
		end
		wait(.1)
		MenuAcceptance = true
	end
end

function CleanupMenuTabs(Menu)
	
	--Prep Default Menu
	if Menu.Name == "DataMenu" or Menu.Name == "PlayerMenu" then
		for i,gui in pairs (DataMenu.PlayerMenu:GetChildren()) do
			if gui:IsA("ImageButton") and string.find(tostring(gui), "Bag") then
				gui.Visible = true
			elseif gui:IsA("Frame") and string.find(tostring(gui), "Menu") then
				gui.Visible = false
			end
		end
	end
	
	for i,button in pairs(Menu:GetChildren()) do
		if (button:IsA("TextButton") or button:IsA("ImageButton")) and button:FindFirstChild("Menu") then
			local AssociatedMenuName = button:FindFirstChild("Menu").Value
			local ButtonMenu = Menu:FindFirstChild(AssociatedMenuName)

			if Menu.Name == "PlayerMenu" then
				ButtonMenu.Visible = false
			end
			
			ButtonMenu.Visible = false
			if Menu == DataMenu.InventoryMenu then
				DataMenu.InventoryMenu.SelectedBagInfo.Visible = false
			end
		end
	end
end

local function GetStatImage(StatInfo)
	local ImageId
	if StatInfo then
		ImageId = StatInfo["GUI Info"].StatImage.Value
	end
	return ImageId
end

local function FindStatLevel(StatInfo, EXPValue)
	local CurrentLevel = 0
	for i,level in pairs (StatInfo.Levels:GetChildren()) do
		if tonumber(EXPValue) >= level.Value and tonumber(level.Name) > CurrentLevel then
			CurrentLevel = tonumber(level.Name)
		end
	end
	local NextLevel
	if StatInfo.Levels:FindFirstChild(tostring(CurrentLevel + 1)) then
		NextLevel = StatInfo.Levels:FindFirstChild(tostring(CurrentLevel + 1))
	else
		NextLevel = StatInfo.Levels:FindFirstChild(tostring(CurrentLevel))
	end
	return CurrentLevel,NextLevel
end


--------------<|PageManager Functions|>---------------------------------------------------------------------------------

function ManagePageInvis(VisiblePage) --Use this in more places than page management?
	for i,page in pairs (VisiblePage.Parent:GetChildren()) do
		if page:IsA("Frame") then
			if page ~= VisiblePage then
				page.Visible = false
			else
				page.Visible = true
			end
		end
	end
	VisiblePage.ZIndex -= 1
	PageDebounce = false
end

function CountPages()
	local HighPage = 0
	for i,page in pairs (PageManager.Menu.Value:GetChildren()) do
		if page:IsA("Frame") then
			local PageNumber = string.gsub(page.Name, "Page", "")
			if tonumber(PageNumber) > HighPage then
				HighPage = tonumber(PageNumber)
			end
		end
	end
	return HighPage
end

function FinalizePageChange(Page)
	PageDebounce = true
	local RarityName = Page.Rarity.Value
	if GuiElements.RarityColors:FindFirstChild(RarityName) then
		local Rarity = GuiElements.RarityColors:FindFirstChild(RarityName)
		PageManager.PageRarityDisplay.Text = RarityName .. " " .. string.gsub(PageManager.Menu.Value.Name, "Menu", "")
		PageManager.PageRarityDisplay.TextColor3 = Rarity.Value
		PageManager.PageRarityDisplay.TextStrokeColor3 = Rarity.TileColor.Value
		for i,tile in pairs (Page:GetChildren()) do
			if tile:IsA("TextButton") or tile:IsA("ImageButton") then
				tile.BackgroundColor3 = Rarity.TileColor.Value
			end
		end
		local ButtonWidth = 0.33
		if PageManager.PageRarityDisplay.Visible == false then
			PageManager.Previous.Size = UDim2.new(ButtonWidth,0,1,0)
			PageManager.Next.Position = UDim2.new(ButtonWidth + 0.005,0,0,0)
			PageManager.Next.Size = UDim2.new(ButtonWidth,0,1,0)
			PageManager.PageRarityDisplay.Visible = true
		end
	else
		--For tiles without rarity distinguishability (no page names)
		local ButtonWidth = 0.502
		if PageManager.PageRarityDisplay.Visible == true then
			PageManager.Previous.Size = UDim2.new(ButtonWidth,0,1,0)
			PageManager.Next.Position = UDim2.new(ButtonWidth + 0.005,0,0,0)
			PageManager.Next.Size = UDim2.new(ButtonWidth,0,1,0)
			PageManager.PageRarityDisplay.Visible = false
		end
	end
	Page.ZIndex += 1
	Page.Visible = true
	Page:TweenPosition(UDim2.new(0,0,0,0), "Out", "Quint", .25)
	wait(.25)
	ManagePageInvis(Page)
end

PageManager.Previous.Activated:Connect(function()
	if PageDebounce == false then
		local HighPage = CountPages()
		local Menu = PageManager.Menu.Value
		if HighPage ~= 1 then --only one page
			local NewPage
			if PageManager.CurrentPage.Value - 1 == 0 then
				NewPage = Menu:FindFirstChild("Page" .. tostring(HighPage))
				PageManager.CurrentPage.Value = HighPage
			else
				NewPage = Menu:FindFirstChild("Page" .. tostring(PageManager.CurrentPage.Value-1))
				PageManager.CurrentPage.Value = PageManager.CurrentPage.Value-1
			end
			
			NewPage.Position = UDim2.new(-1,0,0,0)
			FinalizePageChange(NewPage)
		else --Bounce effect
			PageDebounce = true
			Menu:FindFirstChild("Page1"):TweenPosition(UDim2.new(-.03,0,0,0), "Out", "Quint", .1)
			wait(.1)
			Menu:FindFirstChild("Page1"):TweenPosition(UDim2.new(0,0,0,0), "Out" , "Bounce", .25)
			wait(.25)
			PageDebounce = false
		end
	end
end)

PageManager.Next.Activated:Connect(function()
	if PageDebounce == false then
		local HighPage = CountPages()
		local Menu = PageManager.Menu.Value
		if HighPage ~= 1 then --only one page
			local NewPage
			if PageManager.CurrentPage.Value + 1 > HighPage then
				NewPage = Menu:FindFirstChild("Page1")
				PageManager.CurrentPage.Value = 1
			else
				NewPage = Menu:FindFirstChild("Page" .. tostring(PageManager.CurrentPage.Value+1))
				PageManager.CurrentPage.Value = PageManager.CurrentPage.Value+1
			end
			
			NewPage.Position = UDim2.new(1,0,0,0)
			FinalizePageChange(NewPage)
		else --Bounce effect
			PageDebounce = true
			Menu:FindFirstChild("Page1"):TweenPosition(UDim2.new(.03,0,0,0), "Out", "Quint", .1)
			wait(.1)
			Menu:FindFirstChild("Page1"):TweenPosition(UDim2.new(0,0,0,0), "Out" , "Bounce", .25)
			wait(.25)
			PageDebounce = false
		end
	end
end)

DataMenu.ItemViewer.BackButton.Activated:Connect(function()
	if DataMenu.ItemViewer.Visible == true then
		DataMenu.ItemViewer.Visible = false
		ItemViewerOpen = false
	end
end)

--Creates pages for tiles to be held (tiles managed by ManageTiles())
local function FindStatPage(Stat, Menu, MaxTileAmount, RaritySort, AcquiredLocation)
	local Pages = Menu:GetChildren()
	
	local StatRarity
	if RaritySort then
		StatRarity = game.ReplicatedStorage.ItemLocations:FindFirstChild(AcquiredLocation):FindFirstChild(Stat)["GUI Info"].RarityName.Value
	else --Pages Not Sorted
		StatRarity = "No Rarity"
	end
	
	local Page
	local Over
	local SlotCount = 0
	local found = false
	for i,page in pairs (Pages) do	
		if page.Rarity.Value == StatRarity then
			--print("Found existing page for " .. tostring(StatRarity))

			for i,slot in pairs (page:GetChildren()) do
				if slot:IsA("TextButton") or slot:IsA("ImageButton") then
					SlotCount = SlotCount + 1
				end
			end

			if SlotCount < MaxTileAmount then
				found = true
				Page = page
			else
				Over = page --Too many tiles on rarity page
			end
		end
	end
	
	if found == false then
		--print("Making new page since " .. tostring(Stat) .. " has rarity " .. tostring(StatRarity))
		
		local NewPage = GuiElements.MenuPage:Clone()
		NewPage.Rarity.Value = StatRarity
		if Over then --Group Page With Rarity
			local LastRarityPage = string.gsub(Over.Name, "Page" , "")
			NewPage.Name = "Page" .. tostring(tonumber(LastRarityPage) + 1)
			
		elseif not Over and StatRarity ~= "No Rarity" then --No Page of Rarity Exists, Must Sort Rarities by Order
			--Sort by rarity
			local HighestLowerRarityPage = 0
			
			local RarityOrder = GuiElements.RarityColors:FindFirstChild(StatRarity).Order.Value
			if RarityOrder > 1 then
				for i,rarity in pairs (GuiElements.RarityColors:GetChildren()) do
					if rarity.Order.Value < RarityOrder then
						for i,page in pairs (Pages) do
							if page:IsA("Frame") then
								if page.Rarity.Value == tostring(rarity) then
									local PageNumber = string.gsub(page.Name, "Page" , "")
									if HighestLowerRarityPage < tonumber(PageNumber) then
										HighestLowerRarityPage = tonumber(PageNumber)
									end
								end
							end
						end
					end
				end

				if HighestLowerRarityPage ~= 0 then
					for i,page in pairs (Pages) do
						if page:IsA("Frame") then
							local PageNumber = string.gsub(page.Name, "Page", "")
							if tonumber(PageNumber) >= HighestLowerRarityPage+1 then
								page.Name = "Page" .. tostring(tonumber(PageNumber)+1)
							end
						end
					end
					NewPage.Name = "Page" .. tostring(HighestLowerRarityPage+1)
				else
					NewPage.Name = "Page1"
				end
				
			else --Common
				if #Pages > 0 then
					for i,page in pairs (Pages) do
						if page:IsA("Frame") then
							print(page)
							local PageNumber = string.gsub(page.Name, "Page", "")
							page.Name = "Page" .. tostring(tonumber(PageNumber)+1)
						end
					end
				end
				NewPage.Name = "Page1"
			end
		else
			NewPage.Name = "Page1"
		end
		NewPage.Parent = Menu
		NewPage.Visible = false
		Page = NewPage
	end
	
	if RaritySort then
		Page.BackgroundColor3 = GuiElements.RarityColors:FindFirstChild(StatRarity).Value
	end
	
	return StatRarity,Page,SlotCount
end

local DepositInventory = EventsFolder.Utility:WaitForChild("DepositInventory")
DepositInventory.OnClientEvent:Connect(function()
	for i,menu in pairs (DataMenu.InventoryMenu:GetChildren()) do
		if menu:IsA("Frame") then
			for i,page in pairs (menu:GetChildren()) do
				page:Destroy()
			end
		end
	end
end)


--------------<|Tile Functions|>------------------------------------------------------------------------------------

local function ManageEquipButton(ItemViewerMenu, AcquiredLocation, Stat)
	local EquipButton = ItemViewerMenu.EquipButton
	
	if DataMenu.PlayerMenu:FindFirstChild(AcquiredLocation).CurrentlyEquipped.Value == tostring(Stat) then
		print("Making equip button say unequip:",Stat,DataMenu.PlayerMenu:FindFirstChild(AcquiredLocation).CurrentlyEquipped.Value)

		EquipButton.Text = "Unequip"
		EquipButton.BackgroundColor3 = Color3.fromRGB(255, 96, 96)
		EquipButton.BorderColor3 = Color3.fromRGB(255, 60, 60)
		EquipButton.EquipStatus.Value = true
	else
		EquipButton.Text = "Equip"
		EquipButton.BackgroundColor3 = Color3.fromRGB(0, 255, 72)
		EquipButton.BorderColor3 = Color3.fromRGB(0, 170, 54)
		EquipButton.EquipStatus.Value = false
	end
	
	EquipButton.Visible = true
end

local function HideRemainingStatDisplays(tile)
	for i,statDisplay in pairs (tile:GetChildren()) do
		if statDisplay:FindFirstChild("Utilized") then
			if statDisplay.Utilized.Value == false then
				statDisplay.Visible = false
			end
		end
	end
end

local function InsertItemViewerInfo(Type, Stat, StatInfo, Value, AcquiredLocation)

	local ItemViewerMenu = DataMenu.ItemViewer
	if Type == "Inventory" then
		local RarityName = StatInfo["GUI Info"].RarityName.Value
		local Rarity = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(RarityName)
		
		ItemViewerMenu.ItemImage.BorderColor3 = Rarity.Value
		ItemViewerMenu.ItemImage.BackgroundColor3 = Rarity.TileColor.Value
		ItemViewerMenu.ItemRarity.Text = RarityName
		ItemViewerMenu.ItemRarity.TextColor3 = Rarity.Value
		ItemViewerMenu.ItemRarity.TextStrokeColor3 = Rarity.TileColor.Value

		ItemViewerMenu.ItemAmount.Text = "You Have: " .. tostring(Value)
		ItemViewerMenu.ItemWorth.Text = "Worth: " .. tostring(StatInfo.CurrencyValue.Value)
		ItemViewerMenu.ItemDescription.Text = StatInfo["GUI Info"].Description.Value

		ItemViewerMenu.EquipButton.Visible = false

	elseif Type == "Bags" then
		ItemViewerMenu.ItemDescription.Text = StatInfo["GUI Info"].Description.Value
		ItemViewerMenu.ItemAmount.Text = AcquiredLocation
		ItemViewerMenu.ItemWorth.Text = Type
		ItemViewerMenu.ItemRarity.Text = ""

		ManageEquipButton(ItemViewerMenu, AcquiredLocation, Stat)	
	elseif Type == "Experience" then
		ItemViewerMenu.ItemRarity.Text = ""
		ItemViewerMenu.ItemAmount.Text = "Total EXP: " .. tostring(Value)

		ItemViewerMenu.EquipButton.Visible = false
	else --Non-Bag Player Items
		local ItemStats = Value
		ItemViewerMenu.ItemDescription.Text = StatInfo["GUI Info"].Description.Value
		ItemViewerMenu.ItemAmount.Text = "Efficiency: " .. tostring(ItemStats["Stats"][1][2])
		ItemViewerMenu.ItemRarity.Text = ""
		
	end

	ItemViewerMenu.ItemImage.Image = StatInfo["GUI Info"].StatImage.Value
	ItemViewerMenu.ItemName.Text = tostring(Stat)

	ItemViewerMenu.Visible = true 
end

local function InsertTileInfo(Type, tile, Stat, Value, found, AcquiredLocation)
	tile.StatName.Value = tostring(Stat)
	
	local StatInfo
	if Type == "Inventory" or Type == "Bags" then
		
		if Type == "Inventory" then
			StatInfo = game.ReplicatedStorage.ItemLocations:FindFirstChild(tostring(AcquiredLocation)):FindFirstChild(tostring(Stat))
		else
			StatInfo = game.ReplicatedStorage.Equippable.Bags:FindFirstChild(tostring(AcquiredLocation)):FindFirstChild(tostring(Stat))
		end
		
		tile.Amount.Text = tostring(Value)
		local ImageId = GetStatImage(StatInfo)
		tile.Picture.Image = ImageId
		
		if tostring(Stat) == DataMenu.ItemViewer.ItemName.Text then
			DataMenu.ItemViewer.ItemAmount.Text = "You Have: " .. tostring(Value)
		end
		found = true
		
	elseif Type == "Experience" then
		StatInfo = game.ReplicatedStorage:FindFirstChild(tostring(AcquiredLocation)):FindFirstChild(tostring(Stat) .. "Skill")
		tile.DisplayName.Text = tostring(Stat)
		
		local CurrentLevel = 0
		--Move into Levels value where the value is how many levels, no for in pairs, just 1,amount,1 loop
		for i,level in pairs (StatInfo.Levels:GetChildren()) do
			if Value >= level.Value and tonumber(level.Name) > CurrentLevel then
				CurrentLevel = tonumber(level.Name)
			end
		end

		local NextLevel
		if StatInfo.Levels:FindFirstChild(tostring(CurrentLevel + 1)) then
			NextLevel = StatInfo.Levels:FindFirstChild(tostring(CurrentLevel + 1))
			tile.NextLevel.Text = tostring(NextLevel)
		else
			NextLevel = StatInfo.Levels:FindFirstChild(tostring(CurrentLevel))
			tile.NextLevel.Text = "*"
		end
		
		local CurrentLevelEXP = StatInfo.Levels:FindFirstChild(tostring(CurrentLevel))
		local ProgressBar = tile.ProgressBar
		ProgressBar.Current.Text = tostring(Value - CurrentLevelEXP.Value)
		ProgressBar.Total.Text = tostring(NextLevel.Value - CurrentLevelEXP.Value)
		tile.CurrentLevel.Text = tostring(CurrentLevel)
		
		local Percentage = tonumber(Value - CurrentLevelEXP.Value) / tonumber(NextLevel.Value - CurrentLevelEXP.Value)
		ProgressBar.Progress.Size = UDim2.new(Percentage, 0, 1, 0)
		found = true
		
	else --Non-Bag, Equippable PlayerItems
		local RSTypeFile = game.ReplicatedStorage.Equippable:FindFirstChild(tostring(Type))
		StatInfo = RSTypeFile:FindFirstChild(tostring(AcquiredLocation)):FindFirstChild(tostring(Stat))
		
		tile.DisplayName.Text = tostring(Stat)
		--tile.Picture.Image = StatInfo["GUI Info"].StatImage.Value

		local ItemStats = Value
		for stat = 1,#ItemStats["Stats"],1 do
			local StatName = ItemStats["Stats"][stat][1]
			local StatValue = ItemStats["Stats"][stat][2]

			if ItemStats["Images"][StatName .. "Image"] then --Displayed on a GUI
				if ItemStats["Images"][StatName .. "Image"][2] then
					local ImageId = ItemStats["Images"][StatName .. "Image"][1]
					local ImageType = ItemStats["Images"][StatName .. "Image"][2]
					
					local FoundStatDisplay = false
					for i,statDisplay in pairs (tile:GetChildren()) do
						if FoundStatDisplay == false then
							if string.find(tostring(statDisplay), ImageType) and statDisplay:FindFirstChild("Utilized") then
								if statDisplay.Utilized.Value ~= true then
									statDisplay.Utilized.Value = true
									FoundStatDisplay = true
									
									statDisplay.Image = ImageId
									
									if math.abs(StatValue) < 1 then --Remove 0 before decimal
										local RemovedZero = string.gsub(tostring(StatValue), "0." , "")
										statDisplay.StatValue.Text = "." .. RemovedZero
									else
										statDisplay.StatValue.Text = StatValue
									end
									
									if ImageType == "StatBar" then
										local MaxStatValue = game.ReplicatedStorage.GuiElements.MaxStatValues:FindFirstChild(StatName).Value
										statDisplay.ProgressBar.Progress.Size = UDim2.new(StatValue/MaxStatValue, 0, 1, 0)
									end
								end
							end
						end	
					end
				end	
			end
		end
		
		HideRemainingStatDisplays(tile)
	end
	
	--ItemViewerMenu GUI Management
	tile.Activated:Connect(function()
		if ItemViewerOpen == false then
			ItemViewerOpen = true
			InsertItemViewerInfo(Type, Stat, StatInfo, Value, AcquiredLocation)
		end
	end)
	
	return found
end

local function ManageTileInsertion(tile, slotNumber, previousTile, tilesPerRow)
	if (slotNumber-1)%tilesPerRow == 0 then
		tile.Row.Value = previousTile.Row.Value + 1
		tile.Column.Value = 0
	else
		tile.Row.Value = previousTile.Row.Value
		tile.Column.Value = previousTile.Column.Value + 1
	end

end

function ManageTiles(Stat, Menu, Value, Type, AcquiredLocation)
	--print(Stat,Menu,Value,File,Type) = Stone,OresMenu,2,Ores,Inventory
	local Rarity
	local Page
	local SlotCount
	local OriginalMaterialSlot
	
	--To get rid of types check here, assign number, bool, and slotname as function parameters
	if Type == "Inventory" then
		OriginalMaterialSlot = GuiElements.InventoryMaterialSlot
		Rarity,Page,SlotCount = FindStatPage(Stat, Menu, 15, true, AcquiredLocation)
	elseif Type == "Bags" then
		OriginalMaterialSlot = GuiElements.InventoryMaterialSlot
		Rarity,Page,SlotCount = FindStatPage(Stat, Menu, 15, false, AcquiredLocation)
	elseif Type == "Tools" then
		OriginalMaterialSlot = GuiElements.PlayerItemSlot
		Rarity,Page,SlotCount = FindStatPage(Stat, Menu, 6, false, AcquiredLocation)
	else
		OriginalMaterialSlot = GuiElements.ExperienceSlot
		Rarity,Page,SlotCount = FindStatPage(Stat, Menu, 4, false, AcquiredLocation) --no rarity sort
	end
		
	if SlotCount > 0 then --If tile already present
		local found = false
		
		--Looking to update value of current tile
		for i,tile in pairs (Page:GetChildren()) do
			if tile:IsA("TextButton") or tile:IsA("ImageButton") then
				if tile.StatName.Value == tostring(Stat) and found == false then --Update Tile
					
					if Value > 0 or Value:IsA("LocalizationTable")then --or Value.Efficiency (for special items: Tools, clothes, pets, etc.)
						found = InsertTileInfo(Type, tile, Stat, Value, found, AcquiredLocation)
					else --Deleting existing tile because value = 0 or zeroed from storage transaction 
						found = true
						local SlotNumber = i
						
						for i,tile in pairs (Page:GetChildren()) do --Move other tiles to fill in gap
							if i > SlotNumber then
								if tile:IsA("TextButton") or tile:IsA("ImageButton") then
									tile.Name = tostring("Slot" .. tostring(i - 1))
									if Type == "Inventory" or Type == "Bags" then
										tile.Row.Value = tile.Row.Value - 1
										tile.Column.Value = tile.Column.Value - 1
										tile.Position = UDim2.new(0.017+0.196*tile.Column.Value, 0, 0.02+0.298*tile.Row.Value, 0)
									else
										tile.Position = UDim2.new(0.028,0,0.037+((i-1)*0.24),0) --change to do with Column and Row
									end
								end
							end
						end
						
						if SlotCount == 1 then --if tile is last on page
							Page:Destroy()
						end
						tile:Destroy()
					end
				end
			end
		end
		
		--Make new tile
		if found == false and (Value > 0 or Value:IsA("LocalizationTable")) then
			print("Making a new tile: " .. tostring(Stat))
			local tile = OriginalMaterialSlot:Clone()
			local PreviousTile = Page:FindFirstChild("Slot" .. tostring(SlotCount))
			local slotNumber = SlotCount + 1
			tile.Name = "Slot" .. tostring(slotNumber)
			
			if Type == "Inventory" or Type == "Bags" then
				ManageTileInsertion(tile, slotNumber, PreviousTile, 5)
				
				tile.Rarity.Value = Rarity
				tile.Position = UDim2.new(0.017+0.196*tile.Column.Value, 0, 0.02+0.298*tile.Row.Value, 0)
			elseif Type == "Experience" then
				tile.Position = UDim2.new(0.028,0,0.037+((SlotCount)*0.24),0)
			else --Non-Bag Player Item
				ManageTileInsertion(tile, slotNumber, PreviousTile, 2)
				
				tile.Position = UDim2.new(0.017+.492*tile.Column.Value, 0, 0.02+0.298*tile.Row.Value, 0)
			end
			
			tile.Parent = Page
			
			local PrevTileY = PreviousTile.Position.Y.Scale
			
			found = InsertTileInfo(Type, tile, Stat, Value, found, AcquiredLocation)
		end
	else
		
		--First tile to be made for menu (Change to first tile for page) (function for making a new page to replace canvas function?)
		if Value ~= 0 then			
			local FirstSlot = OriginalMaterialSlot:Clone()
			FirstSlot.Name = "Slot1"
			FirstSlot.Parent = Page
			
			if Type == "Experience" then
				FirstSlot.Position = UDim2.new(0.028,0,0.037,0)
			else
				FirstSlot.Row.Value = 0
				FirstSlot.Column.Value = 0
				FirstSlot.Rarity.Value = Rarity
				FirstSlot.Position = UDim2.new(0.017, 0, 0.02, 0)
			end
			
			FirstSlot.StatName.Value = tostring(Stat)
			InsertTileInfo(Type, FirstSlot, Stat, Value, nil, AcquiredLocation)
		end
	end
end


--------------------<|Material PopUp Functions|>-------------------------------------------------------------------------------------------------------------------

local MaterialPopUpAmount
local function InsertNewMaterialPopUp(ItemPopUp, AcquiredLocation, Item, AmountAdded, Currency)
	--print("New PopUp: " .. tostring(Object))
	local OriginalPopUpGUI = GuiElements:FindFirstChild("PopUpSlot")
	
	--Move other tiles upward
	for i,slot in pairs (ItemPopUp:GetChildren()) do
		slot:TweenPosition(UDim2.new(slot.Position.X.Scale, 0, slot.Position.Y.Scale - .105, 0), "Out", "Quint", .8)
	end
	
	local RealObject
	if Currency then --Possibly give currency its own type later
		
		--Display the pop up for currency via the PurchaseHandler since that will be the only script
		--Handling currency, or possibly fire UpdateInventory through PurchaseHandler
		RealObject = game.ReplicatedStorage.Currencies:FindFirstChild(Item)
		--just shows player the amount of cash they lost/gained (skipped tile management since no inventory tile)
		--possibly give money exclusive popup color or shape?
	else
		RealObject = game.ReplicatedStorage.ItemLocations:FindFirstChild(AcquiredLocation):FindFirstChild(tostring(Item))
	end
	
	local Rarity = RealObject["GUI Info"].RarityName.Value
	local RarityFile = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(Rarity)
	local NewItemPopUp = OriginalPopUpGUI:Clone()
	NewItemPopUp.Parent = ItemPopUp
	NewItemPopUp.Amount.Text = tostring(AmountAdded)
	NewItemPopUp.DisplayName.Text = tostring(Item)
	NewItemPopUp.Position = UDim2.new(0.835, 0,1, 0)
	MaterialPopUpAmount = #ItemPopUp:GetChildren()
	NewItemPopUp.Name = "PopUp" .. tostring(MaterialPopUpAmount)
	NewItemPopUp.Object.Value = tostring(Item)
	
	local ItemImage = GetStatImage(RealObject)
	NewItemPopUp.Picture.Image = ItemImage
	
	NewItemPopUp.BackgroundColor3 = RarityFile.TileColor.Value
	NewItemPopUp.BorderColor3 = RarityFile.Value
	NewItemPopUp.CircleBorder.BackgroundColor3 = RarityFile.Value
	NewItemPopUp["Round Edge"].BackgroundColor3 = RarityFile.Value
	NewItemPopUp["Round Edge"].Inner.BackgroundColor3 = RarityFile.TileColor.Value
	
	NewItemPopUp:TweenPosition(UDim2.new(0.835, 0,0.8, 0), "Out" , "Quint", .45)
	CountdownPopUp(ItemPopUp, NewItemPopUp, 5, .2, 0)
end

local PrevItem
local PrevAmount
local CurrentObject
local function ManageMaterialPopups(ObjectName, AcquiredLocation, AmountAdded, Currency)
	local ItemPopUp = script.Parent.Parent.PopUps:FindFirstChild("ItemPopUp")
	if AmountAdded ~= nil then
		if AmountAdded ~= 0 then
			
			if AmountAdded < 0 then
				CurrentObject = "Negative" .. tostring(ObjectName)
			else
				CurrentObject = ObjectName
			end
			if PrevItem ~= tostring(CurrentObject) then
				InsertNewMaterialPopUp(ItemPopUp, AcquiredLocation, ObjectName, AmountAdded, Currency)
				PrevItem = tostring(ObjectName)
				PrevAmount = AmountAdded
				
			elseif PrevItem == tostring(CurrentObject) and #ItemPopUp:GetChildren() == 0 then
				print("Detected that no slot is available, but prev has been mined")
				InsertNewMaterialPopUp(ItemPopUp, AcquiredLocation, ObjectName, AmountAdded, Currency)
				PrevItem = tostring(ObjectName)
				PrevAmount = AmountAdded
				
			elseif #ItemPopUp:GetChildren() >= 1 then
				PrevAmount = PrevAmount + AmountAdded
				
				--Find most recent version of the popup related to the object
				local MostRecent = 0
				for i,slot in pairs (ItemPopUp:GetChildren()) do
					if slot.Object.Value == tostring(ObjectName) then
						if i > MostRecent then
							MostRecent = i
						end
					end
				end
				
				ItemPopUp:FindFirstChild("PopUp" .. tostring(MostRecent)).Amount.Text = tostring(PrevAmount)
				CountdownPopUp(ItemPopUp, ItemPopUp:FindFirstChild("PopUp" .. tostring(MostRecent)), 5, .2, 0)
			end
		end
	end
end


----------------------------<|Countdown Functions|>--------------------------------------------------------------------------------------------------------------------------

function CountdownPopUp(PopUpGui, Slot, TimeBeforeExpire, XJumpDistance, YJumpDistance, XJumpDistance2, YJumpDistance2)
	if Slot:FindFirstChild("TimeLeft") then
		local Timer = Slot:FindFirstChild("TimeLeft")
		Timer.Value = 0
		coroutine.resume(coroutine.create(function()
			for sec = 1,TimeBeforeExpire,1 do
				wait(1)
				--if Timer then
				if sec == Timer.Value + 1 then
					Timer.Value = sec
					if sec == TimeBeforeExpire then
						if Slot:FindFirstChild("NamePlate") then
							local NamePlate = Slot:FindFirstChild("NamePlate")
							NamePlate:TweenPosition(UDim2.new(NamePlate.Position.X.Scale + XJumpDistance2,0,NamePlate.Position.Y.Scale + YJumpDistance2 ,0), "Out", "Quint", .3)
							wait(.4)
						end
						Slot:TweenPosition(UDim2.new(Slot.Position.X.Scale + XJumpDistance, 0, Slot.Position.Y.Scale + YJumpDistance, 0), "Out", "Quint", .5)
						wait(.8)
						Slot:Destroy()
						if #PopUpGui:GetChildren() > 0 then
							for i,slot in pairs (PopUpGui:GetChildren()) do
								slot.Name = "PopUp" .. tostring(i)
							end
						end
					end
				end
			end
		end))
	end
end

local DifferenceEXPAdded = 0
local LastPercentage = 0
local function CountdownDifference(Difference, OriginalProgressBar, Percentage, AmountAdded, Finished)
	local ExpBar = Difference.Parent.Parent
	if ExpBar:FindFirstChild("TimeLeft") then
		DifferenceEXPAdded = DifferenceEXPAdded + AmountAdded
		local Timer = Difference:FindFirstChild("TimeLeft")
		Timer.Value = 0
		if Percentage < LastPercentage or Percentage >= 1 or Finished then
			print("Finished a skill level, updating exp bar",Percentage,LastPercentage)
			LastPercentage = Percentage
			EXPPopUp(ExpBar, DifferenceEXPAdded, 1)
			DifferenceEXPAdded = 0
			
			OriginalProgressBar:TweenSize(UDim2.new(Percentage, 0, 0, 30), "Out", "Quint", .5)
			Difference:TweenSize(UDim2.new(Percentage, 0, 0, 30), "Out", "Quint", .5)
			local PreviousLevel = tonumber(ExpBar.CurrentLevel.Text)
			ExpBar.CurrentLevel.Text = PreviousLevel + 1
			ExpBar.NextLevel.Text = PreviousLevel + 2
			--Maybe put countdown popup here to refresh the experience bar?
			--Level up animation could go here, or in the ShowEXPChange function
		else
			--print("Percentage: " .. tostring(Percentage))
			LastPercentage = Percentage
			coroutine.resume(coroutine.create(function()
				for sec = 1,5,1 do
					wait(1)
					if Timer then
						if sec == Timer.Value + 1 then
							Timer.Value = sec
							if sec == 5 then
								EXPPopUp(ExpBar, DifferenceEXPAdded, 3)
								DifferenceEXPAdded = 0
								OriginalProgressBar:TweenSize(UDim2.new(0, Difference.Size.X.Offset, Difference.Size.Y.Scale, 30), "Out", "Quint", .5)
								wait(.6)
								Difference:Destroy()
							end
							--else
							--coroutine.yield() --if implemented, would this prevent repeats with menu presses? or greater efficiency??
						end
					end
				end
			end))
		end
	end
end


----------------------------<|EXPBar PopUp Functions|>------------------------------------------------------------------------------------------------------------

function EXPPopUp(ExpBar, Value, Pace)
	local RealEXPPopUp = GuiElements:FindFirstChild("EXPPopUp")
	local NewExpPopUp = RealEXPPopUp:Clone()
	NewExpPopUp.Parent = ExpBar
	NewExpPopUp.Text = "+" .. tostring(Value) .. "XP"
	NewExpPopUp.Position = UDim2.new(math.random(-17.72,-15.48), 0, math.random(-1.71,-.777), 0)
	NewExpPopUp:TweenSize(UDim2.new(0, 100, 0, 25), "Out", "Quart", .5) --Grow
	wait(Pace)
	NewExpPopUp:TweenSizeAndPosition(UDim2.new(0, 0, 0, 0), UDim2.new(-7.64, 0, 0.123, 0), "Out", "Quint", 1) --Move to bar
	wait(1.2)
	NewExpPopUp:Destroy()
end

local function ShowEXPChange(ExperienceBar, CurrentLevel, NextLevel, StatInfo, Value, AmountAdded)
	local ExperienceBarGui = script.Parent.Parent.PopUps:FindFirstChild("EXPBarPopUp")
	local ProgressBar = ExperienceBarGui.ExperienceBar.ProgressBar
	local CurrentLevelEXP = StatInfo.Levels:FindFirstChild(tostring(CurrentLevel))
	
	ExperienceBar.CurrentLevel.Text = tostring(CurrentLevel)
	ExperienceBar.NextLevel.Text = tostring(NextLevel)
	
	--Difference bar check
	if ProgressBar:FindFirstChild("EXPDifference") then
		local Difference = ProgressBar.EXPDifference
		local Percentage = tonumber(Value - CurrentLevelEXP.Value) / tonumber(NextLevel.Value - CurrentLevelEXP.Value)
		if Percentage < LastPercentage then
			--Here instead of CountdownDifference to prevent delay
			Difference:TweenSize(UDim2.new(0, 276, 0, 30), "Out", "Quint", .2)
			wait(.2)
			ProgressBar.Progress:TweenSize(UDim2.new(0, 276, 0, 30), "Out", "Quint", .2)
			wait(.2)
			CountdownDifference(Difference, ProgressBar.Progress, Percentage, AmountAdded, true)
		else
			Difference:TweenSize(UDim2.new(0, 276*Percentage, 0, 30), "Out", "Quint", .2)
			CountdownDifference(Difference, ProgressBar.Progress, Percentage, AmountAdded)
		end
	else
		local Difference = ProgressBar.Progress:Clone()
		Difference.ZIndex = 3 --Put behind progress frame
		Difference.Parent = ProgressBar
		Difference.Name = "EXPDifference"
		Difference.BackgroundColor3 = Color3.new(85, 255, 255)
		local TimeLeftValue = Instance.new("IntValue",Difference)
		TimeLeftValue.Name = "TimeLeft"	
		local Percentage = tonumber(Value - CurrentLevelEXP.Value) / tonumber(NextLevel.Value - CurrentLevelEXP.Value)
		Difference:TweenSize(UDim2.new(0, 276*Percentage, 0, 30), "Out", "Quint", .2)
		
		CountdownDifference(Difference, ProgressBar.Progress, Percentage, AmountAdded)
	end
end

local function InsertNewEXPBar(ExperienceBarGui, ExperienceBar, Stat, Value, CurrentLevel, NextLevel, PopUpAlreadyExists)
	
	if PopUpAlreadyExists then
		local OldExpPopUp = ExperienceBarGui.ExperienceBar
		local NamePlate = OldExpPopUp.NamePlate
		NamePlate:TweenPosition(UDim2.new(-12,0,0,0), "Out", "Quint", .15)
		wait(.15)
		OldExpPopUp:TweenPosition(UDim2.new(0.98, 0, 1.055, 0), "Out", "Quint", .2)
		wait(.2)
		OldExpPopUp:Destroy()
	end
	
	local NewExperienceBar = ExperienceBar:Clone()
	NewExperienceBar.Parent = ExperienceBarGui
	NewExperienceBar.Position = UDim2.new(0.98, 0, 1.055, 0)
	NewExperienceBar.CurrentLevel.Text = tostring(CurrentLevel)
	NewExperienceBar.NextLevel.Text = tostring(NextLevel)
	
	NewExperienceBar:TweenPosition(UDim2.new(.98, 0, NewExperienceBar.Position.Y.Scale - .1, 0), "Out", "Quint", .5)
	
	local StatInfo = game.ReplicatedStorage:FindFirstChild("Skills"):FindFirstChild(tostring(Stat) .. "Skill")
	local ProgressBar = ExperienceBarGui.ExperienceBar.ProgressBar
	local CurrentLevelEXP = StatInfo.Levels:FindFirstChild(tostring(CurrentLevel))
	local Percentage = tonumber(Value - CurrentLevelEXP.Value) / tonumber(NextLevel.Value - CurrentLevelEXP.Value)
	ProgressBar.Progress.Size = UDim2.new(0, 276*Percentage, 0, 30)
	CountdownPopUp(ExperienceBarGui, NewExperienceBar, 12, .45, 0, 0, .9) --Start Countdown
	wait(.5) --Wait for tween to finish
	
	local NamePlate = NewExperienceBar.NamePlate
	NamePlate.DisplayName.Text = tostring(Stat)
	NamePlate:TweenPosition(UDim2.new(-12, 0, -0.9, 0), "Out", "Quint", .3)
end

local function ManageEXPPopUp(Stat, Value, AmountAdded)
	local ExperienceBar = GuiElements:FindFirstChild("ExperienceBar")
	local ExperienceBarGui = script.Parent.Parent.PopUps:FindFirstChild("EXPBarPopUp")
	local StatInfo = game.ReplicatedStorage:FindFirstChild("Skills"):FindFirstChild(tostring(Stat) .. "Skill")
	
	local CurrentLevel,NextLevel = FindStatLevel(StatInfo, Value)
	
	if AmountAdded ~= nil then
		if #ExperienceBarGui:GetChildren() ~= 0 then
			if ExperienceBarGui.ExperienceBar.NamePlate.DisplayName.Text == tostring(Stat) then
				--print("OLD EXPBAR: ",CurrentLevel,NextLevel)
				ShowEXPChange(ExperienceBarGui.ExperienceBar, CurrentLevel, NextLevel, StatInfo, Value, AmountAdded)
				CountdownPopUp(ExperienceBarGui, ExperienceBarGui.ExperienceBar, 12, .5, 0, 0, .9)
			else
				--print("NEW EXPBAR: ",CurrentLevel,NextLevel)
				InsertNewEXPBar(ExperienceBarGui, ExperienceBar, Stat, Value, CurrentLevel, NextLevel, true)
			end
		else --Pop up new experience bar
			--print("NEW EXPBAR: ",CurrentLevel,NextLevel)
			InsertNewEXPBar(ExperienceBarGui,ExperienceBar,Stat, Value, CurrentLevel, NextLevel)
			ShowEXPChange(ExperienceBarGui.ExperienceBar, CurrentLevel, NextLevel, StatInfo, Value, AmountAdded)
		end
	end
	
end

-------------------------<|Bag Information GUI Functions|>----------------------------------------------------------------------------------------------------------

local function InsertNewBagPopUp(BagPopUp, BagPopUpGui, ItemTypeCount, BagCapacity, BagType, PopUpAlreadyExists)
	if PopUpAlreadyExists then
		local OldBagPopUp = BagPopUpGui:FindFirstChild("BagPopUp")
		local NamePlate = OldBagPopUp.NamePlate
		NamePlate:TweenPosition(UDim2.new(0.076,0,0,0), "Out", "Quint", .15)
		wait(.15)
		OldBagPopUp:TweenPosition(UDim2.new(0.126,0,1,0), "Out", "Quint", .2)
		wait(.2)
		OldBagPopUp:Destroy()
	end
	
	local NewBagPopUp = BagPopUp:Clone()
	NewBagPopUp.Parent = BagPopUpGui
	NewBagPopUp.Amounts.Text = tostring(ItemTypeCount) .. "/" .. tostring(BagCapacity)
	
	NewBagPopUp:TweenPosition(UDim2.new(0.126,0,0.918,0), "Out", "Quint", .5)
	wait(.5)
	local NamePlate = NewBagPopUp:FindFirstChild("NamePlate")
	NamePlate.Text = BagType
	NamePlate:TweenPosition(UDim2.new(0.076,0,-0.344,0), "Out", "Quint", .3)
	wait(.3)
	
	CountdownPopUp(BagPopUpGui, NewBagPopUp, 11, 0, 0.082, 0, 0.344)
end

-------------------------------------<|PlayerMenu Functions|>------------------------------------------------------------------------------------------------------------

local PlayerMenu = DataMenu:FindFirstChild("PlayerMenu")
local PlayerInfo = PlayerMenu["Default Menu"].PlayerInfo
local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size420x420
local PlayerProfilePicture = game.Players:GetUserThumbnailAsync(PlayerUserId, thumbType, thumbSize)
local UpdateEquippedItem = EventsFolder.GUI:WaitForChild("UpdateEquippedItem")

PlayerInfo.PlayerThumbnail.Image = PlayerProfilePicture
PlayerInfo.PlayerName.Text = tostring(Player)

local RealBags = game.ReplicatedStorage.Equippable.Bags
local BagInfo = PlayerMenu["Default Menu"].BagInfo

local EquipButton = DataMenu.ItemViewer.EquipButton
EquipButton.Activated:Connect(function()
	if EquipButton.Visible == true then
		EquipButton.Active = false
		
		local ItemName = DataMenu.ItemViewer.ItemName.Text
		local ItemType = DataMenu.ItemViewer.ItemAmount.Text
		local EquipType = DataMenu.ItemViewer.ItemWorth.Text
		
		if EquipButton.EquipStatus.Value == false then --Equip item
			EquipButton.Text = "Unequip"
			EquipButton.BackgroundColor3 = Color3.fromRGB(255, 96, 96)
			EquipButton.BorderColor3 = Color3.fromRGB(255, 60, 60)
			EquipButton.EquipStatus.Value = true
				
			UpdateEquippedItem:FireServer(EquipType, ItemType, ItemName)
		else --Unequip item
			local AssociatedInventoryMenu = DataMenu.InventoryMenu:FindFirstChild(string.gsub(ItemType, "Bag", "") .. "Menu")
			local ItemCount = AssociatedInventoryMenu:GetAttribute("ItemCount")
			
			print("ITEMCOUNT:",ItemCount)
			
			if ItemCount == 0 then
				EquipButton.Text = "Equip"
				EquipButton.BackgroundColor3 = Color3.fromRGB(0, 255, 72)
				EquipButton.BorderColor3 = Color3.fromRGB(0, 170, 54)
				EquipButton.EquipStatus.Value = false
			
				UpdateEquippedItem:FireServer(EquipType, ItemType)
			else
				print("Cannot unequip a bag with items in it")
				--Warning message
			end
		end
		wait(1)
		EquipButton.Active = true
	end
end)

local function UpdateBagButtonBar(Button, RelatedInvMenu)
	local BagCapacity = RelatedInvMenu:GetAttribute("BagCapacity")
	local ItemCount = RelatedInvMenu:GetAttribute("ItemCount")
	local ProgressBar = Button.Progress.Progress
	
	if BagCapacity > 0 then
		ProgressBar.Size = UDim2.new(ItemCount/BagCapacity, 0, 1, 0)
	else
		ProgressBar.Size = UDim2.new(1, 0, 1, 0)
	end
end

function UpdateBagDisplays(Menu, ButtonMenu)
	for i,button in pairs (ButtonMenu:GetChildren()) do
		if button:IsA("ImageButton") then
			if string.find(tostring(button), "Bags") then
				local SingularName = string.gsub(tostring(button), "Bags", "")
				local PluralName = SingularName .. "s"
				local RelatedInvMenu = Menu.InventoryMenu:FindFirstChild(PluralName .. "Menu")
				
				if RelatedInvMenu then
					UpdateBagButtonBar(button, RelatedInvMenu)
				end
			end
		end
	end
end

UpdateEquippedItem.OnClientEvent:Connect(function(EquipType, ItemType, Item)
	local DefaultMenuButton = PlayerMenu:FindFirstChild(ItemType)
	DefaultMenuButton.CurrentlyEquipped.Value = Item
	
	if Item and Item ~= "" then
		local ItemInfo = game.ReplicatedStorage.Equippable:FindFirstChild(EquipType):FindFirstChild(ItemType):FindFirstChild(Item)
		local ItemImage = GetStatImage(ItemInfo)

		DefaultMenuButton.Image = ItemImage
		
		--Highlight Equipped Item
		for i,page in pairs (PlayerMenu:FindFirstChild(ItemType .. "Menu"):GetChildren()) do
			for i,tile in pairs (page:GetChildren()) do
				if tile:IsA("TextButton") then
					if tile.StatName.Value == Item then
						tile.BackgroundColor3 = Color3.fromRGB(85, 170, 255) --Brighter blue (or player's fav color later)
					else
						tile.BackgroundColor3 = Color3.fromRGB(47, 95, 143)
					end
				end
			end
		end
		
	else
		print("Item has been unequipped")
	end
	
	if ItemType == "Bags" then
		UpdateBagDisplays(DataMenu, DataMenu.PlayerMenu)
	end
end)


-------------------------------------<High-Traffic Events>-------------------------------------------------------------------------------------------------------------

local UpdateInventory = EventsFolder.GUI:WaitForChild("UpdateInventory")
UpdateInventory.OnClientEvent:Connect(function(Stat, File, Value, AmountAdded, Type, Currency, AcquiredLocation)
	local TypeSlots = DataMenu:FindFirstChild(tostring(Type) .. "Menu")
	local Slots
	
	if File then
		Slots = TypeSlots:FindFirstChild(File .. "Menu") or TypeSlots:FindFirstChild(File)
	else
		warn("No File associated with non-currency inventory update. Stat Name: " .. tostring(Stat))
	end
	
	if Type == "Inventory" then --Includes Currency
		ManageMaterialPopups(Stat, AcquiredLocation, AmountAdded, Currency) 

	elseif Type == "Experience" then 
		--Experience tiles are also unlocked once you get at least one point of exp
		--Would be fun to have a "You've unlocked a new skill!" animated gui popup
		
		if string.find(tostring(Stat), "Skill") then
			Stat = string.gsub(tostring(Stat), "Skill", "") --Remove "Skill" from string
		end
		
		ManageEXPPopUp(Stat, Value, AmountAdded)
	end
	
	--When levelling-up...
	--Inventory, on next open, would then display what the player now has access too with their new level
	--Level-up data could be in Server Storage, grabbed by PlayerStatManager
	
	if Currency == nil then
		if tonumber(Value) ~= 0 then
			ManageTiles(Stat, Slots, tonumber(Value), Type, AcquiredLocation)
		end
	end
end)

local UpdatePlayerMenu = EventsFolder.GUI:WaitForChild("UpdatePlayerMenu")
UpdatePlayerMenu.OnClientEvent:Connect(function(EquipType, ItemType, Item)
	
	local RealInfo = game.ReplicatedStorage.Equippable:FindFirstChild(EquipType):FindFirstChild(ItemType):FindFirstChild(Item)
	local AssociatedMenu = PlayerMenu:FindFirstChild(ItemType .. "Menu")
	local AssociatedButton = PlayerMenu:FindFirstChild(ItemType)
	
	if EquipType == "Bags" then
		local Value = RealInfo.Value   
		ManageTiles(Item, AssociatedMenu, tonumber(Value), EquipType, ItemType)
	else
		local ItemStats = require(RealInfo:FindFirstChild(Item .. "Stats"))
		ManageTiles(Item, AssociatedMenu, ItemStats, EquipType, ItemType)
	end
	
	--Update Default Menu (Equipped) Item Pictures
	if Item == AssociatedButton.CurrentlyEquipped.Value then
		AssociatedButton.Image = RealInfo["GUI Info"].StatImage.Value
	end
end)

local UpdateItemCount = EventsFolder.GUI:WaitForChild("UpdateItemCount")
UpdateItemCount.OnClientEvent:Connect(function(ItemTypeCount, BagCapacity, BagType, DepositedInventory)
	print("UPDATING ITEM COUNT:",ItemTypeCount,BagCapacity,BagType,DepositInventory)
	
	--print(tostring(BagType) .. ": " .. tostring(ItemTypeCount) .. "/" .. tostring(BagCapacity))
	
	if not DepositedInventory then
		local BagPopUp = GuiElements:FindFirstChild("BagPopUp")
		local BagPopUpGui = script.Parent.Parent.PopUps:FindFirstChild("CurrentBagPopUp")
		if #BagPopUpGui:GetChildren() ~= 0 then --Menu already present
			if BagPopUpGui.BagPopUp.NamePlate.Text == BagType then
				local CurrentBagPopUp = BagPopUpGui:FindFirstChild("BagPopUp")
				CountdownPopUp(BagPopUpGui, CurrentBagPopUp, 11, 0, 0.082, 0, 0.344)
				CurrentBagPopUp.Amounts.Text = tostring(ItemTypeCount) .. "/" .. tostring(BagCapacity)
			else
				InsertNewBagPopUp(BagPopUp, BagPopUpGui, ItemTypeCount, BagCapacity, BagType, true)
			end
		else
			InsertNewBagPopUp(BagPopUp, BagPopUpGui, ItemTypeCount, BagCapacity, BagType)
		end
	end
	
	local ItemType
	if string.find(BagType, "Bag") then
		ItemType = string.gsub(BagType, "Bags", "") .. "s"
	else
		ItemType = BagType
		BagType = string.gsub(ItemType, "s", "") .. "Bags"
	end
	
	--Update bag counts in inventory
	local InventoryMenu = DataMenu.InventoryMenu:FindFirstChild(ItemType .. "Menu")
	
	InventoryMenu:SetAttribute("ItemCount", ItemTypeCount)
	InventoryMenu:SetAttribute("BagCapacity", BagCapacity)

	--Update bag counts in playermenu
	local BagButton = DataMenu.PlayerMenu:FindFirstChild(BagType)
	if BagButton and InventoryMenu then
		UpdateBagButtonBar(BagButton, InventoryMenu)
	end
end)

wait(5)
script.Parent.OpenDataMenuButton.Active = true

