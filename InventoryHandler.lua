local TweenService = game:GetService("TweenService")
local Camera = game.Workspace.CurrentCamera

--local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
--playerGui:SetTopbarTransparency(1)
script.Parent.OpenDataMenuButton.Visible = true

local Player = game.Players.LocalPlayer
local OpenDataMenuButton = script.Parent.OpenDataMenuButton
local dataMenu = script.Parent.DataMenu
local guiElements = game.ReplicatedStorage.GuiElements
local pageManager = dataMenu.PageManager

-----------<|Remote Events/Functions|>--
local eventsFolder = game.ReplicatedStorage.Events

local awardLevelRewards = eventsFolder.GUI:WaitForChild("AwardLevelRewards")
local insertItemViewerInfo = eventsFolder.GUI:WaitForChild("InsertItemViewerInfo")
local MoveAllBaseScreenUI = eventsFolder.GUI:WaitForChild("MoveAllBaseScreenUI")
local ManageTilePlacementFunction = eventsFolder.GUI:FindFirstChild("ManageTilePlacement")
local UpdateEquippedItem = eventsFolder.GUI:WaitForChild("UpdateEquippedItem")
local updateExperience = eventsFolder.GUI:WaitForChild("UpdateExperience")
local updateInventory = eventsFolder.GUI:WaitForChild("UpdateInventory")
local UpdatePlayerMenu = eventsFolder.GUI:WaitForChild("UpdatePlayerMenu")

local CheckResearchDepends = eventsFolder.Utility:WaitForChild("CheckResearchDepends")
local DepositInventory = eventsFolder.Utility:WaitForChild("DepositInventory")
local getCurrentPlayerLevel = eventsFolder.Utility:WaitForChild("GetCurrentPlayerLevel")
local GetItemCountSum = eventsFolder.Utility:WaitForChild("GetItemCountSum")
local getItemStatTable = eventsFolder.Utility:WaitForChild("GetItemStatTable")
----------------------------------------

local GuiUtility = require(game.ReplicatedStorage:FindFirstChild("GuiUtility"))

if dataMenu.Visible == true then
	dataMenu.Visible = false
end

OpenDataMenuButton.Active = false --re-enable when script is ready

--Reset DataMenu on load
for i,v in pairs (dataMenu:GetChildren()) do
	if v:IsA("Frame") and tostring(v) ~= "TopTabBar" and tostring(v) ~= "AccentBorder" then
		v.Visible = false
	end
end

local MenuTabs = {
	dataMenu.PlayerMenuButton, 
	dataMenu.InventoryMenuButton, 
	dataMenu.ExperienceMenuButton,
	dataMenu.JournalMenuButton
}

local tabSelection = dataMenu.TopTabBar.TabSelection
local tsWidth = tabSelection.Size.X.Scale
local previousTween
for _,v in pairs (MenuTabs) do
	local tabWidth = v.Size.X.Scale
	local newSelectPos = math.abs(tabWidth - tsWidth)/2 + v.Position.X.Scale

	if v.Name == "PlayerMenuButton" then
		tabSelection.Position = UDim2.new(newSelectPos, 0, 0.888, 0)
		v.Image = v.SelectedImage.Value
	end
	v.Active = true

	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(tabSelection, tweenInfo, {Position = UDim2.new(newSelectPos, 0, 0.888, 0)})
	local selectedImage = v.SelectedImage.Value
	local staticImage = v.StaticImage.Value
	v.Activated:Connect(function()
		if v.Image ~= selectedImage then
			if previousTween then
				previousTween:Pause()
			end
			tween:Play()
			previousTween = tween
			v.Image = selectedImage
			v.Active = false

			for _,tab in pairs (MenuTabs) do
				if tab ~= v then --other tabs
					tab.Active = false

					if tab.Image == tab.SelectedImage.Value then
						tab.Image = tab.StaticImage.Value
					end
				end
			end

			for _,tab in pairs (MenuTabs) do
				tab.Active = true
			end
		end
	end)
end

local PlayerViewport = dataMenu.PlayerMenu.PlayerInfo.PlayerView
local PlayerModel = game.Workspace.Players:WaitForChild(tostring(Player))
OpenDataMenuButton.Activated:Connect(function()
	if dataMenu.Visible == false then
		GuiUtility.OpenDataMenu(Player, PlayerModel, dataMenu, "PlayerMenu")
	elseif dataMenu.Visible == true then
		OpenDataMenuButton.Active = false
		dataMenu:TweenPosition(UDim2.new(0.5, 0, -0.8, 0), "Out", "Quint", 0.5)
		wait(0.5)
		dataMenu.Visible = false
		dataMenu.Position = UDim2.new(0.159, 0, 0.141, 0)
		pageManager.Visible = false

		dataMenu.TopTabBar.CloseMenu.Active = false
		OpenDataMenuButton.Active = true
	end
end)

dataMenu.TopTabBar.CloseMenu.Activated:Connect(function()
	dataMenu.TopTabBar.CloseMenu.Active = false
	OpenDataMenuButton.Active = false
	dataMenu:TweenPosition(UDim2.new(0.159, 0, -0.8, 0), "Out", "Quint", .5)
	wait(.5)
	dataMenu.Visible = false
	dataMenu.Position = UDim2.new(0.159, 0, 0.141, 0)
	pageManager.Visible = false

	OpenDataMenuButton.Active = true
end)

dataMenu.SelectedBagInfo.Position = UDim2.new(0, 0, 0.94, 0)
local bagBarTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local bagBarOutTween = TweenService:Create(dataMenu.SelectedBagInfo, bagBarTweenInfo, {Position = UDim2.new(0, 0, 1.045, 0)})
local bagBarInTween = TweenService:Create(dataMenu.SelectedBagInfo, bagBarTweenInfo, {Position = UDim2.new(0, 0, 0.94, 0)})
dataMenu.InventoryMenu:GetPropertyChangedSignal("Visible"):Connect(function()
	local bool = dataMenu.InventoryMenu.Visible

	bagBarOutTween:Pause()
	bagBarInTween:Pause()
	if bool == true then
		bagBarOutTween:Play()
	else
		bagBarInTween:Play()
	end
end)

MoveAllBaseScreenUI.Event:Connect(function(ChangeTo)
	dataMenu.Visible = false
	if ChangeTo == "Hide" then
		OpenDataMenuButton:TweenPosition(UDim2.new(-.15, 0, OpenDataMenuButton.Position.Y.Scale, 0), "Out", "Quint", 1)
	else
		OpenDataMenuButton:TweenPosition(UDim2.new(0.01, 0, 0.8, 0), "Out", "Quint", 1)
	end
end)

--------------<|Utility Functions|>-----------------------------------------------------------------------------
local inventoryQuickViewMenu = dataMenu.InventoryMenu.QuickViewMenu.QuickViewMenu
local equipmentQuickViewMenu = dataMenu.PlayerMenu.QuickViewMenu.QuickViewMenu

local function EnableOnlyButtonMenu(buttonMenu, bool, descendantsSeek)
	if descendantsSeek then
		for _,button in pairs (buttonMenu:GetDescendants()) do
			if button:IsA("ImageButton") or button:IsA("TextButton") then
				button.Active = bool
				button.Selectable = bool
			end
		end
	else
		for _,button in pairs (buttonMenu:GetChildren()) do
			if button:IsA("ImageButton") or button:IsA("TextButton") then
				button.Active = bool
				button.Selectable = bool
			end
		end
	end
end

local function ResetRarityTiles(Menu)
	for _,page in pairs (Menu:GetChildren()) do
		if page:IsA("Frame") and string.match(page.Name, "Page") then
			for _,tile in pairs (page:GetChildren()) do
				if tile:IsA("ImageButton") and string.match(tile.Name, "Slot") then
					local rarityInfo = tile.Rarity.Value
					tile.Image = rarityInfo.TileImages.StaticRarityTile.Value
				end
			end
		end
	end
end

local pageDebounce = false
local function SetupPageChange(menu, emptyNotifier, fullBool, partialBool)
	pageManager.Menu.Value = menu
	local PageCount = GetHighPage(menu)	
	
	if PageCount > 0 then
		emptyNotifier.Visible = false

		pageManager.Visible = true
		pageManager.FullBottomDisplay.Visible = fullBool
		pageManager.PartialBottomDisplay.Visible = partialBool
		if menu:FindFirstChild("Page1") then
			pageDebounce = true
			pageDebounce = GuiUtility.CommitPageChange(menu.Page1, 0.25)
		end
	else
		emptyNotifier.Visible = true
	end
end

