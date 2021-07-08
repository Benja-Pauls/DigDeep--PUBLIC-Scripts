local TweenService = game:GetService("TweenService")
local Camera = game.Workspace.CurrentCamera

--local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
--playerGui:SetTopbarTransparency(1)
script.Parent.OpenDataMenuButton.Visible = true

local Player = game.Players.LocalPlayer
local PlayerUserId = Player.UserId
local OpenDataMenuButton = script.Parent.OpenDataMenuButton
local DataMenu = script.Parent.DataMenu
local GuiElements = game.ReplicatedStorage.GuiElements
local PageManager = DataMenu.PageManager

local eventsFolder = game.ReplicatedStorage.Events

local GuiUtility = require(game.ReplicatedStorage:FindFirstChild("GuiUtility"))

if DataMenu.Visible == true then
	DataMenu.Visible = false
end

OpenDataMenuButton.Active = false --re-enable when script is ready

--Reset DataMenu on load
for i,v in pairs (DataMenu:GetChildren()) do
	if v:IsA("Frame") and tostring(v) ~= "TopTabBar" and tostring(v) ~= "AccentBorder" then
		v.Visible = false
	end
end

local MenuTabs = {
	DataMenu.PlayerMenuButton, 
	DataMenu.InventoryMenuButton, 
	DataMenu.ExperienceMenuButton,
	DataMenu.JournalMenuButton
}

local tabSelection = DataMenu.TopTabBar.TabSelection
local tsWidth = tabSelection.Size.X.Scale
local previousTween
for i,v in pairs (MenuTabs) do
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
			
			for i,tab in pairs (MenuTabs) do
				if tab ~= v then --other tabs
					tab.Active = false
						
					if tab.Image == tab.SelectedImage.Value then
						tab.Image = tab.StaticImage.Value
					end
				end
			end
			
			for i,tab in pairs (MenuTabs) do
				tab.Active = true
			end
		end
	end)
end

local InventoryOpens = 0
local PlayerViewport = DataMenu.PlayerMenu.PlayerInfo.PlayerView
local PlayerModel = game.Workspace.Players:WaitForChild(tostring(Player))
OpenDataMenuButton.Activated:Connect(function()
	if DataMenu.Visible == false then
		DataMenu.Position = UDim2.new(0.159, 0, -.8, 0)
		DataMenu.Visible = true
		DataMenu.PlayerMenu.Visible = true
		DataMenu.TopTabBar.CloseMenu.Active = true
		OpenDataMenuButton.Active = false
		
		--CheckForNewItems()
		
		DataMenu.PlayerMenu.Visible = true
		DataMenu:TweenPosition(UDim2.new(0.159, 0, 0.173, 0), "Out", "Quint", 0.5)
		
		--Manage Tabs
		if InventoryOpens == 0 then
			InventoryOpens = 1
			DataMenu.InventoryMenu.SelectedBagInfo.Visible = false
			ReadyMenuButtons(DataMenu)
			ReadyMenuButtons(DataMenu.PlayerMenu) --Prep menu buttons on default screen
		else
			--Reset Tab Selection
			for i,tab in pairs (MenuTabs) do
				if tab.Name == "PlayerMenuButton" then
					local playerMenuButton = DataMenu.PlayerMenuButton
					local tabWidth = playerMenuButton.Size.X.Scale
					local newSelectPos = math.abs(tabWidth - tsWidth)/2 + playerMenuButton.Position.X.Scale
					tabSelection.Position = UDim2.new(newSelectPos, 0, 0.888, 0)
					playerMenuButton.Image = playerMenuButton.SelectedImage.Value
					playerMenuButton.Active = true
				else
					tab.Image = tab.StaticImage.Value
				end
			end
			
			CleanupMenuTabs(DataMenu)
		end
		
		DataMenu.PlayerMenu.Visible = true
		GuiUtility.Display3DModels(Player, PlayerViewport, PlayerModel:Clone(), true, 178)
		
		wait(0.5)
		OpenDataMenuButton.Active = true
		
	elseif DataMenu.Visible == true then
		OpenDataMenuButton.Active = false
		DataMenu:TweenPosition(UDim2.new(0.159, 0, -0.8, 0), "Out", "Quint", 0.5)
		wait(0.5)
		DataMenu.Visible = false
		DataMenu.Position = UDim2.new(0.159, 0, 0.141, 0)
		PageManager.Visible = false
		
		DataMenu.TopTabBar.CloseMenu.Active = false
		OpenDataMenuButton.Active = true
	end
end)

DataMenu.TopTabBar.CloseMenu.Activated:Connect(function()
	DataMenu.TopTabBar.CloseMenu.Active = false
	OpenDataMenuButton.Active = false
	DataMenu:TweenPosition(UDim2.new(0.159, 0, -0.8, 0), "Out", "Quint", .5)
	wait(.5)
	DataMenu.Visible = false
	DataMenu.Position = UDim2.new(0.159, 0, 0.141, 0)
	PageManager.Visible = false

	OpenDataMenuButton.Active = true
end)

local MoveAllBaseScreenUI = eventsFolder.GUI:WaitForChild("MoveAllBaseScreenUI")
MoveAllBaseScreenUI.Event:Connect(function(ChangeTo)
	DataMenu.Visible = false
	if ChangeTo == "Hide" then
		OpenDataMenuButton:TweenPosition(UDim2.new(-.15, 0, OpenDataMenuButton.Position.Y.Scale, 0), "Out", "Quint", 1)
	else
		OpenDataMenuButton:TweenPosition(UDim2.new(0.01, 0, 0.8, 0), "Out", "Quint", 1)
	end
end)

--------------<|Utility Functions|>-----------------------------------------------------------------------------
local inventoryQuickViewMenu = DataMenu.InventoryMenu.QuickViewMenu.QuickViewMenu
local equipmentQuickViewMenu = DataMenu.PlayerMenu.QuickViewMenu.QuickViewMenu

local function EnableOnlyButtonMenu(buttonMenu, bool, descendantsSeek)
	if descendantsSeek then
		for i,button in pairs (buttonMenu:GetDescendants()) do
			if button:IsA("ImageButton") or button:IsA("TextButton") then
				button.Active = bool
				button.Selectable = bool
			end
		end
	else
		for i,button in pairs (buttonMenu:GetChildren()) do
			if button:IsA("ImageButton") or button:IsA("TextButton") then
				button.Active = bool
				button.Selectable = bool
			end
		end
	end
end