local ButtonPresses = {}
local MenuAcceptance = true
function ReadyMenuButtons(Menu)
	
	if MenuAcceptance == true then
		MenuAcceptance = false
		for _,button in pairs(Menu:GetChildren()) do
			if (button:IsA("TextButton") or button:IsA("ImageButton")) and button:FindFirstChild("Menu") then
				ButtonPresses[button] = 0
				local associatedMenuName = button:FindFirstChild("Menu").Value
				local ButtonMenu = Menu:FindFirstChild(associatedMenuName)

				--print("Menu:",Menu, " ButtonMenu:",ButtonMenu)

				--First Time Default Menu Setup
				if ButtonMenu.Name ~= "PlayerMenu" then
					ButtonMenu.Visible = false
				else
					ButtonMenu.Visible = true
					ButtonMenu.EmptyNotifier.Visible = false
					ButtonMenu.QuickViewMenu.Visible = false		
				end

				if ButtonMenu:FindFirstChild("FirstSeeMenu") then
					ButtonMenu.Visible = true
				end

				button.Activated:Connect(function()

					for _,v in pairs (ButtonMenu.Parent:GetChildren()) do
						if v:IsA("Frame") and not v:FindFirstChild("Menu") then
							if tostring(v) ~= "TopTabBar" and tostring(v) ~= "AccentBorder" and tostring(v) ~= "SelectedBagInfo" then
								v.Visible = false
							else
								v.Visible = true
							end
						end
					end
					ButtonMenu.Visible = true

					--Enable only current menu's buttons
					for _,menu in pairs (dataMenu:GetChildren()) do
						if string.find(menu.Name, "Menu") and menu:IsA("Frame") then
							EnableOnlyButtonMenu(menu, false, true)
						end
					end
					EnableOnlyButtonMenu(ButtonMenu, true, true)

					--print("Menu:",Menu, " ButtonMenu:",ButtonMenu)

					if tostring(ButtonMenu) == "InventoryMenu" then
						ButtonMenu.QuickViewMenu.Visible = true
						ButtonMenu.QuickViewMenu.QuickViewPreview.Visible = true
						ButtonMenu.QuickViewMenu.QuickViewMenu.Visible = false
						ButtonMenu.EmptyNotifier.Visible = false

						local MaterialsMenu = ButtonMenu.MaterialsMenu
						local bagCapacity = MaterialsMenu:GetAttribute("BagCapacity")
						local itemCount = MaterialsMenu:GetAttribute("ItemCount")

						if bagCapacity and itemCount then
							dataMenu.SelectedBagInfo.BagAmount.Text = tostring(itemCount) .. "/" .. tostring(bagCapacity)
							dataMenu.SelectedBagInfo.FillProgress.Size = UDim2.new(itemCount/bagCapacity, 0, 1, 0)
							dataMenu.SelectedBagInfo.BagType.Value = string.gsub(tostring(ButtonMenu), "Menu", "")
						end
						
						ResetRarityTiles(ButtonMenu.MaterialsMenu)
						SetupPageChange(MaterialsMenu, ButtonMenu.EmptyNotifier, false, true)
						
					elseif tostring(ButtonMenu) == "PlayerMenu" then
						ButtonMenu.EmptyNotifier.Visible = false
						pageManager.FullBottomDisplay.Visible = false
						pageManager.PartialBottomDisplay.Visible = false

						ButtonMenu.QuickViewMenu.Visible = false
						ButtonMenu.PlayerInfo.Visible = true

					elseif tostring(ButtonMenu) == "ExperienceMenu" then
						local skillsMenu = ButtonMenu.SkillsMenu
						for _,menu in pairs (dataMenu.ExperienceMenu:GetChildren()) do
							if menu:IsA("Frame") then
								if string.match(menu.Name, "Menu") and menu ~= skillsMenu then
									menu.Visible = false
								else
									menu.Visible = true
								end
							end
						end

						ButtonMenu.SideButtonBar.BackgroundColor3 = ButtonMenu.SkillsMenuButton.Color.Value
						ButtonMenu.SideButtonBar.UIStroke.Color = ButtonMenu.SkillsMenuButton.Color.AccentColor.Value
						for _,page in pairs (skillsMenu:GetChildren()) do
							if page:IsA("Frame") and string.match(page.Name, "Page") then
								page.BackgroundColor3 = ButtonMenu.SkillsMenuButton.Color.Value
							end
						end

						SetupPageChange(skillsMenu, ButtonMenu.EmptyNotifier, true, false)
					end


					if tostring(Menu) == "PlayerMenu" then
						Menu.QuickViewMenu.Visible = true
						Menu.QuickViewMenu.QuickViewMenu.Visible = false
						Menu.QuickViewMenu.QuickViewPreview.Visible = true

						--print("Menu == PlayerMenu", ButtonMenu)
						ResetRarityTiles(ButtonMenu)
						SetupPageChange(ButtonMenu, Menu.EmptyNotifier, false, true)

					elseif tostring(Menu) == "ExperienceMenu" then
						EnableOnlyButtonMenu(Menu, true, false)

						Menu.SideButtonBar.Visible = true
						Menu.SideButtonBar.BackgroundColor3 = button.Color.Value
						Menu.SideButtonBar.UIStroke.Color = button.Color.AccentColor.Value
						for _,page in pairs (ButtonMenu:GetChildren()) do
							if page:IsA("Frame") and string.match(page.Name, "Page") then
								page.BackgroundColor3 = button.Color.Value
							end
						end
						Menu.ExpInfoViewerMenu.Visible = false

						local menuName = string.gsub(tostring(button), "MenuButton", "")
						if dataMenu.ExperienceMenu:FindFirstChild(menuName) then
							for _,menu in pairs (dataMenu.ExperienceMenu:GetChildren()) do
								if menu:IsA("Frame") then
									if string.match(menu.Name, "Menu") and menu ~= ButtonMenu then
										menu.Visible = false
									else
										menu.Visible = true
									end
								end
							end

							SetupPageChange(ButtonMenu, Menu.EmptyNotifier, true, false)
						end
					end

					pageManager.CurrentPage.Value = 1

					if ButtonPresses[button] == 0 then
						ButtonPresses[button] = 1
						ReadyMenuButtons(ButtonMenu)
					else
						GuiUtility.CleanupMenuDefaults(Player, ButtonMenu)
					end
				end)

			end
		end

		wait(.1)
		MenuAcceptance = true
	end
end

GuiUtility.Reset3DObject(Player, PlayerViewport, PlayerModel, 178)
GuiUtility.Reset3DObject(Player, equipmentQuickViewMenu.ItemImage)
GuiUtility.Reset3DObject(Player, inventoryQuickViewMenu.ItemImage)

local function GetLevelCounts(statInfo)
	if statInfo["Levels"] then
		local levelCount = #statInfo["Levels"]
		local rewardCount = 0

		for l = 1,levelCount,1 do
			local count = #statInfo["Levels"][l]["Rewards"]
			if count > 0 then
				rewardCount += count
			else
				rewardCount += 1
			end
		end

		return levelCount,rewardCount
	else
		warn(statInfo, " does not have Levels")
	end
end

--------------<|PageManager & Tile-Placement Functions|>---------------------------------------------------------------------------------

local function CompareHighPage(page, HighPage)
	local pageNumber = string.gsub(page.Name, "Page", "")
	if tonumber(pageNumber) > HighPage then
		return tonumber(pageNumber)
	else
		return HighPage
	end	
end

function GetHighPage(Menu, rarityName) --Find page for rarity tile OR max page count
	local highPage = 0
	for i,page in pairs (Menu:GetChildren()) do		
		if page:IsA("Frame") and string.match(page.Name, "Page") then
			if rarityName then
				--Want highest page with tile rarity present
				local RarityIsPresent = false
				for i,tile in pairs (page:GetChildren()) do
					if not RarityIsPresent then
						if (tile:IsA("ImageButton") or tile:IsA("TextButton")) and string.find(tile.Name, "Slot") then
							if tostring(tile.Rarity.Value) == rarityName then
								RarityIsPresent = true
							end
						end
					end
				end

				if RarityIsPresent then
					highPage = CompareHighPage(page, highPage)
				end
			else
				--Want high page
				highPage = CompareHighPage(page, highPage)
			end
		end
	end

	return highPage
end

local function StartPageChange(pageChange)
	if pageDebounce == false then
		local HighPage = GetHighPage(pageManager.Menu.Value)
		local Menu = pageManager.Menu.Value

		if HighPage ~= 1 then --not only one page
			local pageCheck = false
			local overPage
			if pageChange == -1 then
				if pageManager.CurrentPage.Value - 1 == 0 then
					pageCheck = true
					overPage = HighPage
				end
			elseif pageChange == 1 then
				if pageManager.CurrentPage.Value + 1 > HighPage then
					pageCheck = true
					overPage = 1
				end
			end

			local NewPage
			if overPage then
				NewPage = Menu:FindFirstChild("Page" .. tostring(overPage))
				pageManager.CurrentPage.Value = overPage
			else
				NewPage = Menu:FindFirstChild("Page" .. tostring(pageManager.CurrentPage.Value + pageChange))
				pageManager.CurrentPage.Value = pageManager.CurrentPage.Value + pageChange
			end

			pageDebounce = true
			NewPage.Position = UDim2.new(pageChange,0,0,0)
			pageDebounce = GuiUtility.CommitPageChange(NewPage, 0.25)
		else --Bounce Effect (no other pages)
			pageDebounce = true
			Menu.Page1:TweenPosition(UDim2.new(.03*pageChange,0,0,0), "Out", "Quint", .1)
			wait(.1)
			Menu.Page1:TweenPosition(UDim2.new(0,0,0,0), "Out" , "Bounce", .25)
			wait(.25)
			pageDebounce = false
		end
	end
end

local pageBtnScaleChange = 0.045
for i,pageDisplay in pairs (pageManager:GetChildren()) do
	if pageDisplay:FindFirstChild("Next") then
		GuiUtility.SetUpPressableButton(pageDisplay.Next, pageBtnScaleChange)
		pageDisplay.Next.Activated:Connect(function()
			StartPageChange(1)
		end)
	end

	if pageDisplay:FindFirstChild("Previous") then
		GuiUtility.SetUpPressableButton(pageDisplay.Previous, pageBtnScaleChange)
		pageDisplay.Previous.Activated:Connect(function()
			StartPageChange(-1)
		end)
	end
end

local function CreateNewMenuPage(Type, Menu, Page, pageNumber)
	local newPage
	if Type == "Research" then
		newPage = guiElements.ResearchPage:Clone()
	else
		newPage = guiElements.DataMenuPage:Clone()
	end

	newPage.Visible = false
	newPage.Parent = Menu
	newPage.Name = "Page" .. tostring(pageNumber)

	return newPage
end


local function GetHighestSlotOfRarity(Page, rarityName) --highest slot of rarity on page
	local highestSlotValue = 0
	for i,slot in pairs (Page:GetChildren()) do
		if (slot:IsA("ImageButton") or slot:IsA("TextButton")) and string.match(slot.Name, "Slot") then
			if slot.Rarity.Value.Name == rarityName then
				local slotValue = string.gsub(slot.Name, "Slot", "")
				if tonumber(slotValue) > highestSlotValue then
					highestSlotValue = tonumber(slotValue)
				end
			end
		end
	end

	return highestSlotValue
end

local function GetTileTruePosition(Page, PageSlotCount, maxTileAmount)
	local pageNumber = string.gsub(Page.Name, "Page", "")
	local TruePosition = PageSlotCount + ((tonumber(pageNumber) - 1) * maxTileAmount)
	return TruePosition
end

local function SeekSlotAvailability(Menu, Type, checkedPageNumber, rarityName, maxTileAmount)
	local Page
	local TruePosition
	local PageSlotCount = 0

	local possiblePage = Menu:FindFirstChild("Page" .. tostring(checkedPageNumber))
	local highestSlotValue = GetHighestSlotOfRarity(possiblePage, rarityName)
	if highestSlotValue < maxTileAmount then
		Page = possiblePage
		PageSlotCount = highestSlotValue
		TruePosition = GetTileTruePosition(Page, PageSlotCount, maxTileAmount)
	else --newTile cannot fit on checkedPage
		if Menu:FindFirstChild("Page" .. tostring(checkedPageNumber + 1)) then --next page is available
			Page = Menu:FindFirstChild("Page" .. tostring(checkedPageNumber + 1))
		else --no next page, make a new page
			Page = CreateNewMenuPage(Type, Menu, Page, checkedPageNumber + 1)
		end
		PageSlotCount = 0
		TruePosition = GetTileTruePosition(Page, PageSlotCount, maxTileAmount)
	end

	return Page,TruePosition,PageSlotCount
end

local function FindNearbyRarity(Menu, rarityInfo, orderValue, direction)
	if orderValue + direction ~= -1 and orderValue + direction < #rarityInfo.Parent:GetChildren() then
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

local function ManageTilePlacement(menu, menuType, rarityInfo)

	--PAGE SORTING STRATEGY: (Same as research tiles)
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

	local rarityName
	local maxTileAmount
	if rarityInfo then 
		rarityName = rarityInfo.Name

		if string.match(menuType, "Research") then
			if menuType == "Research" then
				maxTileAmount = 5
			else --ResearchDepend
				maxTileAmount = 3
			end
		else
			maxTileAmount = 12 --Inventory was 18
		end
	else --Experience Tiles
		rarityName = "No Rarity"
		maxTileAmount = 4
	end

	local pageCount = GetHighPage(menu)

	local Page
	local TruePosition
	local PageSlotCount = 0 --Position reference, +1 for name (Count=0: "Slot1")
	if pageCount > 0 then
		if rarityName ~= "No Rarity" then
			local highRarityPage = GetHighPage(menu, rarityName)
			local rarityOrderValue = rarityInfo.Order.Value

			if highRarityPage ~= 0 then
				--print("11111111111 highRarityPage ~= 0: ", rarityName)
				Page,TruePosition,PageSlotCount = SeekSlotAvailability(menu, menuType, highRarityPage, rarityName, maxTileAmount)
			else
				--Look for lesser rarity to reference instead
				local lesserRarityPage,lesserRarityName = FindNearbyRarity(menu, rarityInfo, rarityOrderValue, -1)
				if lesserRarityPage then
					--print("22222222222 lesserRarity: ", lesserRarityPage, lesserRarityName)
					Page,TruePosition,PageSlotCount = SeekSlotAvailability(menu, menuType, lesserRarityPage, lesserRarityName, maxTileAmount)

				else --Must be first tile
					Page = menu.Page1
					PageSlotCount = 0
					TruePosition = 0
				end
			end
		else --New experience tiles

			--****Possibly sort alphabetically when no rarity is involved

			Page = menu:FindFirstChild("Page" .. tostring(pageCount))

			local slotCount = 0
			for i,slot in pairs (Page:GetChildren()) do
				if (slot:IsA("TextButton") or slot:IsA("ImageButton")) and string.find(slot.Name, "Slot") then
					slotCount += 1
				end
			end
			PageSlotCount = slotCount
			TruePosition = pageCount*maxTileAmount + PageSlotCount
		end
	else --No pages in menu, make new page
		Page = CreateNewMenuPage(menuType, menu, Page, 1)
		PageSlotCount = 0
		TruePosition = 0
	end

	--Create tile with new-found info
	local newTile
	if menuType == "Experience" then
		newTile = guiElements.ExperienceSlot:Clone()
	elseif string.match(menuType, "Research") then
		newTile = guiElements.ResearchSlot:Clone()
	else
		newTile = guiElements.InventoryMaterialSlot:Clone()
	end

	newTile.Name = "Slot" .. tostring(PageSlotCount + 1)
	newTile.Rarity.Value = rarityInfo
	newTile.TruePosition.Value = TruePosition
	newTile.Parent = Page

	--print("*****", Type, newTile, "'s final values are TruePosition: ", TruePosition, " and PageSlotCount: ", PageSlotCount, " in ", Page)

	--Position tile with new-found info
	ManageTileTruePosition(menu, Page, newTile, TruePosition, maxTileAmount, 1, menuType)

	return newTile
end
ManageTilePlacementFunction.OnInvoke = ManageTilePlacement

local function GetTileSlotCount(Page, tileTruePosition, affectingTile, Change)
	--Count other slots on page
	local PageSlotCount = 0
	for i,slot in pairs (Page:GetChildren()) do
		if (slot:IsA("ImageButton") or slot:IsA("TextButton")) and string.find(slot.Name, "Slot") then
			if slot.TruePosition.Value < tileTruePosition then
				if Change == -1 then
					PageSlotCount -= 1
				else
					PageSlotCount += 1
				end
			end
		end
	end

	return PageSlotCount
end

local function SlotCountToXY(PageSlotCount, tilesPerRow)
	local tileNumber = PageSlotCount
	local rowValue = math.floor(tileNumber / tilesPerRow)
	local columnValue = (PageSlotCount % (tilesPerRow))
	return columnValue, rowValue
end

function ManageTileTruePosition(menu, tilePage, affectingTile, truePosition, maxTileAmount, change, menuType)
	--TruePosition is used to move all other tiles around
	--PageSlotCount is used to position the tile on that page properly
	--Change is how higher TruePosition tiles should move (up 1 or down 1)

	local pageNumber = string.gsub(tilePage.Name, "Page", "")

	for _,page in pairs (menu:GetChildren()) do
		if page:IsA("Frame") and string.find(page.Name, "Page") then
			local currentPageNumber = string.gsub(page.Name, "Page", "")

			--Grab only pages containing tiles that will be affected by this new tile (affectingTile)
			if tonumber(currentPageNumber) >= tonumber(pageNumber) then
				for _,tile in pairs (page:GetChildren()) do
					if (tile:IsA("ImageButton") or tile:IsA("TextButton")) and string.find(tile.Name, "Slot") then
						if tile.TruePosition.Value >= truePosition then --Every tile "above" affecting tile
							local pageSlotCount = 0
							local tilePage

							if tile ~= affectingTile then
								tile.TruePosition.Value += change
								pageSlotCount = GetTileSlotCount(page, tile.TruePosition.Value, affectingTile, change)

								if pageSlotCount >= maxTileAmount then
									--Affected tile will be moved to next page
									if menu:FindFirstChild("Page" .. tostring(tonumber(currentPageNumber) + 1)) then
										tilePage = menu:FindFirstChild("Page" .. tostring(tonumber(currentPageNumber) + 1))
									else --No next page, making new one
										tilePage = CreateNewMenuPage(menuType, menu, tilePage, tonumber(currentPageNumber) + 1)
									end
									pageSlotCount = 0
								elseif pageSlotCount < 0 then
									--Affected tile will be moved to previous page
									tilePage = menu:FindFirstChild("Page" .. tostring(tonumber(currentPageNumber) - 1))
								else
									--Affected tile will stay on this page
									tilePage = page
								end
								tile.Name = "Slot" .. tostring(pageSlotCount + 1)
							else
								if change == -1 then
									tile:Destroy()
								else
									--Will guaranteed be on this page since it was calculated earlier
									pageSlotCount = GetTileSlotCount(page, tile.TruePosition.Value, affectingTile, change)
									tilePage = page
								end
							end

							if tilePage then --Reposition affected tile
								tile.Parent = tilePage

								local truePositionValue = GetTileTruePosition(tilePage, pageSlotCount, maxTileAmount)
								tile.TruePosition.Value = truePositionValue

								if menuType ~= "Experience" or string.match(menuType, "Research") then --straight down insertion
									if menuType == "Experience" then
										tile.Position = UDim2.new(0.023,0,0.023+((pageSlotCount)*0.215),0)
										tile.Size = UDim2.new(0.952, 0, 0.2, 0)
									elseif menuType == "Research" then
										tile.Position = UDim2.new(0.05, 0, 0.054+0.173*pageSlotCount, 0)
										tile.Size = UDim2.new(0.9, 0, 0.14, 0)
									else --ResearchDepend
										tile.Position = UDim2.new(0.036, 0, 0.168 + 0.281*pageSlotCount)
										tile.Size = UDim2.new(0.93, 0, 0.225, 0)
									end
								else --non-list insertion (Inventory & Equipment)
									local tilesPerRow = 4
									local columnValue, rowValue = SlotCountToXY(pageSlotCount, tilesPerRow)
									tile.Position = UDim2.new(0.043+.239*columnValue, 0, 0.028+0.29*rowValue, 0)
									tile.Size = UDim2.new(0.208, 0, 0.258, 0)
								end
							end
						end
					end
				end
			end
		end
	end