local function ResetRarityTiles(Menu)
	for i,page in pairs (Menu:GetChildren()) do
		if page:IsA("Frame") and string.find(page.Name, "Page") then
			for i,tile in pairs (page:GetChildren()) do
				if tile:IsA("ImageButton") and string.find(tile.Name, "Slot") then
					local rarityInfo = tile.Rarity.Value
					tile.Image = rarityInfo.TileImages.StaticRarityTile.Value
				end
			end
		end
	end
end

local ButtonPresses = {}
local pageDebounce = false
local MenuAcceptance = true
function ReadyMenuButtons(Menu)
	
	if MenuAcceptance == true then
		MenuAcceptance = false
		for i,button in pairs(Menu:GetChildren()) do
			if (button:IsA("TextButton") or button:IsA("ImageButton")) and button:FindFirstChild("Menu") then
				ButtonPresses[button] = 0
				local associatedMenuName = button:FindFirstChild("Menu").Value
				local ButtonMenu = Menu:FindFirstChild(associatedMenuName)
				
				print("Menu:",Menu, " ButtonMenu:",ButtonMenu)
				
				--First Time Default Menu Setup
				if ButtonMenu.Name ~= "PlayerMenu" then
					ButtonMenu.Visible = false
				else
					ButtonMenu.Visible = true
					ButtonMenu.EmptyNotifier.Visible = false
					ButtonMenu.QuickViewMenu.Visible = false
					--UpdateBagDisplays(Menu, ButtonMenu)		
				end
				
				if ButtonMenu:FindFirstChild("FirstSeeMenu") then
					ButtonMenu.Visible = true
				end
				
				button.Activated:Connect(function()
					--Reset new item notifiers
					if button:FindFirstChild("NewItem") then
						button.NewItem.Value = false
					end
					
					for i,v in pairs (ButtonMenu.Parent:GetChildren()) do
						if v:IsA("Frame") and not v:FindFirstChild("Menu") then
							if tostring(v) ~= "TopTabBar" and tostring(v) ~= "AccentBorder" then
								v.Visible = false
							end
						end
					end
					ButtonMenu.Visible = true
					
					--Enable only current menu's buttons
					for i,menu in pairs (DataMenu:GetChildren()) do
						if string.find(menu.Name, "Menu") and menu:IsA("Frame") then
							EnableOnlyButtonMenu(menu, false, true)
						end
					end
					EnableOnlyButtonMenu(ButtonMenu, true, true)
					
					if tostring(ButtonMenu) == "InventoryMenu" then
						ButtonMenu.EmptyNotifier.Visible = false
						
						inventoryQuickViewMenu.Visible = false
						ButtonMenu.QuickViewMenu.QuickViewPreview.Visible = true
						
						local MaterialsMenu = ButtonMenu.MaterialsMenu
						local bagCapacity = MaterialsMenu:GetAttribute("BagCapacity")
						local itemCount = MaterialsMenu:GetAttribute("ItemCount")
						
						if bagCapacity and itemCount then
							ButtonMenu.SelectedBagInfo.BagAmount.Text = tostring(itemCount) .. "/" .. tostring(bagCapacity)
							ButtonMenu.SelectedBagInfo.FillProgress.Size = UDim2.new(itemCount/bagCapacity, 0, 1, 0)
							ButtonMenu.SelectedBagInfo.BagType.Value = string.gsub(tostring(ButtonMenu), "Menu", "")
							ButtonMenu.SelectedBagInfo.Visible = true
						else
							ButtonMenu.SelectedBagInfo.Visible = false
						end
						
						ResetRarityTiles(ButtonMenu.MaterialsMenu)
						
						PageManager.Menu.Value = MaterialsMenu
						local PageCount = GetHighPage(MaterialsMenu)
						if PageCount > 0 then
							PageManager.Visible = true
							--PageManager.FullBottomDisplay.Visible = true
							PageManager.PartialBottomDisplay.Visible = true
							if MaterialsMenu:FindFirstChild("Page1") then
								pageDebounce = true
								pageDebounce = GuiUtility.CommitPageChange(MaterialsMenu.Page1, 0.25)
							end
						else
							ButtonMenu.EmptyNotifier.Visible = true
						end
						
					elseif tostring(ButtonMenu) == "PlayerMenu" then
						ButtonMenu.EmptyNotifier.Visible = false
						PageManager.FullBottomDisplay.Visible = false
						PageManager.PartialBottomDisplay.Visible = false
						
						ButtonMenu.QuickViewMenu.Visible = false
						ButtonMenu.PlayerInfo.Visible = true
						
					elseif tostring(ButtonMenu) == "ExperienceMenu" then
						local skillsMenu = ButtonMenu.SkillsMenu
						for _,menu in pairs (DataMenu.ExperienceMenu:GetChildren()) do
							if menu:IsA("Frame") then
								if string.match(menu.Name, "Menu") and menu ~= skillsMenu then
									menu.Visible = false
								else
									menu.Visible = true
								end
							end
						end
						
						ButtonMenu.SideButtonBar.BackgroundColor3 = ButtonMenu.SkillsMenuButton.Color.Value
						
						PageManager.Menu.Value = skillsMenu
						local PageCount = GetHighPage(skillsMenu)
						if PageCount > 0 then
							PageManager.Visible = true
							PageManager.FullBottomDisplay.Visible = true
							PageManager.PartialBottomDisplay.Visible = false

							if skillsMenu:FindFirstChild("Page1") then
								pageDebounce = true
								pageDebounce = GuiUtility.CommitPageChange(skillsMenu.Page1, 0.25)
							end
						else
							Menu.EmptyNotifier.Visible = true
						end
					end
					
					if tostring(Menu) == "PlayerMenu" then
						Menu.QuickViewMenu.Visible = true
						Menu.QuickViewMenu.QuickViewMenu.Visible = false
						Menu.QuickViewMenu.QuickViewPreview.Visible = true
						
						--print("Menu == PlayerMenu", ButtonMenu)
						ResetRarityTiles(ButtonMenu)
						
						PageManager.Menu.Value = ButtonMenu
						local PageCount = GetHighPage(ButtonMenu)
						if PageCount > 0 then
							PageManager.Visible = true
							PageManager.FullBottomDisplay.Visible = false
							PageManager.PartialBottomDisplay.Visible = true
							if ButtonMenu:FindFirstChild("Page1") then
								pageDebounce = true
								pageDebounce = GuiUtility.CommitPageChange(ButtonMenu.Page1, 0.25)
							end
						else
							Menu.EmptyNotifier.Visible = true
						end
						
					elseif tostring(Menu) == "ExperienceMenu" then
						EnableOnlyButtonMenu(Menu, true, false)
						GuiUtility.SetUpPressableButton(button, 0.005)
						
						Menu.SideButtonBar.Visible = true
						Menu.SideButtonBar.BackgroundColor3 = button.Color.Value
						
						local menuName = string.gsub(tostring(button), "MenuButton", "")
						if DataMenu.ExperienceMenu:FindFirstChild(menuName) then
							for _,menu in pairs (DataMenu.ExperienceMenu:GetChildren()) do
								if menu:IsA("Frame") then
									if string.match(menu.Name, "Menu") and menu ~= ButtonMenu then
										menu.Visible = false
									else
										menu.Visible = true
									end
								end
							end
							
							PageManager.Menu.Value = ButtonMenu
							local PageCount = GetHighPage(ButtonMenu)
							if PageCount > 0 then
								PageManager.Visible = true
								PageManager.FullBottomDisplay.Visible = true
								PageManager.PartialBottomDisplay.Visible = false

								if ButtonMenu:FindFirstChild("Page1") then
									pageDebounce = true
									pageDebounce = GuiUtility.CommitPageChange(ButtonMenu.Page1, 0.25)
								end
							else
								Menu.EmptyNotifier.Visible = true
							end
						end
					end
					
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

GuiUtility.Reset3DObject(Player, PlayerViewport, PlayerModel, 178)
GuiUtility.Reset3DObject(Player, equipmentQuickViewMenu.ItemImage)
GuiUtility.Reset3DObject(Player, inventoryQuickViewMenu.ItemImage)

function CleanupMenuTabs(Menu)
	--Prep Default Menu
	if Menu.Name == "DataMenu" or Menu.Name == "PlayerMenu" then
		for _,gui in pairs (DataMenu.PlayerMenu:GetChildren()) do
			gui.Visible = false
			
			if gui:IsA("ImageButton") then
				gui.Visible = true
				gui.Active = true
			end
		end
		DataMenu.PlayerMenu.PlayerInfo.Visible = true
	end
	
	for _,button in pairs(Menu:GetChildren()) do
		if (button:IsA("TextButton") or button:IsA("ImageButton")) and button:FindFirstChild("Menu") then
			local AssociatedMenuName = button:FindFirstChild("Menu").Value
			local ButtonMenu = Menu:FindFirstChild(AssociatedMenuName)
			
			ButtonMenu.Visible = false
			if Menu == DataMenu.InventoryMenu then
				DataMenu.InventoryMenu.SelectedBagInfo.Visible = false
			end
		end
	end
	
	if Menu.Name == "ExperienceMenu" then
		Menu.SkillsMenu.Visible = true
		Menu.SideButtonBar.Visible = true
	end
end

local TI = TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
local startingPos = Vector2.new(-1.2, 0) --Start on right
local waitPeriod = 2.5

--****Replace shine effect with small notification circle in corner of tile
local function AnimateShine(button)
	local Gradient = button.UIGradient
	local ShineEffect = TweenService:Create(Gradient, TI, {Offset = Vector2.new(1.2, 0)})
	
	Gradient.Offset = startingPos
	ShineEffect:Play()
	ShineEffect.Completed:Wait()
	
	Gradient.Offset = startingPos
	ShineEffect:Play()
	ShineEffect.Completed:Wait()
	
	if button.NewItem.Value == true then
		wait(waitPeriod)
		AnimateShine(button)
	end
end

function CheckForNewItems()
	local NewItemButtons = {}
	
	for i,button in pairs (DataMenu.PlayerMenu:GetChildren()) do
		if button:IsA("ImageButton") then
			button.UIGradient.Offset = Vector2.new(1.5, 0)
			if button.NewItem.Value == true then
				table.insert(NewItemButtons, button)
			end
		end
	end
	
	--Put something in the corner of the tile to alert there is something new (only in equipment)
	--openning the menu alone is enough to show that it has been "seen": player does not need to click on the item
	
	--Show that tile has something new
	--coroutine.resume(coroutine.create(function()
		--for button = 1,#NewItemButtons,1 do
			--AnimateShine(NewItemButtons[button])
		--end
	--end))
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

local mouse = Player:GetMouse()
local mouseoverDisplay = Player.PlayerGui.PopUps.MouseoverPopUp.MouseoverDisplay
mouseoverDisplay.Visible = false
local function CountdownToMouseDisplay(timeBeforeAppear)
	local timer = mouseoverDisplay.TimeLeft
	timer.Value = 0
	
	coroutine.resume(coroutine.create(function()
		for sec = 1,timeBeforeAppear,1 do
			wait(1)
			
			if sec == timer.Value + 1 then --this is still countdown function
				timer.Value = sec
				if sec == timeBeforeAppear then
					mouseoverDisplay.Visible = true
				end
			end
		end
	end))
end

--Display small tip when hovering over some GUI
local mouseDisplayGuiUsed = false
for i,gui in pairs (DataMenu:GetDescendants()) do
	if gui:FindFirstChild("MouseoverInfo") then
		gui.MouseEnter:Connect(function()
			mouseDisplayUsed = true
			mouseoverDisplay.Visible = false

			local charCount = string.len(" " .. gui.MouseoverInfo.Value)
			mouseoverDisplay.Size = UDim2.new(0.007 * charCount, 0, mouseoverDisplay.Size.Y.Scale, 0)
			mouseoverDisplay.Position = UDim2.new(0.017, mouse.X, 0, mouse.Y)
			mouseoverDisplay.TextLabel.Text = "<b>" .. gui.MouseoverInfo.Value .. "</b>"
			mouseoverDisplay.TextLabel.UIPadding.PaddingLeft = UDim.new(0.05 * (1-0.007*charCount))
			
			CountdownToMouseDisplay(2)
		end)

		gui.MouseLeave:Connect(function()
			mouseDisplayUsed = false
			mouseoverDisplay.Visible = false
			mouseoverDisplay.TimeLeft.Value = -1
		end)
	end
end

mouse.Move:Connect(function()
	if mouseDisplayUsed == true then
		mouseoverDisplay.Position = UDim2.new(0.017, mouse.X, 0, mouse.Y)
		--mouseoverDisplay.Visible = false (keep visible once touched)
		--CountdownToMouseDisplay(2)
	end
end)

--------------<|PageManager Functions|>---------------------------------------------------------------------------------

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
		if page:IsA("Frame") and string.find(page.Name, "Page") then
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

--[[
function CommitPageChange(Page)
	Page.ZIndex += 1
	Page.Visible = true
	Page:TweenPosition(UDim2.new(0,0,0,0), "Out", "Quint", .25)
	wait(.25)
	
	--Manage Page Invisibility
	for i,page in pairs (Page.Parent:GetChildren()) do
		if page:IsA("Frame") then
			if page ~= Page then
				page.Visible = false
			else
				page.Visible = true
			end
		end
	end
	Page.ZIndex -= 1
	PageDebounce = false
end
]]

local function StartPageChange(pageChange)
	if pageDebounce == false then
		local HighPage = GetHighPage(PageManager.Menu.Value)
		local Menu = PageManager.Menu.Value
		
		if HighPage ~= 1 then --not only one page
			local pageCheck = false
			local overPage
			if pageChange == -1 then
				if PageManager.CurrentPage.Value - 1 == 0 then
					pageCheck = true
					overPage = HighPage
				end
			elseif pageChange == 1 then
				if PageManager.CurrentPage.Value + 1 > HighPage then
					pageCheck = true
					overPage = 1
				end
			end

			local NewPage
			if overPage then
				NewPage = Menu:FindFirstChild("Page" .. tostring(overPage))
				PageManager.CurrentPage.Value = overPage
			else
				NewPage = Menu:FindFirstChild("Page" .. tostring(PageManager.CurrentPage.Value + pageChange))
				PageManager.CurrentPage.Value = PageManager.CurrentPage.Value + pageChange
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
for i,pageDisplay in pairs (PageManager:GetChildren()) do
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
		newPage = GuiElements.ResearchPage:Clone()
	else
		newPage = GuiElements.DataMenuPage:Clone()
	end
	
	newPage.Visible = false
	newPage.Parent = Menu
	newPage.Name = "Page" .. tostring(pageNumber)
	
	return newPage
end


local function GetHighestSlotOfRarity(Page, rarityName) --highest slot of rarity on page
	local highestSlotValue = 0
	for i,slot in pairs (Page:GetChildren()) do
		if (slot:IsA("ImageButton") or slot:IsA("TextButton")) and string.find(slot.Name, "Slot") then
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
		if Menu:findFirstChild("Page" .. tostring(checkedPageNumber + 1)) then --next page is available
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

local function ManageTilePlacement(Menu, Type, rarityInfo)
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
		
		if Type == "Research" then
			print("Research Tile")
			maxTileAmount = 5
		else
			maxTileAmount = 12 --Inventory was 18
		end
	else --Experience Tiles
		rarityName = "No Rarity"
		maxTileAmount = 4
	end
	
	local pageCount = GetHighPage(Menu)

	local Page
	local TruePosition
	local PageSlotCount = 0 --Position reference, +1 for name (Count=0: "Slot1")
	if pageCount > 0 then
		if rarityName ~= "No Rarity" then
			local highRarityPage = GetHighPage(Menu, rarityName)
			local rarityOrderValue = rarityInfo.Order.Value
			
			if highRarityPage ~= 0 then
				--print("11111111111 highRarityPage ~= 0: ", rarityName)
				Page,TruePosition,PageSlotCount = SeekSlotAvailability(Menu, Type, highRarityPage, rarityName, maxTileAmount)
			else
				--Look for lesser rarity to reference instead
				local lesserRarityPage,lesserRarityName = FindNearbyRarity(Menu, rarityInfo, rarityOrderValue, -1)
				if lesserRarityPage then
					--print("22222222222 lesserRarity: ", lesserRarityPage, lesserRarityName)
					Page,TruePosition,PageSlotCount = SeekSlotAvailability(Menu, Type, lesserRarityPage, lesserRarityName, maxTileAmount)
				else
					--Look for higher rarity to reference instead
					local higherRarityPage,higherRarityName = FindNearbyRarity(Menu, rarityInfo, rarityOrderValue, 1)
					if higherRarityPage then
						--print("3333333333 higherRarityName: ", higherRarityPage, higherRarityName)
						Page,TruePosition,PageSlotCount = SeekSlotAvailability(Menu, Type, higherRarityPage, higherRarityName, maxTileAmount)
					end
				end
			end
		else --New experience tiles
		
			--****Possibly sort alphabetically when no rarity is involved
			
			Page = Menu:FindFirstChild("Page" .. tostring(pageCount))
			
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
		Page = CreateNewMenuPage(Type, Menu, Page, 1)
		PageSlotCount = 0
		TruePosition = 0
	end
	
	--Create tile with new-found info
	local newTile
	if Type == "Experience" then
		newTile = GuiElements.ExperienceSlot:Clone()
	elseif Type == "Research" then
		newTile = GuiElements.ResearchSlot:Clone()
	else
		newTile = GuiElements.InventoryMaterialSlot:Clone()
	end
	
	newTile.Name = "Slot" .. tostring(PageSlotCount + 1)
	newTile.Rarity.Value = rarityInfo
	newTile.TruePosition.Value = TruePosition
	newTile.Parent = Page
	
	--print("*****", Type, newTile, "'s final values are TruePosition: ", TruePosition, " and PageSlotCount: ", PageSlotCount, " in ", Page)
	
	--Position tile with new-found info
	ManageTileTruePosition(Menu, Page, newTile, TruePosition, maxTileAmount, 1, Type)
	
	return newTile
end

local ManageTilePlacementFunction = eventsFolder.GUI:FindFirstChild("ManageTilePlacement")
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

function ManageTileTruePosition(Menu, Page, affectingTile, TruePosition, maxTileAmount, Change, Type)
	--TruePosition is used to move all other tiles around
	--PageSlotCount is used to position the tile on that page properly
	--Change is how higher TruePosition tiles should move (up 1 or down 1)
	
	local pageNumber = string.gsub(Page.Name, "Page", "")
	
	for i,page in pairs (Menu:GetChildren()) do
		if page:IsA("Frame") and string.find(page.Name, "Page") then
			local currentPageNumber = string.gsub(page.Name, "Page", "")
			
			--Grab only pages containing tiles that will be affected by this new tile (affectingTile)
			if tonumber(currentPageNumber) >= tonumber(pageNumber) then
				for i,tile in pairs (page:GetChildren()) do
					if (tile:IsA("ImageButton") or tile:IsA("TextButton")) and string.find(tile.Name, "Slot") then
						if tile.TruePosition.Value >= TruePosition then --Every tile "above" affecting tile
							local PageSlotCount = 0
							local Page
							
							if tile ~= affectingTile then
								tile.TruePosition.Value += Change
								PageSlotCount = GetTileSlotCount(page, tile.TruePosition.Value, affectingTile, Change)
								
								if PageSlotCount >= maxTileAmount then
									--Affected tile will be moved to next page
									if Menu:FindFirstChild("Page" .. tostring(tonumber(currentPageNumber) + 1)) then
										Page = Menu:FindFirstChild("Page" .. tostring(tonumber(currentPageNumber) + 1))
									else --No next page, making new one
										Page = CreateNewMenuPage(Type, Menu, Page, tonumber(currentPageNumber) + 1)
									end
									PageSlotCount = 0
								elseif PageSlotCount < 0 then
									--Affected tile will be moved to previous page
									Page = Menu:FindFirstChild("Page" .. tostring(tonumber(currentPageNumber) - 1))
								else
									--Affected tile will stay on this page
									Page = page
								end
								tile.Name = "Slot" .. tostring(PageSlotCount + 1)
							else
								if Change == -1 then
									tile:Destroy()
								else
									--Will guaranteed be on this page since it was calculated earlier
									PageSlotCount = GetTileSlotCount(page, tile.TruePosition.Value, affectingTile, Change)
									Page = page
								end
							end
							
							if Page then --Reposition affected tile
								tile.Parent = Page
								
								local truePositionValue = GetTileTruePosition(Page, PageSlotCount, maxTileAmount)
								tile.TruePosition.Value = truePositionValue
								
								if Type == "Experience" or Type == "Research" then --straight down insertion
									if Type == "Experience" then
										tile.Position = UDim2.new(0.023,0,0.023+((PageSlotCount)*0.215),0)
										tile.Size = UDim2.new(0.952, 0, 0.2, 0)
									else
										tile.Position = UDim2.new(0.05, 0, 0.054+0.173*PageSlotCount, 0)
										tile.Size = UDim2.new(0.9, 0, 0.14, 0)
									end
								else --non-list insertion (Inventory & Equipment)
									local tilesPerRow = 4
									local columnValue, rowValue = SlotCountToXY(PageSlotCount, tilesPerRow)
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

local DepositInventory = eventsFolder.Utility:WaitForChild("DepositInventory")
DepositInventory.OnClientEvent:Connect(function()
	for i,menu in pairs (DataMenu.InventoryMenu:GetChildren()) do
		if menu:IsA("Frame") then
			for i,page in pairs (menu:GetChildren()) do
				page:Destroy()
			end
		end
	end
end)


--------------<|Tile Functions|>--------------------------------------------------------------------------------------------------------------------

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

local function InsertItemViewerInfo(tile, statMenu, Type, statName, StatInfo, value, itemType)
	
	--**Value is useless in every instance except for stat bar appearance (inventory and experience amounts don't
	--update, they only update to the value they were first created with for the tile.Activated)
	
	if Type == "Inventory" then
		local rarityName = StatInfo["GUI Info"].RarityName.Value
		local rarity = GuiElements.RarityColors:FindFirstChild(rarityName)
		statMenu.ItemImage.BackgroundColor3 = rarity.TileColor.Value
		statMenu.ItemImageBorder.BackgroundColor3 = rarity.Value
		
		statMenu.ItemAmount.Text = tile.Amount.Text
		statMenu.ItemWorth.Text = tostring(StatInfo.CurrencyValue.Value)

		GuiUtility.Display3DModels(Player, statMenu.ItemImage, StatInfo:Clone(), true, StatInfo["GUI Info"].DisplayAngle.Value)
		
	elseif Type == "Experience" then
		statMenu.ItemRarity.Text = ""
		statMenu.ItemAmount.Text = "Total EXP: " .. tostring(value)
		statMenu.ItemImage.Image = StatInfo["GUI Info"].StatImage.Value
		
		statMenu.ItemWorth.Visible = true
		
	else --Equipment
		statMenu.EquipType.Value = Type
		statMenu.ItemType.Value = itemType
		
		local rarityName = StatInfo["GUI Info"].RarityName.Value
		local rarity = GuiElements.RarityColors:FindFirstChild(rarityName)
		statMenu.ItemImage.BackgroundColor3 = rarity.TileColor.Value
		statMenu.ItemImageBorder.BackgroundColor3 = rarity.Value
		
		ManageStatBars(value)
		ManageEquipButton(DataMenu.PlayerMenu:FindFirstChild(itemType).CurrentlyEquipped.Value, statName)
			
		--local ItemModel = game.ReplicatedStorage.Equippable:FindFirstChild(Type):FindFirstChild(AcquiredLocation):FindFirstChild(Stat)
		
		if StatInfo:FindFirstChild("Handle") then
			GuiUtility.Display3DModels(Player, statMenu.ItemImage, StatInfo.Handle:Clone(), true, StatInfo["GUI Info"].DisplayAngle.Value)
		else
			GuiUtility.Display3DModels(Player, statMenu.ItemImage, GuiElements:FindFirstChild("3DObjectPlaceholder"):Clone(), true, StatInfo["GUI Info"].DisplayAngle.Value)
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

local previousTile
local function InsertTileInfo(Type, tile, statName, Value, itemType, tileAlreadyPresent)
	tile.StatName.Value = statName

	local statInfo
	local statMenu
	if Type == "Inventory" then
		statMenu = inventoryQuickViewMenu
		statInfo = game.ReplicatedStorage.InventoryItems:FindFirstChild(itemType):FindFirstChild(statName)
		tile.Picture.Image = GetStatImage(statInfo)
		tile.Amount.Text = tostring(Value)
		
		if statName == statMenu.ItemName.Text then --Menu is currently open
			statMenu.ItemAmount.Text = tostring(Value)
		end
		
		--Do Rarity Imaging
		local rarityInfo = tile.Rarity.Value
		tile.Image = rarityInfo.TileImages.StaticRarityTile.Value
		tile.HoverImage = rarityInfo.TileImages.HoverRarityTile.Value
		tile.PressedImage = rarityInfo.TileImages.PressedRarityTile.Value
		
	elseif Type == "Experience" then
		statMenu = DataMenu.ExperienceMenu.ExpInfoViewer
		
		local statInfo
		local expTypeFolder = game.ReplicatedStorage.Experience:FindFirstChild(itemType)
		for _,expStat in pairs (expTypeFolder:GetChildren()) do
			if string.match(tostring(expStat), statName) then
				statInfo = expStat
			end
		end
		tile.DisplayName.Text = statName
		
		local expMenuButton = DataMenu.ExperienceMenu:FindFirstChild(itemType .. "MenuButton")
		if expMenuButton then
			tile.Image = expMenuButton.TileStaticImage.Value
			tile.HoverImage = expMenuButton.TileHoverImage.Value
			expMenuButton.Color.UIGradient:Clone().Parent = tile.ProgressBar.Progress
		end
		
		local CurrentLevel = 0
		--Move into Levels value where the value is how many levels, no for in pairs, just 1,amount,1 loop
		for i,level in pairs (statInfo.Levels:GetChildren()) do
			if Value >= level.Value and tonumber(level.Name) > CurrentLevel then
				CurrentLevel = tonumber(level.Name)
			end
		end

		local NextLevel
		if statInfo.Levels:FindFirstChild(tostring(CurrentLevel + 1)) then
			NextLevel = statInfo.Levels:FindFirstChild(tostring(CurrentLevel + 1))
			tile.NextLevel.Text = tostring(NextLevel)
		else
			NextLevel = statInfo.Levels:FindFirstChild(tostring(CurrentLevel))
			tile.NextLevel.Text = "*"
		end
		
		local CurrentLevelEXP = statInfo.Levels:FindFirstChild(tostring(CurrentLevel))
		local ProgressBar = tile.ProgressBar
		ProgressBar.Current.Text = tostring(Value - CurrentLevelEXP.Value)
		ProgressBar.Total.Text = tostring(NextLevel.Value - CurrentLevelEXP.Value)
		tile.CurrentLevel.Text = tostring(CurrentLevel)
		
		local Percentage = tonumber(Value - CurrentLevelEXP.Value) / tonumber(NextLevel.Value - CurrentLevelEXP.Value)
		ProgressBar.Progress.Size = UDim2.new(Percentage, 0, 1, 0)
		
	else
		statMenu = equipmentQuickViewMenu
		local RSTypeFile = game.ReplicatedStorage.Equippable:FindFirstChild(Type)
		statInfo = RSTypeFile:FindFirstChild(itemType):FindFirstChild(statName)
		
		tile.Picture.Image = GetStatImage(statInfo)
		tile.Amount.Visible = false
		local rarityInfo = tile.Rarity.Value
		tile.Image = rarityInfo.TileImages.StaticRarityTile.Value
		tile.HoverImage = rarityInfo.TileImages.HoverRarityTile.Value
		tile.PressedImage = rarityInfo.TileImages.PressedRarityTile.Value
	end
	
	--ItemViewerMenu GUI Management
	if tileAlreadyPresent == nil then
		tile.Activated:Connect(function()
			if Type == "Experience" then
				InsertItemViewerInfo(tile, statMenu, Type, statName, statInfo, Value, itemType)
			else
				InsertItemViewerInfo(tile, statMenu, Type, statName, statInfo, Value, itemType)
				local rarityInfo = tile.Rarity.Value
				local newTileImage = rarityInfo.TileImages.SelectedRarityTile.Value
				
				--Both Equipment and Inventory use a QuickViewMenu (deselect previous tile)
				if previousTile then
					local prevRarityInfo = previousTile.Rarity.Value
					previousTile.Image = prevRarityInfo.TileImages.StaticRarityTile.Value
				end
					
				previousTile = tile
				statMenu.Visible = true
				tile.Image = newTileImage
			end	
		end)
	end
end

function ManageTiles(statName, Menu, value, Type, itemType)
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
		rarityInfo = GuiElements.RarityColors:FindFirstChild(rarityName)
	end
	
	local tileAlreadyPresent
	for _,page in pairs (Menu:GetChildren()) do
		if page:IsA("Frame") and string.find(page.Name, "Page") then
			
			for _,slot in pairs (page:GetChildren()) do
				if (slot:IsA("ImageButton") or slot:IsA("TextButton")) and string.find(slot.Name, "Slot") then
					local slotItemName = slot.StatName.Value
					
					if slotItemName == statName then
						tileAlreadyPresent = slot
					end
				end
			end
		end
	end
	
	if tileAlreadyPresent then
		InsertTileInfo(Type, tileAlreadyPresent, statName, value, itemType, tileAlreadyPresent)
	else
		local newTile = ManageTilePlacement(Menu, Type, rarityInfo)
		newTile.Active = true
		newTile.Selectable = true
		InsertTileInfo(Type, newTile, statName, value, itemType)
	end

end

local SearchBars = {
	PageManager.FullBottomDisplay.SearchBar,
	PageManager.PartialBottomDisplay.SearchBar
}
for i,searchBar in pairs (SearchBars) do
	GuiUtility.ManageSearchVisual(searchBar.SearchInput)
end


--------------------<|Material PopUp Functions|>-------------------------------------------------------------------------------------------------------------------
local itemPopUpGui = script.Parent.Parent.PopUps:FindFirstChild("ItemPopUp")

local moveUpAmount = 0.105
local itemPopUpCount
local function InsertNewMaterialPopUp(itemType, statName, amountAdded)
	
	--Move other popups upward
	for _,popUp in pairs (itemPopUpGui:GetChildren()) do
		popUp:TweenPosition(UDim2.new(popUp.Position.X.Scale, 0, popUp.Position.Y.Scale - moveUpAmount, 0), "Out", "Quint", .8)
	end
	
	local itemInfo = game.ReplicatedStorage.InventoryItems:FindFirstChild(itemType):FindFirstChild(statName)
	
	local newItemPopUp = GuiElements.PopUpSlot:Clone()
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
	local rarityInfo = GuiElements.RarityColors:FindFirstChild(rarityName)
	newItemPopUp.BackgroundColor3 = rarityInfo.TileColor.Value
	newItemPopUp.BorderColor3 = rarityInfo.Value
	newItemPopUp.CircleBorder.BackgroundColor3 = rarityInfo.Value
	newItemPopUp["Round Edge"].BackgroundColor3 = rarityInfo.Value
	newItemPopUp["Round Edge"].Inner.BackgroundColor3 = rarityInfo.TileColor.Value
	
	newItemPopUp.ZIndex = 50
	
	newItemPopUp:TweenPosition(UDim2.new(0.835, 0,0.8, 0), "Out" , "Quint", .45)
	CountdownPopUp(itemPopUpGui, newItemPopUp, 5, .2, 0)
end

local prevItem
local prevAmount
local currentPopUpStat
local function ManageMaterialPopups(statName, itemType, amountAdded)
	
	if amountAdded ~= nil then
		if amountAdded ~= 0 then
			
			if amountAdded < 0 then
				currentPopUpStat = "Negative" .. statName
			else
				currentPopUpStat = statName
			end
			
			if prevItem ~= currentPopUpStat then
				InsertNewMaterialPopUp(itemType, statName, amountAdded)
				prevItem = statName
				prevAmount = amountAdded
				
			elseif prevItem == currentPopUpStat and #itemPopUpGui:GetChildren() == 0 then
				InsertNewMaterialPopUp(itemType, statName, amountAdded) --Was PopUp of stat, but expired
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
		end
	end
end


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
local expBarGui = GuiElements:FindFirstChild("ExperienceBar")
local expPopUpGui = script.Parent.Parent.PopUps:FindFirstChild("EXPBarPopUp")

function NewDiffPopUp(expBar, difference, pace)
	local realDiffPopUp = GuiElements:FindFirstChild("EXPPopUp")
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
	
	local currentLevelMax = skillInfo.Levels:FindFirstChild(tostring(currentLevel))
	local progressBar = experienceBar.ProgressBar
	
	if progressBar:FindFirstChild("EXPDifference") then --Difference Bar Check
		local difference = progressBar.EXPDifference
		local levelProgress = tonumber(expAmount - currentLevelMax.Value) / tonumber(nextLevel.Value - currentLevelMax.Value)
		
		if levelProgress < lastProgressAmount then
			difference:TweenSize(UDim2.new(0, 276, 0, 30), "Out", "Quint", .2)
			wait(.2)
			progressBar.Progress:TweenSize(UDim2.new(0, 276, 0, 30), "Out", "Quint", .2)
			wait(.2)
			CountdownDifference(difference, progressBar.Progress, levelProgress, amountAdded, true)
			
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
		
		local levelProgress = tonumber(expAmount - currentLevelMax.Value) / tonumber(nextLevel.Value - currentLevelMax.Value)
		difference:TweenSize(UDim2.new(0, 276*levelProgress, 0, 30), "Out", "Quint", .2)
		
		CountdownDifference(difference, progressBar.Progress, levelProgress, levelProgress, amountAdded)
	end
end

local function InsertNewEXPBar(statName, expAmount, currentLevel, nextLevel, popUpAlreadyExists)
	
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
	
	local skillInfo = game.ReplicatedStorage.Experience.Skills:FindFirstChild(tostring(statName) .. "Skill")
	local progressBar = expPopUpGui.ExperienceBar.ProgressBar
	local CurrentLevelEXP = skillInfo.Levels:FindFirstChild(tostring(currentLevel))
	local levelProgress = tonumber(expAmount - CurrentLevelEXP.Value) / tonumber(nextLevel.Value - CurrentLevelEXP.Value)
	progressBar.Progress.Size = UDim2.new(0, 276*levelProgress, 0, 30)
	CountdownPopUp(expPopUpGui, newExpBar, 12, .45, 0, 0, .9) --Start Countdown
	
	local namePlate = newExpBar.NamePlate
	namePlate.DisplayName.Text = tostring(statName)
	
	wait(.5)
	namePlate:TweenPosition(UDim2.new(-12, 0, -0.9, 0), "Out", "Quint", .3)
end

local function ManageEXPPopUp(statName, expAmount, amountAdded)
	local skillInfo = game.ReplicatedStorage.Experience.Skills:FindFirstChild(statName .. "Skill")
	local currentLevel,nextLevel = FindStatLevel(skillInfo, expAmount)
	
	if amountAdded ~= nil then
		if #expPopUpGui:GetChildren() ~= 0 then
			if expPopUpGui.ExperienceBar.NamePlate.DisplayName.Text == statName then --Old Exp Bar
				ShowEXPChange(currentLevel, nextLevel, skillInfo, expAmount, amountAdded)
				CountdownPopUp(expPopUpGui, expPopUpGui.ExperienceBar, 12, .5, 0, 0, .9)
				
			else
				InsertNewEXPBar(statName, expAmount, currentLevel, nextLevel, true)
			end
			
		else
			InsertNewEXPBar(statName, expAmount, currentLevel, nextLevel)
			ShowEXPChange(currentLevel, nextLevel, skillInfo, expAmount, amountAdded)
		end
	end
	
end

-------------------------<|Bag Information GUI Functions|>----------------------------------------------------------------------------------------------------------
local BagPopUp = GuiElements:FindFirstChild("BagPopUp")
local BagPopUpGui = script.Parent.Parent:WaitForChild("PopUps"):WaitForChild("CurrentBagPopUp")

local function InsertNewBagPopUp(BagPopUp, BagPopUpGui, ItemTypeCount, BagCapacity, BagType, PopUpAlreadyExists)
	if PopUpAlreadyExists then
		local OldBagPopUp = BagPopUpGui:FindFirstChild("BagPopUp")
		local NamePlate = OldBagPopUp.NamePlate
		NamePlate:TweenPosition(UDim2.new(0.076,0,0,0), "Out", "Quint", .15)
		wait(.15)
		OldBagPopUp:TweenPosition(UDim2.new(0.159,0,1,0), "Out", "Quint", .2)
		wait(.2)
		OldBagPopUp:Destroy()
	end
	
	local NewBagPopUp = BagPopUp:Clone()
	NewBagPopUp.Parent = BagPopUpGui
	NewBagPopUp.Amounts.Text = tostring(ItemTypeCount) .. "/" .. tostring(BagCapacity)
	
	NewBagPopUp:TweenPosition(UDim2.new(0.159,0,0.918,0), "Out", "Quint", .5)
	wait(.5)
	local NamePlate = NewBagPopUp:FindFirstChild("NamePlate")
	NamePlate.Text = BagType
	NamePlate:TweenPosition(UDim2.new(0.076,0,-0.344,0), "Out", "Quint", .3)
	wait(.3)
	
	if BagCapacity == 0 or ItemTypeCount == BagCapacity then
		NewBagPopUp.Amounts.TextColor3 = Color3.fromRGB(203, 12, 15)
	else
		NewBagPopUp.Amounts.TextColor3 = Color3.fromRGB(0, 0, 0)
	end
	
	CountdownPopUp(BagPopUpGui, NewBagPopUp, 11, 0, 0.082, 0, 0.344)
end


-------------------------------------<|PlayerMenu Functions|>------------------------------------------------------------------------------------------------------------

local PlayerMenu = DataMenu:FindFirstChild("PlayerMenu")
local PlayerInfo = PlayerMenu.PlayerInfo
local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size420x420
local PlayerProfilePicture = game.Players:GetUserThumbnailAsync(PlayerUserId, thumbType, thumbSize)
local UpdateEquippedItem = eventsFolder.GUI.UpdateEquippedItem

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
			local AssociatedInventoryMenu = DataMenu.InventoryMenu:FindFirstChild(string.gsub(ItemType, "Bag", "") .. "Menu")
			
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

--May have to use this in item viewer too, so keep as function (not only equipment)
local function HideRemainingStatDisplays()
	for i,statDisplay in pairs (equipmentQuickViewMenu.StatDisplays:GetChildren()) do
		if statDisplay:FindFirstChild("Utilized") then
			statDisplay.Visible = statDisplay.Utilized.Value
		end
	end
end

function ManageStatBars(ItemStats)
	for i,statDisplay in pairs (equipmentQuickViewMenu.StatDisplays:GetChildren()) do
		if statDisplay:FindFirstChild("Utilized") then
			statDisplay.Utilized.Value = false
		end
	end
	
	for stat = 1,#ItemStats["Stats"],1 do
		local StatName = ItemStats["Stats"][stat][1]
		local StatValue = ItemStats["Stats"][stat][2]
		
		if ItemStats["Images"][StatName .. "Image"] then --Displayed on a GUI
			if ItemStats["Images"][StatName .. "Image"][2] then --Associated ImageType
				local ImageId = ItemStats["Images"][StatName .. "Image"][1]
				local ImageType = ItemStats["Images"][StatName .. "Image"][2]
				
				local FoundStatDisplay = false
				for i,statDisplay in pairs (equipmentQuickViewMenu.StatDisplays:GetChildren()) do
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
									local MaxStatValue = GuiElements.MaxStatValues:FindFirstChild(StatName).Value
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
		
	HideRemainingStatDisplays()
end

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

		DefaultMenuButton.ItemImage.Image = ItemImage
	else
		DefaultMenuButton.ItemImage.Image = ""
	end
	
	--Highlight Equipped Item
	for i,page in pairs (PlayerMenu:FindFirstChild(ItemType .. "Menu"):GetChildren()) do
		for i,tile in pairs (page:GetChildren()) do
			if tile:IsA("TextButton") then
				if tile.StatName.Value == Item then
					tile.BackgroundColor3 = Color3.fromRGB(85, 170, 255) --Brighter blue (or player's fav color later)
				else
					tile.BackgroundColor3 = Color3.fromRGB(47, 95, 143) --Darker accent color
				end
			end
		end
	end
	
	if ItemType == "Bags" then
		--UpdateBagDisplays(DataMenu, DataMenu.PlayerMenu)
	end
end)


-------------------------------------<High-Traffic Events>-------------------------------------------------------------------------------------------------------------
local getItemStatTable = eventsFolder.Utility:WaitForChild("GetItemStatTable")

local UpdateInventory = eventsFolder.GUI:WaitForChild("UpdateInventory")
UpdateInventory.OnClientEvent:Connect(function(statName, folder, value, amountAdded, Type, itemType)
	local typeFrame = DataMenu:FindFirstChild(tostring(Type) .. "Menu")
	
	local Slots
	if folder then
		if typeFrame == DataMenu.ExperienceMenu then
			Slots = typeFrame:FindFirstChild(folder .. "Menu") or typeFrame:FindFirstChild(folder)
		else
			Slots = typeFrame.MaterialsMenu
		end
	else
		warn("No Folder associated with inventory update. Stat Name: " .. statName)
	end
	
	if Type == "Inventory" then
		ManageMaterialPopups(statName, itemType, amountAdded) 

	elseif Type == "Experience" then 
		if string.find(statName, "Skill") then
			statName = string.gsub(statName, "Skill", "") --Remove "Skill" from string
		end
		
		ManageEXPPopUp(statName, value, amountAdded)
	end
	
	if tonumber(value) ~= 0 then
		ManageTiles(statName, Slots, tonumber(value), Type, itemType)
	end
end)

local UpdatePlayerMenu = eventsFolder.GUI:WaitForChild("UpdatePlayerMenu")
UpdatePlayerMenu.OnClientEvent:Connect(function(EquipType, ItemType, Item)
	local itemInfo = game.ReplicatedStorage.Equippable:FindFirstChild(EquipType):FindFirstChild(ItemType):FindFirstChild(Item)
	local AssociatedMenu = PlayerMenu:FindFirstChild(ItemType .. "Menu")
	local AssociatedButton = PlayerMenu:FindFirstChild(ItemType)
	
	if EquipType == "Bags" then
		local itemStats = getItemStatTable:InvokeServer("Equipment", EquipType, ItemType, Item) 
		ManageTiles(Item, AssociatedMenu, itemStats, EquipType, ItemType)
	else
		local itemStats = getItemStatTable:InvokeServer("Equipment", EquipType, ItemType, Item)
		ManageTiles(Item, AssociatedMenu, itemStats, EquipType, ItemType)
	end
	
	--Update Default Menu (Equipped) Item Pictures
	--if Item == AssociatedButton.CurrentlyEquipped.Value then
		--AssociatedButton.Image = itemInfo["GUI Info"].StatImage.Value
	--end
end)

local UpdateItemCount = eventsFolder.GUI:WaitForChild("UpdateItemCount")
UpdateItemCount.OnClientEvent:Connect(function(ItemTypeCount, BagCapacity, BagType, DepositedInventory)
	if ItemTypeCount < 0 then
		ItemTypeCount = 0
	end
	
	if not DepositedInventory then
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
	
	if ItemTypeCount ~= BagCapacity or BagCapacity ~= 0 then
		local ItemType
		if string.find(BagType, "Bag") then
			ItemType = string.gsub(BagType, "Bags", "") .. "s"
		else
			ItemType = BagType
			BagType = string.gsub(ItemType, "s", "") .. "Bags"
		end
		
		--Update bag counts in inventory
		local InventoryMenu = DataMenu.InventoryMenu.MaterialsMenu
		InventoryMenu:SetAttribute("ItemCount", ItemTypeCount)
		InventoryMenu:SetAttribute("BagCapacity", BagCapacity)

		--Update bag counts in playermenu
		local BagButton = DataMenu.PlayerMenu:FindFirstChild(BagType)
		if BagButton and InventoryMenu then
			UpdateBagButtonBar(BagButton, InventoryMenu)
		end
	end
end)

game.Workspace.Players:WaitForChild(tostring(Player)).Archivable = true

wait(3)
script.Parent.OpenDataMenuButton.Active = true