end

DepositInventory.OnClientEvent:Connect(function()
	for _,menu in pairs (dataMenu.InventoryMenu:GetChildren()) do
		if menu:IsA("Frame") and menu:FindFirstChild("Page1") then
			for _,page in pairs (menu:GetChildren()) do
				if string.match(page.Name, "Page") then
					page:Destroy()
				end
			end
		end
	end
end)

local researchRewardViewer = dataMenu.ExperienceMenu.ExpInfoViewerMenu.ResearchRewardViewer
local rrPageManager = researchRewardViewer.PageManager

local rewardPageDebounce = false
local rewardPages = researchRewardViewer.RewardPages
rrPageManager.NextPage.Activated:Connect(function()
	if rewardPageDebounce == false then
		rewardPageDebounce = true
		GuiUtility.ChangeToNextPage(rrPageManager, rewardPages)
		rewardPageDebounce = false
	end
end)

rrPageManager.PreviousPage.Activated:Connect(function()
	if rewardPageDebounce == false then
		rewardPageDebounce = true
		GuiUtility.ChangeToPreviousPage(rrPageManager, rewardPages)
		rewardPageDebounce = false
	end
end)

researchRewardViewer.ExitButton.Activated:Connect(function()
	if researchRewardViewer.InfoMenuOpen.Value == true then
		researchRewardViewer.ResearchInfoViewer.Visible = false
		researchRewardViewer.RewardPages.Visible = true
		researchRewardViewer.InfoMenuOpen.Value = false
	else
		researchRewardViewer.Visible = false
		researchRewardViewer.RewardPages.Visible = true
		researchRewardViewer.ResearchInfoViewer.Visible = false
		for _,rewardTile in pairs (researchRewardViewer.RewardPages:GetChildren()) do
			rewardTile:Destroy()
		end
	end
end)

local expInfoViewerMenu = dataMenu.ExperienceMenu.ExpInfoViewerMenu
local levelRewards = expInfoViewerMenu.LevelRewards

local currentPageChangeTweens = {}
local function MoveRewardBackFrame(change, waitAmount)
	local currentLevel = levelRewards.CurrentDisplayLevel.Value
	local levelTile = levelRewards.BackFrame:FindFirstChild("Level" .. tostring(currentLevel))
	local rewardFrameRefer = levelRewards.AbsoluteSize.X/2
	local xPos = rewardFrameRefer - levelTile.Position.X.Offset - levelTile.Size.X.Offset/2
	
	levelRewards.BackFrame.Position = UDim2.new(0, xPos, 0, 0)
	
	if change then
		local changeToLevel = currentLevel + change
		local newLevelTile = levelRewards.BackFrame:FindFirstChild("Level" .. tostring(changeToLevel))
		
		if currentPageChangeTweens[levelRewards] then
			currentPageChangeTweens[levelRewards]:Pause()
		end
		
		if newLevelTile then
			local pageChangeTweenInfo = TweenInfo.new(waitAmount, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			
			local newCenterTile = newLevelTile.Size.X.Offset/2
			local newPos = rewardFrameRefer - newLevelTile.Position.X.Offset - newCenterTile
			
			levelRewards.CurrentDisplayLevel.Value += change
			local pageChangeTween = TweenService:Create(levelRewards.BackFrame, pageChangeTweenInfo, {Position = UDim2.new(0, newPos, 0, 0)})
			currentPageChangeTweens[levelRewards] = pageChangeTween
			pageChangeTween:Play()
			
		else --Bounce Effect
			local levelTileSize = levelTile.Size.X.Offset/2
			
			local oppositeChange = 1
			if change == 1 then
				oppositeChange = -1
			end
			
			local bounceTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			local bounceTween = TweenService:Create(levelRewards.BackFrame, bounceTweenInfo, {Position = UDim2.new(0, xPos + levelTileSize*oppositeChange, 0, 0)})
			currentPageChangeTweens[levelRewards] = bounceTween
			bounceTween:Play()
			
			wait(0.25)
			
			local backBounceTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
			local backBounceTween = TweenService:Create(levelRewards.BackFrame, backBounceTweenInfo, {Position = UDim2.new(0, xPos, 0, 0)})
			currentPageChangeTweens[levelRewards] = backBounceTween
			backBounceTween:Play()
		end
	end
end

levelRewards.NextPage.Activated:Connect(function()
	MoveRewardBackFrame(1, 0.25)
end)

levelRewards.PreviousPage.Activated:Connect(function()
	MoveRewardBackFrame(-1, 0.25)
end)

local itemRewardViewer = expInfoViewerMenu.ItemRewardViewer
itemRewardViewer.ExitButton.Activated:Connect(function()
	itemRewardViewer.Visible = false
end)

local equipmentRewardViewer = expInfoViewerMenu.EquipmentRewardViewer
equipmentRewardViewer.ExitButton.Activated:Connect(function()
	equipmentRewardViewer.Visible = false
end)

--------------<|GUI Information Display Functions|>--------------------------------------------------------------------------------------------------------------------

local function ManageEquipButton(currentlyEquipped, statName, Equip)
	local equipButton = equipmentQuickViewMenu.EquipButton

	if Equip == true or (currentlyEquipped and currentlyEquipped == statName) then
		--"Unequip"
		equipButton.Image = "rbxassetid://6892832163"
		equipButton.HoverImage = "rbxassetid://6933979593"
		equipButton.PressedImage = "rbxassetid://6913278639"
		equipButton.EquipStatus.Value = true
	else
		--"Equip"
		equipButton.Image = "rbxassetid://6892801036"
		equipButton.HoverImage = "rbxassetid://6893271094"
		equipButton.PressedImage = "rbxassetid://6893294832"
		equipButton.EquipStatus.Value = false
	end

	equipButton.Visible = true
end

local levelUpNotify = expInfoViewerMenu.LevelUpNotify
local function DisplayLevelUp(tile, expInfo, unseenRewardCount, currentLevel)
	
	local newLevel = currentLevel - unseenRewardCount + 1
	local levelInfo = expInfo["Levels"][newLevel]
	local prevLevelInfo = expInfo["Levels"][newLevel - 1]

	--Set up top half of screen to display levelup rather than expInfo
	levelUpNotify.Visible = true
	levelUpNotify.BackgroundColor3 = expInfo["ThirdColor"]
	levelUpNotify.LevelDisplay.Level.Text = tostring(newLevel - 1)
		
	if prevLevelInfo then
		levelUpNotify.LevelName.Text = prevLevelInfo["Level Name"]
	end
	
	local levelTile = levelRewards.BackFrame:FindFirstChild("Level" .. tostring(currentLevel))
	levelTile.Progress.Size = UDim2.new(0, 0, 1, 0)
	
	local levelUpDisplay = levelUpNotify.LevelUpDisplay
	levelUpDisplay.Size = UDim2.new(0, 0, 0, 0)
	
	tile.Parent.Parent.Parent.ExpInfoViewerMenu.Visible = true
	wait(1)

	--Roll bottom frame to new level
	MoveRewardBackFrame(1, 1.5)
	
	if levelUpNotify.LevelDisplay:FindFirstChild("PreviousLevel") then
		levelUpNotify.LevelDisplay.PreviousLevel:Destroy()
	end
	
	--Roll number to next level
	local rollToText = levelUpNotify.LevelDisplay.Level:Clone()
	rollToText.Parent = levelUpNotify.LevelDisplay
	rollToText.Text = tostring(newLevel)
	levelUpNotify.LevelDisplay.Level.Name = "PreviousLevel"
	rollToText.Name = "Level"
		
	local rollTextTweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local rollPrevTween = TweenService:Create(levelUpNotify.LevelDisplay.PreviousLevel, rollTextTweenInfo, {Position = UDim2.new(0.5, 0, -0.6, 0)})
	rollPrevTween:Play()
		
	rollToText.Position = UDim2.new(0.5, 0, 1.5, 0)
	local rollTween = TweenService:Create(rollToText, rollTextTweenInfo, {Position = UDim2.new(0.5, 0, 0.4, 0)})
	rollTween:Play()

	--Fill progress bar of level reward tile
	levelTile.Progress.Size = UDim2.new(0, 0, 1, 0)
	levelTile.Progress.Visible = true
			
	local fillTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local fillTween = TweenService:Create(levelTile.Progress, fillTweenInfo, {Size = UDim2.new(1, 0, 1, 0)})
	fillTween:Play()
		
	rollTween.Completed:Wait()
		
	--Bounce effect for new number and extra effects (rotating images, sounds, ui rays, etc.)
	local extraBounceTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
	local extraBounceTween = TweenService:Create(rollToText, extraBounceTweenInfo, {Position = UDim2.new(0.5, 0, 0.5, 0)})
	extraBounceTween:Play()
		
	--Move Pointer
	local pointer = levelRewards.Pointer
	local bouncePointerTweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local bouncePointerTween = TweenService:Create(pointer, bouncePointerTweenInfo, {Position = UDim2.new(0.5, 0, 0.15, 0)})
	bouncePointerTween:Play()
		
	--Change LevelName
	local expandTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local expandTween = TweenService:Create(levelUpNotify.LevelName, expandTweenInfo, {Size = UDim2.new(0.9, 0, 0.23, 0)})
	expandTween:Play()
		
	wait(0.1)
	levelUpNotify.LevelName.Text = levelInfo["Level Name"]
		
	expandTween.Completed:Wait()
		
	local contractTween = TweenService:Create(levelUpNotify.LevelName, expandTweenInfo, {Size = UDim2.new(0.9, 0, 0.2, 0)})
	contractTween:Play()
		
	local contractPointerTweenInfo = TweenInfo.new(0.85, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
	local contractPointerTween = TweenService:Create(pointer, contractPointerTweenInfo, {Position = UDim2.new(0.5, 0, 0.125, 0)})
	contractPointerTween:Play()
	
	local levelUpTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local levelUpTween = TweenService:Create(levelUpDisplay, levelUpTweenInfo, {Size = UDim2.new(0.75, 0, 0.31, 0)})
	levelUpTween:Play()
	
	levelUpTween.Completed:Wait()
	
	local retractLevelUpTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
	local retractLevelUpTween = TweenService:Create(levelUpDisplay, retractLevelUpTweenInfo, {Size = UDim2.new(0.75, 0, 0.27, 0)})
	retractLevelUpTween:Play()
		
	--Udpate unseenReward Count & Give Player Level Rewards
	if dataMenu.Visible == true then
		local moreRewards = awardLevelRewards:InvokeServer(expInfo["StatName"], expInfo["StatType"])
			
		if moreRewards then
			wait(2)
			local hideLevelUpTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			local hideLevelUpTween = TweenService:Create(levelUpDisplay, hideLevelUpTweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
			hideLevelUpTween:Play()
			
			hideLevelUpTween.Completed:Wait()
			
			local newUnseenRewardCount = getCurrentPlayerLevel:InvokeServer(expInfo, nil, true)
			DisplayLevelUp(tile, expInfo, newUnseenRewardCount, getCurrentPlayerLevel:InvokeServer(expInfo))
		else
			GuiUtility.UpdateNotifySymbols(tile.Parent.Parent.Parent, tile, false)
			wait(5)
			levelUpNotify.Visible = false
		end
	end
end

local function DisplayExpRewardInfo(rewardInfo)
	local rewardMenu

	if rewardInfo["Research List"] then
		rewardMenu = researchRewardViewer

		local researchList = rewardInfo["Research List"]
		local researchCount = #researchList

		for r = 1,researchCount,1 do
			local researchRewardInfo = researchList[r]
			local researchRewardTile = guiElements.ResearchRewardTile:Clone()

			local researchName = researchRewardInfo["Research Name"]
			local researchTypeName = researchRewardInfo["Research Type"]

			local pageCount = #rewardMenu.RewardPages:GetChildren()
			if r == 1 or (r-1)%3 == 0 then
				local newResearchRewardPage = guiElements.DataMenuPage:Clone()
				newResearchRewardPage.BackgroundTransparency = 1
				newResearchRewardPage.Name = "Page" .. tostring(pageCount + 1)

				newResearchRewardPage.Parent = rewardMenu.RewardPages
				newResearchRewardPage.Visible = false
				researchRewardTile.Parent = newResearchRewardPage
				pageCount += 1
			else
				researchRewardTile.Parent = rewardMenu.RewardPages:FindFirstChild("Page" .. tostring(pageCount))
			end
			researchRewardTile.Position = UDim2.new(0.116, 0, 0.118 + 0.294*((r-1)-3*(pageCount-1)), 0)

			local shortName = researchName
			if string.len(researchName) > 20 then
				local shortString = string.sub(researchName, 1, 20)
				shortName = shortString .. "..."
			end
			researchRewardTile.ResearchName.Text = researchName

			researchRewardTile.ResearchType.Text = researchTypeName
			researchRewardTile.Picture.Image = researchRewardInfo["Research Image"]
			researchRewardTile.Name = "Reward" .. tostring(r)

			researchRewardTile.Activated:Connect(function()
				researchRewardViewer.InfoMenuOpen.Value = true
				researchRewardViewer.RewardPages.Visible = false

				local researchInfoViewer = researchRewardViewer.ResearchInfoViewer
				researchInfoViewer.Visible = true

				local researchType = string.gsub(researchTypeName, " Research", "") .. " Improvements"
				local researchInfo = getItemStatTable:InvokeServer("Research", nil, researchType, researchName)
				local researchDependsMet = CheckResearchDepends:InvokeServer(researchInfo)

				if researchDependsMet then
					researchInfoViewer.ResearchImage.LockNotify.Visible = false
					researchInfoViewer.ResearchImage.LockImage.Visible = false
					researchInfoViewer.ResearchImage.Image = researchInfo["Research Image"]

					researchInfoViewer.ResearchName.Text = researchName
					researchInfoViewer.ResearchName.TextColor3 = Color3.fromRGB(255, 255, 255)
					researchInfoViewer.ResearchTime.Text = GuiUtility.ToDHMS(researchInfo["Research Length"])
					researchInfoViewer.UnlockedState.Text = "Research Unlocked"
					researchInfoViewer.ComputerNote.Text = "View in your computer for more info"
				else --locked info
					researchInfoViewer.ResearchImage.LockNotify.Visible = true
					researchInfoViewer.ResearchImage.LockImage.Visible = true
					researchInfoViewer.ResearchImage.Image = ""

					researchInfoViewer.ResearchName.Text = "Unknown Research"
					researchInfoViewer.ResearchName.TextColor3 = Color3.fromRGB(226, 226, 226)
					researchInfoViewer.ResearchTime.Text = "Unknown"
					researchInfoViewer.UnlockedState.Text = "Research Locked"
					researchInfoViewer.ComputerNote.Text = "View in your computer for ways to unlock"
				end
			end)
		end

		rewardMenu.PageManager.CurrentPage.Value = 1
		rewardMenu.RewardPages.Page1.Visible = true

	else
		rewardMenu = expInfoViewerMenu:FindFirstChild(rewardInfo[1] .. "RewardViewer")
		local itemInfo = rewardInfo[2]

		rewardMenu.Badge.Image = itemInfo["GUI Info"].BadgeImage.Value
		rewardMenu.ItemName.Text = tostring(itemInfo)

		if rewardInfo[1] == "Item" then
			rewardMenu.RewardAmount.Text = tostring(rewardInfo[3])
			rewardMenu.ItemWorth.Text = tostring(itemInfo.CurrencyValue.Value)
			rewardMenu.StorageAmount.Text = tostring(GetItemCountSum:InvokeServer(tostring(itemInfo)))

			GuiUtility.Display3DModels(Player, rewardMenu.ItemImage, itemInfo:Clone(), true, itemInfo["GUI Info"].DisplayAngle.Value)
		else --Equipment
			local equipType = tostring(itemInfo.Parent.Parent)
			local itemType = tostring(itemInfo.Parent)
			local itemStats = getItemStatTable:InvokeServer("Equipment", equipType, itemType, tostring(itemInfo))

			GuiUtility.Display3DModels(Player, rewardMenu.ItemImage, itemInfo.Handle:Clone(), true, itemInfo["GUI Info"].DisplayAngle.Value)
			ManageStatBars(rewardMenu, itemStats)
		end
	end

	if rewardMenu then
		rewardMenu.Visible = true
	end
end

--Disable rewards buttons depending on visibility of RewardViewers
for _,gui in pairs (expInfoViewerMenu:GetChildren()) do
	if string.match(gui.Name, "RewardViewer") then
		gui:GetPropertyChangedSignal("Visible"):Connect(function()
			local bool = not gui.Visible

			for _,level in pairs (expInfoViewerMenu.LevelRewards.BackFrame:GetChildren()) do
				if level:IsA("Frame") and string.match(level.Name, "Level") then
					for _,reward in pairs (level:GetChildren()) do
						if reward:IsA("ImageButton") and string.match(reward.Name, "Reward") then
							reward.Active = bool
							reward.Selectable = bool
						end
					end
				end
			end

			expInfoViewerMenu.LevelRewards.NextPage.Active = bool
			expInfoViewerMenu.LevelRewards.NextPage.Selectable = bool
			expInfoViewerMenu.LevelRewards.PreviousPage.Active = bool
			expInfoViewerMenu.LevelRewards.PreviousPage.Selectable = bool
		end)
	end
end

local function InsertItemViewerInfo(tile, statMenu, Type, statName, statInfo, value, itemType)

	--**Value is useless in every instance except for stat bar appearance (inventory and experience amounts don't
	--update, they only update to the value they were first created with for the tile.Activated)
	
	if Type == "Inventory" then
		local rarityName = statInfo["GUI Info"].RarityName.Value
		local rarityInfo = guiElements.RarityColors:FindFirstChild(rarityName)
		statMenu.ItemImage.BackgroundColor3 = rarityInfo.TileColor.Value
		statMenu.ItemImageBorder.BackgroundColor3 = rarityInfo.Value

		statMenu.ItemAmount.Text = tile.Amount.Text
		statMenu.ItemWorth.Text = GuiUtility.ConvertShort(statInfo.CurrencyValue.Value)
		
		local expAmount = GuiUtility.ConvertShort(statInfo.Experience.Value)
		statMenu.ExpAmount.Text = "+" .. expAmount .. " EXP"
		statMenu.ExpAmountDropShadow.Text = "+" .. expAmount .. " EXP"

		GuiUtility.Display3DModels(Player, statMenu.ItemImage, statInfo:Clone(), true, statInfo["GUI Info"].DisplayAngle.Value)

	elseif Type == "Experience" then
		equipmentRewardViewer.Visible = false
		itemRewardViewer.Visible = false
		researchRewardViewer.Visible = false
		researchRewardViewer.RewardPages.Visible = true
		researchRewardViewer.InfoMenuOpen.Value = false
		researchRewardViewer.ResearchInfoViewer.Visible = false

		for _,gui in pairs (dataMenu.ExperienceMenu:GetChildren()) do
			if gui:FindFirstChild("Page1") then
				for _,page in pairs (gui:GetChildren()) do
					if page:IsA("Frame") and string.match(page.Name, "Page") then
						for _,tile in pairs (page:GetChildren()) do
							if tile:IsA("ImageButton") and string.match(tile.Name, "Slot") then
								tile.Active = false
								tile.Selectable = false
							end
						end
					end
				end
			end
		end
		
		local levelRewards = statMenu.LevelRewards
		local backFrame = levelRewards.BackFrame
		
		statMenu.ItemImage.Image = statInfo["StatImage"]
		statMenu.ItemName.Text = statInfo["StatName"]
		statMenu.TotalExp.Text = 'Total Exp: <font color="#FFFFFF">' .. value .. '</font>'

		statMenu.CurrentLevel.Text = tile.CurrentLevel.Text
		statMenu.NextLevel.Text = tile.NextLevel.Text
		
		--backFrame.OverallProgress.BackgroundColor3 = statInfo["PrimaryColor"]
		--backFrame.OverallProgress.UIStroke.Color = statInfo["SecondaryColor"]
		
		if statMenu:FindFirstChild("ProgressBar") then
			statMenu.ProgressBar:Destroy()
		end

		local progressBar = tile.ProgressBar:Clone() --Grab progress bar from activated expTile
		progressBar.Parent = statMenu
		progressBar.Position = UDim2.new(0.34, 0, 0.241, 0)
		progressBar.Size = UDim2.new(0.562, 0, 0.109, 0)

		----Update LevelRewards Display----
		local noRewardYPos = 0.369
		local noRewardYSize = 0.18
		local noRewardSizeConversion = 1/3 --xSize is 1/3 of ySize ({0.06,0}{0.18,0} = square)

		local rewardYPos = 0.278
		local rewardYSize = 0.36
		local rewardSizeConversion = 1/6 --xSize is 1/6 of ySize ({0.06}{0.36,0} = tall rectangle)

			--**Use previouspage arrow as xDistance reference for xPos of first tile (yPos is constant)
			--**xSize will be calculated with sizeConversion variable from expRewardTile's constant ySize

		local prevPagePosDiff = 1.22
		local prevPageXPos = levelRewards.PreviousPage.AbsolutePosition.X

		local xSize = levelRewards.PreviousPage.AbsoluteSize.X * 1.05
		local jumpDistance = 1/3*xSize + 0.003*backFrame.Parent.AbsoluteSize.X

		for _,gui in pairs (backFrame:GetChildren()) do
			if gui:IsA("Frame") and string.match(gui.Name, "Level") then
				gui:Destroy()
			end
		end

		local levelCount,skewedRewardCount = GetLevelCounts(statInfo)
		local pageChangeCount = math.ceil(skewedRewardCount/10)
		backFrame.Size = UDim2.new(1*pageChangeCount, 0, 1, 0) --Size backFrame properly
			
		if backFrame:FindFirstChild("Progress") then
			backFrame.Progress:Destroy()
		end
			
		--Update reward tiles roadmap
		for l = 1,levelCount,1 do
			local rewardTile = guiElements.ExpRewardTile:Clone()
			rewardTile.Parent = backFrame
			rewardTile.Name = "Level" .. tostring(l)
			rewardTile.Level.Text = tostring(l)
			
			--rewardTile.BackgroundColor3 = backFrame.OverallProgress.BackgroundColor3
			--rewardTile.UIStroke.Color = backFrame.OverallProgress.UIStroke.Color
			--rewardTile.Progress.BackgroundColor3 = backFrame.OverallProgress.UIStroke.Color

			local levelInfo = statInfo["Levels"][l]
			if l == 1 then --First tile uses prevPageButton to find xPos
				local xPos = (prevPageXPos * prevPagePosDiff) - backFrame.AbsolutePosition.X --+ levelRewards.LeftBorderFrame.AbsoluteSize.X

				rewardTile.Position = UDim2.new(0, xPos, noRewardYPos, 0)
				rewardTile.Size = UDim2.new(0, xSize, noRewardYSize, 0)

			else --All other tiles use previous level's tile to find xPos
				if backFrame:FindFirstChild("Level" .. tostring(l-1)) then
					local previousLevelTile = backFrame:FindFirstChild("Level" .. tostring(l-1))
					local xPos = previousLevelTile.Position.X.Offset + previousLevelTile.Size.X.Offset + jumpDistance

					local rewardCount = #levelInfo["Rewards"]
					if rewardCount > 0 then
						rewardTile.Position = UDim2.new(0, xPos, rewardYPos, 0)

						local xSize = rewardCount*xSize + (rewardCount-1)*jumpDistance
						rewardTile.Size = UDim2.new(0, xSize, rewardYSize, 0)

						--position reward preview tiles
						--(a rewardPreview is 46x59 on a 1271x697 screen (.036,.085))

						if rewardCount > 1 then

							--must find previewWidth since rewardTile xSize changes based on rewardCount
							local jumpSum = 0.56
							for j = 2,rewardCount,1 do
								jumpSum += .56/((j-1)*2) --0.56, 0.28, 0.14, 0.07...
							end
							local previewWidth = 1.237 - jumpSum --Example: 0.56+0.28+0.14 --> 1.237 - .98 = .257

							for r = 1,rewardCount,1 do
								local rewardPreviewTile = guiElements.ExpRewardPreviewTile:Clone()

								local leftoverSpace = 1 - previewWidth*rewardCount
								local diff = leftoverSpace/(rewardCount + 1)

								local previewXPos = r*diff + previewWidth*(r-1) + previewWidth/2 --previewWidth/2 added since anchor is .5,.5

								rewardPreviewTile.Parent = rewardTile
								rewardPreviewTile.Position = UDim2.new(previewXPos, 0, 0.5, 0)
								rewardPreviewTile.Size = UDim2.new(previewWidth, 0, 0.678, 0)
								rewardPreviewTile.Name = "Reward" .. tostring(r)
							end
								
							--Resize and RePosition Level TextLabel
							rewardTile.Level.Position = UDim2.new(0.251, 0, 1.243, 0)
							rewardTile.Level.Size = UDim2.new(0.479, 0, 0.58, 0)
						else
							local rewardPreviewTile = guiElements.ExpRewardPreviewTile:Clone()
							rewardPreviewTile.Parent = rewardTile
							rewardPreviewTile.Position = UDim2.new(0.5, 0, 0.5, 0)
							rewardPreviewTile.Size = UDim2.new(1, 0, 1, 0)
							rewardPreviewTile.Name = "Reward1"

							--local mouseoverInfo = Instance.new("StringValue", rewardPreviewTile)
							--mouseoverInfo.Name = "MouseoverInfo"
							--**MouseoverInfo function must be updated for this to work
						end

						--Last tile will be a research notifier (if a research's skill was met)
						local rewardTilesToFill = rewardCount
						if levelInfo["Rewards"][rewardCount]["Research List"] then
							rewardTilesToFill -= 1

							local researchListTile = rewardTile:FindFirstChild("Reward" .. tostring(rewardCount))
							researchListTile.RewardImage.Image = "rbxassetid://7080090511"

							researchListTile.Activated:Connect(function()
								DisplayExpRewardInfo(levelInfo["Rewards"][rewardCount])
							end)
						end

						--Put reward in tile
						for r = 1,rewardTilesToFill,1 do
							local rewardInfo = levelInfo["Rewards"][r]

							local rewardPreviewTile = rewardTile:FindFirstChild("Reward" .. tostring(r))
							rewardPreviewTile.RewardImage.Image = rewardInfo[2]["GUI Info"].StatImage.Value

							rewardPreviewTile.Activated:Connect(function()
								DisplayExpRewardInfo(rewardInfo)
							end)
						end

					else --noReward
						rewardTile.Position = UDim2.new(0, xPos, noRewardYPos, 0)
						rewardTile.Size = UDim2.new(0, xSize, noRewardYSize, 0)
					end
				end
			end

			rewardTile.Progress.Visible = true
			if l <= tonumber(statMenu.CurrentLevel.Text) then
				rewardTile.Progress.Size = UDim2.new(1, 0, 1, 0)
			else
				rewardTile.Progress.Visible = false
			end
		end
		
		backFrame.OverallProgress.Visible = true
		backFrame.OverallProgress.Position = UDim2.new(0, backFrame.Level1.Position.X.Offset, 0.457, 0)
		local xSize = backFrame:FindFirstChild("Level" .. tostring(levelCount)).Position.X.Offset - backFrame.Level1.Position.X.Offset
		backFrame.OverallProgress.Size = UDim2.new(0, xSize, 0.062, 0)

		local levelTile = backFrame:FindFirstChild("Level" .. tostring(tonumber(statMenu.CurrentLevel.Text)))
		if levelTile then
			local progress = backFrame.OverallProgress:Clone()
			progress.Parent = backFrame
			progress.Name = "Progress"
			progress.BackgroundColor3 = backFrame.OverallProgress.UIStroke.Color
			local progressSize = (levelTile.Position.X.Offset + levelTile.Size.X.Offset) - backFrame.Level1.Position.X.Offset
			progress.Size = UDim2.new(0, progressSize, backFrame.OverallProgress.Size.Y.Scale, 0)

			local currentTile = backFrame:FindFirstChild("Level" .. tostring(tonumber(statMenu.CurrentLevel.Text) + 1))
			local percent = statMenu.ProgressBar.Progress.Size.X.Scale
			local xDiff = currentTile.Position.X.Offset - (levelTile.Position.X.Offset + levelTile.Size.X.Offset)
			backFrame.Progress.Size = UDim2.new(0, progress.Size.X.Offset + (xDiff * percent), backFrame.OverallProgress.Size.Y.Scale, 0)
		end
		
		statMenu.LevelRewards.CurrentDisplayLevel.Value = tonumber(statMenu.CurrentLevel.Text)
		MoveRewardBackFrame()
		
		--See if ExperienceMenu must display NewLevel Animation Sequence
		if tile:FindFirstChild("NotifySymbol") then
			if tile.NotifySymbol.Visible == true then
				local unseenRewardCount = getCurrentPlayerLevel:InvokeServer(statInfo, nil, true)
				local currentLevel = getCurrentPlayerLevel:InvokeServer(statInfo)
				statMenu.LevelRewards.CurrentDisplayLevel.Value = currentLevel - unseenRewardCount
				MoveRewardBackFrame() --Position bottom BackFrame at Level1 so it can be "rolled up"
				
				statMenu.Visible = true
				DisplayLevelUp(tile, statInfo, unseenRewardCount, currentLevel)
			else
				levelUpNotify.Visible = false
			end
		end
		
	else --Equipment
		statMenu.EquipType.Value = Type
		statMenu.ItemType.Value = itemType

		local rarityName = statInfo["GUI Info"].RarityName.Value
		local rarity = guiElements.RarityColors:FindFirstChild(rarityName)
		statMenu.ItemImage.BackgroundColor3 = rarity.TileColor.Value
		statMenu.ItemImageBorder.BackgroundColor3 = rarity.Value

		ManageStatBars(equipmentQuickViewMenu, value)
		ManageEquipButton(dataMenu.PlayerMenu:FindFirstChild(Type .. "MenuButton").CurrentlyEquipped.Value, statName)

		--local ItemModel = game.ReplicatedStorage.Equippable:FindFirstChild(Type):FindFirstChild(AcquiredLocation):FindFirstChild(Stat)

		if statInfo:FindFirstChild("Handle") then
			GuiUtility.Display3DModels(Player, statMenu.ItemImage, statInfo.Handle:Clone(), true, statInfo["GUI Info"].DisplayAngle.Value)
		else
			GuiUtility.Display3DModels(Player, statMenu.ItemImage, guiElements:FindFirstChild("3DObjectPlaceholder"):Clone(), true, statInfo["GUI Info"].DisplayAngle.Value)
		end
	end

	--Display description when InfoButton is pressed!

	for _,button in pairs (statMenu:GetChildren()) do
		if button:IsA("ImageButton") or button:IsA("TextButton") then
			button.Active = true
			button.Selectable = true
		end
	end

	statMenu.ItemName.Text = statName
	statMenu.Visible = true 
end

insertItemViewerInfo.Event:Connect(InsertItemViewerInfo)

local function InsertTileInfo(Type, tile, statName, value, itemType, tileAlreadyPresent)
	tile.StatName.Value = statName

	local statInfo
	local statMenu
	if Type == "Inventory" then
		statMenu = inventoryQuickViewMenu
		statInfo = game.ReplicatedStorage.InventoryItems:FindFirstChild(itemType):FindFirstChild(statName)
		tile.Picture.Image = GuiUtility.GetStatImage(nil, statInfo)
		tile.Amount.Text = GuiUtility.ConvertShort(value)

		if statName == statMenu.ItemName.Text then --Updating currently-open QuickViewMenu
			statMenu.ItemAmount.Text = GuiUtility.ConvertShort(value)
		end

		--Do Rarity Imaging
		local rarityInfo = tile.Rarity.Value
		tile.Image = rarityInfo.TileImages.StaticRarityTile.Value
		tile.HoverImage = rarityInfo.TileImages.HoverRarityTile.Value
		tile.PressedImage = rarityInfo.TileImages.PressedRarityTile.Value

	elseif Type == "Experience" then
		statMenu = expInfoViewerMenu

		local expMenuButton = dataMenu.ExperienceMenu:FindFirstChild(itemType .. "MenuButton")
		if expMenuButton then
			tile.Image = expMenuButton.TileStaticImage.Value
			tile.HoverImage = expMenuButton.TileHoverImage.Value
			
			expMenuButton.Color.UIGradient:Clone().Parent = tile.ProgressBar.Progress
			tile.ProgressBar.BackgroundColor3 = expMenuButton.Color.Value
			tile.ProgressBar.UIStroke.Color = expMenuButton.Color.AccentColor.Value
			tile.PictureBorder.UIStroke.Color = expMenuButton.Color.AccentColor.Value
		end

		statInfo = getItemStatTable:InvokeServer("Experience", nil, itemType, statName)
		local currentLevel,nextLevel = GuiUtility.FindStatLevel(statInfo, value)
		local currentLevelInfo = statInfo["Levels"][currentLevel]
		local nextLevelInfo = statInfo["Levels"][nextLevel]

		tile.DisplayName.Text = statName
		tile.PictureBorder.Picture.Image = statInfo["StatImage"]
		tile.PictureBorder.BackgroundColor3 = statInfo["PrimaryColor"]
		tile.CurrentLevel.Text = tostring(currentLevel)
		tile.NextLevel.Text = tostring(nextLevel)

		local ProgressBar = tile.ProgressBar
		local currentProgressExp = tonumber(value - currentLevelInfo["Exp Requirement"])
		local totalLevelExp = tonumber(nextLevelInfo["Exp Requirement"] - currentLevelInfo["Exp Requirement"])
		ProgressBar.Current.Text = GuiUtility.ConvertShort(currentProgressExp)
		ProgressBar.Total.Text = GuiUtility.ConvertShort(totalLevelExp)

		local percentage = currentProgressExp / totalLevelExp
		ProgressBar.Progress.Size = UDim2.new(percentage, 0, 1, 0)
		
		local unseenRewardCount = getCurrentPlayerLevel:InvokeServer(statInfo, nil, true)
		if unseenRewardCount > 0 then
			GuiUtility.UpdateNotifySymbols(dataMenu.ExperienceMenu:FindFirstChild(itemType .. "Menu"), tile, true)
		else
			tile.NotifySymbol.Visible = false
		end

	else
		statMenu = equipmentQuickViewMenu
		local RSTypeFile = game.ReplicatedStorage.Equippable:FindFirstChild(Type)
		statInfo = RSTypeFile:FindFirstChild(itemType):FindFirstChild(statName)

		tile.Picture.Image = GuiUtility.GetStatImage(nil, statInfo)
		tile.Amount.Visible = false
		local rarityInfo = tile.Rarity.Value
		tile.Image = rarityInfo.TileImages.StaticRarityTile.Value
		tile.HoverImage = rarityInfo.TileImages.HoverRarityTile.Value
		tile.PressedImage = rarityInfo.TileImages.PressedRarityTile.Value
	end

	--ItemViewerMenu GUI Management
	if not tileAlreadyPresent then
		tile.Activated:Connect(function()
			if Type == "Experience" then
				pageManager.Visible = false
				InsertItemViewerInfo(tile, statMenu, Type, statName, statInfo, value, itemType)
			else
				InsertItemViewerInfo(tile, statMenu, Type, statName, statInfo, value, itemType)
				local rarityInfo = tile.Rarity.Value
				local newTileImage = rarityInfo.TileImages.SelectedRarityTile.Value

				local previousTile = statMenu.PreviousTile
				if previousTile.Value then --Visually deselect previous tile
					local prevRarityInfo = previousTile.Value.Rarity.Value
					previousTile.Value.Image = prevRarityInfo.TileImages.StaticRarityTile.Value
				end

				previousTile.Value = tile
				statMenu.Visible = true
				tile.Image = newTileImage
			end	
		end)
	end
end

local SearchBars = {
	pageManager.FullBottomDisplay.SearchBar,
	pageManager.PartialBottomDisplay.SearchBar
}
for i,searchBar in pairs (SearchBars) do
	GuiUtility.ManageSearchVisual(searchBar.SearchInput)
end

for _,button in pairs (dataMenu.ExperienceMenu:GetChildren()) do
	if button:IsA("ImageButton") and string.match(button.Name, "MenuButton") then
		GuiUtility.SetUpPressableButton(button, 0.005)
	end
end

-------------------------------------<|PlayerMenu Functions|>------------------------------------------------------------------------------------------------------------

local PlayerMenu = dataMenu:FindFirstChild("PlayerMenu")
local PlayerInfo = PlayerMenu.PlayerInfo
local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size420x420
local PlayerProfilePicture = game.Players:GetUserThumbnailAsync(Player.UserId, thumbType, thumbSize)

PlayerInfo.PlayerThumbnail.Image = PlayerProfilePicture
PlayerInfo.PlayerName.Text = tostring(Player)

local EquipButton = equipmentQuickViewMenu.EquipButton
local equipBtnScaleChange = 0.008
GuiUtility.SetUpPressableButton(EquipButton, equipBtnScaleChange)

EquipButton.Activated:Connect(function()
	print("Equip button activated")
	if EquipButton.Visible == true then
		EquipButton.Active = false

		local ItemName = equipmentQuickViewMenu.ItemName.Text
		local ItemType = equipmentQuickViewMenu.ItemType.Value
		local EquipType = equipmentQuickViewMenu.EquipType.Value

		if EquipButton.EquipStatus.Value == false then --Equip item
			ManageEquipButton(nil, nil, true)

			UpdateEquippedItem:FireServer(EquipType, ItemType, ItemName)
		else --Unequip item
			local AssociatedInventoryMenu = dataMenu.InventoryMenu:FindFirstChild(string.gsub(ItemType, "Bag", "") .. "Menu")

			if EquipType == "Bags" then
				local ItemCount = AssociatedInventoryMenu:GetAttribute("ItemCount")

				if ItemCount == 0 then
					ManageEquipButton(nil, nil, false)
					UpdateEquippedItem:FireServer(EquipType, ItemType)
				else
					print("Cannot unequip a bag with items in it")
					--Warning message
				end
			else
				ManageEquipButton(nil, nil, false)
				UpdateEquippedItem:FireServer(EquipType, ItemType)
			end
		end
		wait(1)
		EquipButton.Active = true
	end
end)

--May have to use this in item viewer too, so keep as function for now (not only equipment)
local function HideRemainingStatDisplays(menu)
	for i,statDisplay in pairs (menu.StatDisplays:GetChildren()) do
		if statDisplay:FindFirstChild("Utilized") then
			statDisplay.Visible = statDisplay.Utilized.Value
		end
	end
end

function ManageStatBars(menu, itemStats)
	for i,statDisplay in pairs (menu.StatDisplays:GetChildren()) do
		if statDisplay:FindFirstChild("Utilized") then
			statDisplay.Utilized.Value = false
		end
	end

	for stat = 1,#itemStats["Stats"],1 do
		local StatName = itemStats["Stats"][stat][1]
		local StatValue = itemStats["Stats"][stat][2]

		if itemStats["Images"][StatName .. "Image"] then --Displayed on a GUI
			if itemStats["Images"][StatName .. "Image"][2] then --Associated ImageType
				local ImageId = itemStats["Images"][StatName .. "Image"][1]
				local ImageType = itemStats["Images"][StatName .. "Image"][2]

				local FoundStatDisplay = false
				for i,statDisplay in pairs (menu.StatDisplays:GetChildren()) do
					if FoundStatDisplay == false then
						if string.find(tostring(statDisplay), ImageType) and statDisplay:FindFirstChild("Utilized") then
							if statDisplay.Utilized.Value ~= true then
								statDisplay.Utilized.Value = true
								FoundStatDisplay = true

								if type(StatValue) == "number" then
									if math.abs(StatValue) < 1 then --Remove 0 before decimal
										local RemovedZero = string.gsub(tostring(StatValue), "0." , "")
										statDisplay.StatValue.Text = "." .. RemovedZero
									else
										statDisplay.StatValue.Text = StatValue
									end
								end

								if ImageType == "StatBar" then
									local MaxStatValue = guiElements.MaxStatValues:FindFirstChild(StatName).Value
									statDisplay.ProgressBar.Progress.Size = UDim2.new(StatValue/MaxStatValue, 0, 1, 0)
									statDisplay.StatImageBorder.StatImage.Image = ImageId
									statDisplay.StatName.Text = StatName
								else --Badge
									statDisplay.Image = ImageId
								end
							end
						end
					end	
				end
			else
				--possibly display in info menu? (non-statbars images and non-badge image)
			end	
		end
	end

	HideRemainingStatDisplays(menu)
end

-----------------<Overall ManageTiles Function|>----------------------------------------------------------------------

local function ManageTiles(statName, Menu, value, Type, itemType, updateNotify)
	--print(Stat,Menu,Value,Type,AcquiredLocation) = Stone,OresMenu,2,Inventory,Mineshaft

	local rarityInfo
	if Type ~= "Experience" then
		local statLocation
		if Type == "Inventory" then
			statLocation = game.ReplicatedStorage.InventoryItems:FindFirstChild(itemType):FindFirstChild(statName)
		else
			statLocation = game.ReplicatedStorage.Equippable:FindFirstChild(Type):FindFirstChild(itemType):FindFirstChild(statName)
		end
		
		local rarityName = statLocation["GUI Info"].RarityName.Value
		rarityInfo = guiElements.RarityColors:FindFirstChild(rarityName)
	end

	local tile
	for _,page in pairs (Menu:GetChildren()) do
		if page:IsA("Frame") and string.find(page.Name, "Page") then

			for _,slot in pairs (page:GetChildren()) do
				if (slot:IsA("ImageButton") or slot:IsA("TextButton")) and string.find(slot.Name, "Slot") then
					local slotItemName = slot.StatName.Value

					if slotItemName == statName then
						tile = slot
					end
				end
			end
		end
	end
	
	if tile then
		InsertTileInfo(Type, tile, statName, value, itemType, true)
	else
		local newTile = ManageTilePlacement(Menu, Type, rarityInfo)
		tile = newTile
		newTile.Active = true
		newTile.Selectable = true
		InsertTileInfo(Type, newTile, statName, value, itemType)
	end
	
	if updateNotify and tile then
		GuiUtility.UpdateNotifySymbols(Menu, tile, true)
	end
end

-------------------------------------<High-Traffic Events>-------------------------------------------------------------------------------------------------------------

updateInventory.OnClientEvent:Connect(function(statName, itemType, value, Type)
	local menu = dataMenu.InventoryMenu.MaterialsMenu
	
	if tonumber(value) ~= 0 and not string.match(statName, "Discovered") then
		ManageTiles(statName, menu, tonumber(value), Type, itemType)
	end
end)

updateExperience.OnClientEvent:Connect(function(expName, expType, expAmount, Type, amountAdded, levelUp)
	local menu = dataMenu.ExperienceMenu:FindFirstChild(expType .. "Menu")
	
	--**Separate from updateinventory so levelup can be used by this function to manage the new notify
	--New notify will probably be different to prepare for each of these types, so parameters will start to diverge
	--However, they probably will use the same function that changes the new notify symbol visibilty of the menu
	--and the parent menus

	if tonumber(expAmount) ~= 0 then --Mix this with menu existence check in ManageTiles function
		ManageTiles(expName, menu, tonumber(expAmount), Type, expType, levelUp)
	end
end)

UpdatePlayerMenu.OnClientEvent:Connect(function(equipType, itemType, itemName)
	local itemInfo = game.ReplicatedStorage.Equippable:FindFirstChild(equipType):FindFirstChild(itemType):FindFirstChild(itemName)
	local AssociatedMenu = PlayerMenu:FindFirstChild(equipType .. "Menu")
	local AssociatedButton = PlayerMenu:FindFirstChild(equipType .. "MenuButton")

	local itemStats = getItemStatTable:InvokeServer("Equipment", equipType, itemType, itemName)
	ManageTiles(itemName, AssociatedMenu, itemStats, equipType, itemType)
end)

UpdateEquippedItem.OnClientEvent:Connect(function(equipType, itemType, item)
	local defaultMenuButton = PlayerMenu:FindFirstChild(equipType .. "MenuButton")
	defaultMenuButton.CurrentlyEquipped.Value = item

	if item and item ~= "" then
		local itemInfo = game.ReplicatedStorage.Equippable:FindFirstChild(equipType):FindFirstChild(itemType):FindFirstChild(item)
		local itemImage = GuiUtility.GetStatImage(nil, itemInfo)

		defaultMenuButton.ItemImage.Image = itemImage
	else
		defaultMenuButton.ItemImage.Image = ""
	end

	--Highlight Equipped Item
	for _,page in pairs (PlayerMenu:FindFirstChild(equipType .. "Menu"):GetChildren()) do
		for _,tile in pairs (page:GetChildren()) do
			if tile:IsA("TextButton") then
				if tile.StatName.Value == item then
					tile.BackgroundColor3 = Color3.fromRGB(85, 170, 255) --Brighter blue (or player's fav color later)
				else
					tile.BackgroundColor3 = Color3.fromRGB(47, 95, 143) --Darker accent color
				end
			end
		end
	end
end)

game.Workspace.Players:WaitForChild(tostring(Player)).Archivable = true

ReadyMenuButtons(dataMenu)
ReadyMenuButtons(dataMenu.PlayerMenu) --Prep menu buttons on default screen
--**Will the inventory menu be prepared by these two so the item popups can go directly to it, or will this script
--have to also prep the inventory menu and other menu tabs?


wait(3)
script.Parent.OpenDataMenuButton.Active = true

