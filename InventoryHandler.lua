--(LocalScript)
--Inventory graphical menu handler
-------------------------------------------------------------------------------------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local Camera = game.Workspace.CurrentCamera

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
	if v:IsA("Frame") and tostring(v) ~= "TopTabBar" and tostring(v) ~= "MenuBorder" then
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
	
	local tweenInfo = TweenInfo.new(0.4,Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
OpenDataMenuButton.Activated:Connect(function()
	if DataMenu.Visible == false then
		DataMenu.Position = UDim2.new(0.159, 0, -.8, 0)
		DataMenu.Visible = true
		DataMenu.PlayerMenu.Visible = true
		DataMenu.TopTabBar.CloseMenu.Active = true
		OpenDataMenuButton.Active = false
		
		--CheckForNewItems()
		
		DataMenu.PlayerMenu.Visible = true
		DataMenu:TweenPosition(UDim2.new(0.159, 0, 0.173, 0), "Out", "Quint", .5)
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
		Display3DModels(false)
		Display3DModels(true)
		
		OpenDataMenuButton.Active = true
		
	elseif DataMenu.Visible == true then
		OpenDataMenuButton.Active = false
		DataMenu:TweenPosition(UDim2.new(0.159, 0, -0.8, 0), "Out", "Quint", .5)
		wait(.5)
		DataMenu.Visible = false
		DataMenu.Position = UDim2.new(0.159, 0, 0.141, 0)
		PageManager.Visible = false
		DataMenu.ItemViewer.Visible = false
		
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
	DataMenu.ItemViewer.Visible = false

	OpenDataMenuButton.Active = true
end)

MoveAllBaseScreenUI.Event:Connect(function(ChangeTo)
	DataMenu.Visible = false
	if ChangeTo == "Hide" then
		OpenDataMenuButton:TweenPosition(UDim2.new(-.15, 0, OpenDataMenuButton.Position.Y.Scale, 0), "Out", "Quint", 1)
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
					ButtonMenu.EmptyNotifier.Visible = false
					ButtonMenu.QuickViewMenu.Visible = false
					--UpdateBagDisplays(Menu, ButtonMenu)		
				end
				
				button.Activated:Connect(function()
					DataMenu.InventoryMenu.EmptyNotifier.Visible = false
					DataMenu.PlayerMenu.EmptyNotifier.Visible = false
					
					--Reset new item notifiers
					if button:FindFirstChild("NewItem") then
						button.NewItem.Value = false
					end
					
					for i,v in pairs (ButtonMenu.Parent:GetChildren()) do
						if v:IsA("Frame") and not v:FindFirstChild("Menu") then
							if tostring(v) ~= "TopTabBar" and tostring(v) ~= "MenuBorder" then
								v.Visible = false
							end
						end
					end
					ButtonMenu.Visible = true
					
					print(button,ButtonMenu,Menu)
					
					--Possibly make this ~= "PlayerMenu" since the PlayerMenu is the only menu that has a "main menu"
					--that doesn't auto select a menu to look at immediately like the inventory, exp, and journal
					if tostring(ButtonMenu) == "InventoryMenu" then
						local MaterialsMenu = ButtonMenu.MaterialsMenu
						local BagCapacity = MaterialsMenu:GetAttribute("BagCapacity")
						local ItemCount = MaterialsMenu:GetAttribute("ItemCount")
						ButtonMenu.SelectedBagInfo.Text = tostring(ItemCount) .. "/" .. tostring(BagCapacity)
						ButtonMenu.SelectedBagInfo.BagType.Text = string.gsub(tostring(ButtonMenu), "Menu", "")
						ButtonMenu.SelectedBagInfo.Visible = true
						
						PageManager.Menu.Value = MaterialsMenu
						local PageCount = CountPages()
						if PageCount > 0 then
							PageManager.Visible = true
							PageManager.FullBottomDisplay.Visible = true
							PageManager.PartialBottomDisplay.Visible = false
							if MaterialsMenu:FindFirstChild("Page1") then
								CommitPageChange(MaterialsMenu.Page1)
							end
						else
							ButtonMenu.EmptyNotifier.Visible = true
						end
					end
					
					if tostring(Menu) == "PlayerMenu" then
						Menu.QuickViewMenu.Visible = true
						Menu.QuickViewMenu.QuickViewMenu.Visible = false
						Menu.QuickViewMenu.QuickViewPreview.Visible = true
						PageManager.Menu.Value = ButtonMenu
						
						local PageCount = CountPages()
						if PageCount > 0 then
							PageManager.Visible = true
							PageManager.FullBottomDisplay.Visible = false
							PageManager.PartialBottomDisplay.Visible = true
							if ButtonMenu:FindFirstChild("Page1") then
								CommitPageChange(ButtonMenu.Page1)
							end
						else
							DataMenu.PlayerMenu.EmptyNotifier.Visible = true
						end
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

local function PressGUIButton(button, newPosition, newSize)
	if button.Visible == true then
		button:TweenPosition(newPosition, "Out", "Quint", 0.2)
		button:TweenSize(newSize, "Out", "Quint", 0,2)
	end
end

local PlayerViewport = DataMenu.PlayerMenu.PlayerInfo.PlayerView
function Display3DModels(bool)
	--possibly get rid of bool cause that used to associate with background transparency. Possibly load viewport on
	--first open and then never again? (leave viewport running in the background)
	

	--get rid of point light
	--get rid of shield effect
	if bool == true then
		local PlayerModel = game.Workspace.Players:WaitForChild(tostring(Player)):Clone()
		local HRP = PlayerModel.HumanoidRootPart
		local vpCamera = Instance.new("Camera",PlayerViewport)
		
		PlayerModel.Parent = PlayerViewport.Physics
		HRP.Anchored = true
		PlayerViewport.CurrentCamera = vpCamera
		
		--Move Camera Around Player & Auto FOV
		local currentAngle = 0
		local modelCenter, modelSize = PlayerModel:GetBoundingBox()	

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
		
		local idleAnimation = PlayerModel.Humanoid:LoadAnimation(PlayerModel.Animate.idle.Animation1)
		idleAnimation:Play()
		
		local minDist = (maxExtent/3.75)/tan + diagonal
		game:GetService("RunService").RenderStepped:Connect(function(dt)
			currentAngle = currentAngle + (1*dt*60)/3
			vpCamera.CFrame = modelCenter * CFrame.fromEulerAnglesYXZ(0, math.rad(currentAngle), 0) * CFrame.new(0, 0, minDist + 3)
		end)
	else
		PlayerViewport.CurrentCamera = nil
		for i,view in pairs (PlayerViewport.Physics:GetChildren()) do
			view:Destroy()
		end
	end
end

--Reset camera view in viewport
PlayerViewport.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1) then
		Display3DModels(false)
		Display3DModels(true)
	end
end)

function CleanupMenuTabs(Menu)
	
	--Prep Default Menu
	if Menu.Name == "DataMenu" or Menu.Name == "PlayerMenu" then
		DataMenu.PlayerMenu.EmptyNotifier.Visible = false
		
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

local TI = TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
local startingPos = Vector2.new(-1.2, 0) --Start on right
local waitPeriod = 2.5

--Replace this with small notifier in corner of tile rather than shine effect?+
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

function CommitPageChange(Page)
	PageDebounce = true
	local RarityName = Page.Rarity.Value
	if GuiElements.RarityColors:FindFirstChild(RarityName) then
		local Rarity = GuiElements.RarityColors:FindFirstChild(RarityName)
		--PageManager.PageRarityDisplay.Text = RarityName .. " " .. string.gsub(PageManager.Menu.Value.Name, "Menu", "")
		--PageManager.PageRarityDisplay.TextColor3 = Rarity.Value
		--PageManager.PageRarityDisplay.TextStrokeColor3 = Rarity.TileColor.Value
		for i,tile in pairs (Page:GetChildren()) do
			if tile:IsA("TextButton") or tile:IsA("ImageButton") then
				tile.Image = Rarity.ItemTileImage.Value
				--tile.BackgroundColor3 = Rarity.TileColor.Value
			end
		end
		local ButtonWidth = 0.33
		--if PageManager.PageRarityDisplay.Visible == false then
			--PageManager.Previous.Size = UDim2.new(ButtonWidth,0,1,0)
			--PageManager.Next.Position = UDim2.new(ButtonWidth + 0.005,0,0,0)
			--PageManager.Next.Size = UDim2.new(ButtonWidth,0,1,0)
			--PageManager.PageRarityDisplay.Visible = true
		--end
	else
		--For tiles without rarity distinguishability (no page names)
		local ButtonWidth = 0.502
		--if PageManager.PageRarityDisplay.Visible == true then
			--PageManager.Previous.Size = UDim2.new(ButtonWidth,0,1,0)
			--PageManager.Next.Position = UDim2.new(ButtonWidth + 0.005,0,0,0)
			--PageManager.Next.Size = UDim2.new(ButtonWidth,0,1,0)
			--PageManager.PageRarityDisplay.Visible = false
		--end
	end
	Page.ZIndex += 1
	Page.Visible = true
	Page:TweenPosition(UDim2.new(0,0,0,0), "Out", "Quint", .25)
	wait(.25)
	ManagePageInvis(Page)
end

local function StartPageChange(pageChange)
	if PageDebounce == false then
		local HighPage = CountPages()
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
			
			NewPage.Position = UDim2.new(pageChange,0,0,0)
			CommitPageChange(NewPage)
		else --Bounce Effect (no other pages)
			PageDebounce = true
			Menu:FindFirstChild("Page1"):TweenPosition(UDim2.new(.03*pageChange,0,0,0), "Out", "Quint", .1)
			wait(.1)
			Menu:FindFirstChild("Page1"):TweenPosition(UDim2.new(0,0,0,0), "Out" , "Bounce", .25)
			wait(.25)
			PageDebounce = false
		end
	end
end

for i,pageDisplay in pairs (PageManager:GetChildren()) do
	if pageDisplay:FindFirstChild("Next") then
		pageDisplay.Next.Activated:Connect(function()
			StartPageChange(1)
		end)
	end
	
	if pageDisplay:FindFirstChild("Previous") then
		pageDisplay.Previous.Activated:Connect(function()
			StartPageChange(-1)
		end)
	end
end

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
		if page:IsA("Frame") then
			if page.Rarity.Value == StatRarity then
				--print("Found existing page for " .. tostring(StatRarity))

				for i,slot in pairs (page:GetChildren()) do
					if slot:IsA("TextButton") or slot:IsA("ImageButton") then
						SlotCount += 1
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
	end
	
	if found == false then
		--print("Making new page since " .. tostring(Stat) .. " has rarity " .. tostring(StatRarity))
		
		local NewPage = GuiElements.MenuPage:Clone()
		NewPage.Rarity.Value = StatRarity
		if Over then --Group Page With Rarity
			local LastRarityPage = string.gsub(Over.Name, "Page" , "")
			NewPage.Name = "Page" .. tostring(tonumber(LastRarityPage) + 1)
			
		elseif not Over and StatRarity ~= "No Rarity" then --No Page of Rarity Exists, Must Sort Rarities by Order
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


--------------<|Tile Functions|>--------------------------------------------------------------------------------------------------------------------

local ItemViewerMenu = DataMenu.ItemViewer
local QuickViewMenu = DataMenu.PlayerMenu.QuickViewMenu.QuickViewMenu
local function ManageEquipButton(CurrentlyEquipped, Stat, Equip)
	local EquipButton = QuickViewMenu.EquipButton
	
	if Equip == true or (Stat and CurrentlyEquipped == tostring(Stat)) then
		--"Unequip"
		EquipButton.Image = "rbxassetid://6892832163"
		EquipButton.HoverImage = "rbxassetid://6893534695"
		EquipButton.PressedImage = "rbxassetid://6893271094"
		EquipButton.EquipStatus.Value = true
	else
		--"Equip"
		EquipButton.Image = "rbxassetid://6892801036"
		EquipButton.HoverImage = "rbxassetid://6893271094"
		EquipButton.PressedImage = "rbxassetid://6893294832"
		EquipButton.EquipStatus.Value = false
	end
	
	EquipButton.Visible = true
end

--May have to use this in item viewer too, so keep as function
local function HideRemainingStatDisplays(tile)
	for i,statDisplay in pairs (tile:GetChildren()) do
		if statDisplay:FindFirstChild("Utilized") then
			statDisplay.Visible = statDisplay.Utilized.Value
		end
	end
end

local function InsertItemViewerInfo(StatMenu, Type, Stat, StatInfo, Value, AcquiredLocation)

	if Type == "Inventory" then
		local RarityName = StatInfo["GUI Info"].RarityName.Value
		local Rarity = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(RarityName)
		
		StatMenu.ItemImage.BorderColor3 = Rarity.Value
		StatMenu.ItemImage.BackgroundColor3 = Rarity.TileColor.Value
		StatMenu.ItemRarity.Text = RarityName
		StatMenu.ItemRarity.TextColor3 = Rarity.Value
		StatMenu.ItemRarity.TextStrokeColor3 = Rarity.TileColor.Value

		StatMenu.ItemAmount.Text = "You Have: " .. tostring(Value)
		StatMenu.ItemWorth.Text = "Worth: " .. "$" .. tostring(StatInfo.CurrencyValue.Value)
		StatMenu.ItemDescription.Text = StatInfo["GUI Info"].Description.Value
		
		StatMenu.ItemWorth.Visible = true
		StatMenu.EquipButton.Visible = false

	--elseif Type == "Bags" then
		--ItemViewerMenu.ItemDescription.Text = StatInfo["GUI Info"].Description.Value
		--ItemViewerMenu.ItemAmount.Text = AcquiredLocation
		--ItemViewerMenu.ItemRarity.Text = ""
		
		--ItemViewerMenu.EquipType.Value = Type
		--ItemViewerMenu.ItemType.Value = AcquiredLocation
		
		--ItemViewerMenu.ItemWorth.Visible = false
		--ItemViewerMenu.EquipButton.Visible = true
		--ManageEquipButton(DataMenu.PlayerMenu:FindFirstChild(AcquiredLocation).CurrentlyEquipped.Value, Stat)	
	elseif Type == "Experience" then
		StatMenu.ItemRarity.Text = ""
		StatMenu.ItemAmount.Text = "Total EXP: " .. tostring(Value)
		
		StatMenu.ItemWorth.Visible = true
		StatMenu.EquipButton.Visible = false
	else --Equipment
		--local ItemStats = Value
		--local ShownStatName = string.gsub(tostring(ItemStats["Stats"][1][1]), AcquiredLocation, "") .. ": "
		
		StatMenu.EquipType.Value = Type
		StatMenu.ItemType.Value = AcquiredLocation
		
		StatMenu.EquipButton.Visible = true
		--ManageStatBars
		ManageEquipButton(DataMenu.PlayerMenu:FindFirstChild(AcquiredLocation).CurrentlyEquipped.Value, Stat)
	end

	StatMenu.ItemImage.Image = StatInfo["GUI Info"].StatImage.Value
	StatMenu.ItemName.Text = tostring(Stat)

	StatMenu.Visible = true 
end

local function InsertTileInfo(Type, tile, Stat, Value, found, AcquiredLocation)
	tile.StatName.Value = tostring(Stat)

	local StatInfo
	local StatMenu
	if Type == "Inventory" then
		StatMenu = ItemViewerMenu
		StatInfo = game.ReplicatedStorage.ItemLocations:FindFirstChild(tostring(AcquiredLocation)):FindFirstChild(tostring(Stat))
		tile.Picture.Image = GetStatImage(StatInfo)
		tile.Amount.Text = tostring(Value)
			
		if tostring(Stat) == DataMenu.ItemViewer.ItemName.Text then
			DataMenu.ItemViewer.ItemAmount.Text = "You Have: " .. tostring(Value)
		end
		
		--**Make rarity tile imaging a function
		local RarityName = StatInfo["GUI Info"].RarityName.Value
		local Rarity = GuiElements.RarityColors:FindFirstChild(RarityName)
		tile.Image = Rarity.ItemTileImage.Value
		--tile.HoverImage = 
		--tile.PressedImage = 

		found = true
		
	elseif Type == "Experience" then
		StatMenu = ItemViewerMenu
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
		
	else --Non-Bag, Equippable PlayerItems (Stat Table Referencing)
		StatMenu = QuickViewMenu
		local RSTypeFile = game.ReplicatedStorage.Equippable:FindFirstChild(tostring(Type))
		StatInfo = RSTypeFile:FindFirstChild(tostring(AcquiredLocation)):FindFirstChild(tostring(Stat))
		
		tile.Picture.Image = GetStatImage(StatInfo)
		tile.Amount.Visible = false
		local RarityName = StatInfo["GUI Info"].RarityName.Value
		local Rarity = GuiElements.RarityColors:FindFirstChild(RarityName)
		tile.Image = Rarity.ItemTileImage.Value
		--tile.HoverImage = 
		--tile.PressedImage = 
		
		--tile.DisplayName.Text = tostring(Stat)
		--tile.Picture.Image = StatInfo["GUI Info"].StatImage.Value
		
		--[[
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
		]]
	end
	
	--ItemViewerMenu GUI Management
	tile.Activated:Connect(function()
		if ItemViewerOpen == false then
			ItemViewerOpen = true
			InsertItemViewerInfo(StatMenu, Type, Stat, StatInfo, Value, AcquiredLocation)
		end
	end)
	
	return found
end

local function ManageTileAdvancedInsertion(tile, slotNumber, previousTile, tilesPerRow)
	if (slotNumber-1)%tilesPerRow == 0 then
		tile.Row.Value = previousTile.Row.Value + 1
		tile.Column.Value = 0
	else
		tile.Row.Value = previousTile.Row.Value
		tile.Column.Value = previousTile.Column.Value + 1
	end

end

function ManageTiles(Stat, Menu, Value, Type, AcquiredLocation)
	--print(Stat,Menu,Value,Type,AcquiredLocation) = Stone,OresMenu,2,Inventory,Mineshaft
	local Rarity
	local Page
	local SlotCount
	local OriginalMaterialSlot

	--To get rid of types check here, assign number, bool, and slotname as function parameters
	if Type == "Inventory" then
		OriginalMaterialSlot = GuiElements.InventoryMaterialSlot
		Rarity,Page,SlotCount = FindStatPage(Stat, Menu, 18, true, AcquiredLocation)
	elseif Type == "Experience" then
		OriginalMaterialSlot = GuiElements.ExperienceSlot
		Rarity,Page,SlotCount = FindStatPage(Stat, Menu, 4, false, AcquiredLocation) --no rarity sort
	else
		OriginalMaterialSlot = GuiElements.InventoryMaterialSlot
		Rarity,Page,SlotCount = FindStatPage(Stat, Menu, 12, false, AcquiredLocation)
	end
	
	--**************************
	--This is where the start of the more advanced sorting will be
	--Now that the page is known, the script will have to look for the last tile of this new tile's rarity, ensure it
	--exists, then append this tile to it while moving all others down and possibly onto new pages, along with the
	--possibility of this tile being deleted and moving the rest of the tiles after this one up
	
	--(THEREFORE, look at how the research script was done a lot; however, it will be harder since this is incorporating
	--another dimension with multiple columns, multiple menu types, and multiple item types with possibly no rarity)
	--**************************
	
	if SlotCount > 0 then --If tile already present
		local found = false
		
		--Looking to update value of current tile
		for i,tile in pairs (Page:GetChildren()) do
			if tile:IsA("TextButton") or tile:IsA("ImageButton") then
				if tile.StatName.Value == tostring(Stat) and found == false then --Update Tile
					
					if Value ~= 0 or Value:IsA("LocalizationTable")then
						found = InsertTileInfo(Type, tile, Stat, Value, found, AcquiredLocation)
					else --Deleting existing tile because value = 0 or zeroed from storage transaction 
						found = true
						local SlotNumber = i
						
						for i,tile in pairs (Page:GetChildren()) do --Move other tiles to fill in gap
							if i > SlotNumber then
								if tile:IsA("TextButton") or tile:IsA("ImageButton") then
									tile.Name = tostring("Slot" .. tostring(i - 1))
									if Type == "Inventory" then
										tile.Row.Value = tile.Row.Value - 1
										tile.Column.Value = tile.Column.Value - 1
										tile.Position = UDim2.new(0.018+0.164*tile.Column.Value, 0, 0.028+0.29*tile.Row.Value)
									elseif Type == "Experience" then
										tile.Position = UDim2.new(0.028,0,0.037+((i-1)*0.24),0) --change to do with Column and Row then
									else
									
									end
								end
							end
						end
						
						--Do other page checks here once rarity sorting is fixed to not sort pages by rarity 
						--(Do like how research tiles are handled)
						
						
						if SlotCount == 1 then --if tile is last on page
							Page:Destroy()
						end
						tile:Destroy()
					end
				end
			end
		end
		
		--Make new tile
		if found == false and (typeof(Value) == "table" or Value > 0) then
			local tile = OriginalMaterialSlot:Clone()
			local PreviousTile = Page:FindFirstChild("Slot" .. tostring(SlotCount))
			local SlotNumber = SlotCount + 1
			tile.Name = "Slot" .. tostring(SlotNumber)
			
			if Type == "Inventory" then
				ManageTileAdvancedInsertion(tile, SlotNumber, PreviousTile, 6)
				tile.Rarity.Value = Rarity
				tile.Position = UDim2.new(0.018+0.164*tile.Column.Value, 0, 0.028+0.29*tile.Row.Value, 0)
				tile.Size = UDim2.new(0.142, 0, 0.259, 0)
			elseif Type == "Experience" then
				tile.Position = UDim2.new(0.028,0,0.037+((SlotCount)*0.24),0)
			else
				ManageTileAdvancedInsertion(tile, SlotNumber, PreviousTile, 4)
				tile.Position = UDim2.new(0.043+.239*tile.Column.Value, 0, 0.028+0.29*tile.Row.Value, 0)
				tile.Size = UDim2.new(0.208, 0, 0.258, 0)
			end
			
			tile.Parent = Page
			InsertTileInfo(Type, tile, Stat, Value, found, AcquiredLocation)
		end
	else --First tile to be made for menu
		if Value ~= 0 then			
			local FirstSlot = OriginalMaterialSlot:Clone()
			FirstSlot.Name = "Slot1"
			
			if Type == "Experience" then
				FirstSlot.Position = UDim2.new(0.028,0,0.037,0)
			else
				FirstSlot.Row.Value = 0
				FirstSlot.Column.Value = 0
				FirstSlot.Rarity.Value = Rarity
				
				if Type == "Inventory" then
					FirstSlot.Position = UDim2.new(0.018, 0, 0.028, 0)
					FirstSlot.Size = UDim2.new(0.142, 0, 0.259, 0)
				else
					FirstSlot.Position = UDim2.new(0.043, 0, 0.028, 0)
					FirstSlot.Size = UDim2.new(0.208, 0, 0.258, 0)
				end
			end
			
			FirstSlot.Parent = Page
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
		--possibly give money exclusive popup color or shape? (yellow)
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
	
	NewItemPopUp.ZIndex = 50
	
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
local UpdateEquippedItem = EventsFolder.GUI:WaitForChild("UpdateEquippedItem")

PlayerInfo.PlayerThumbnail.Image = PlayerProfilePicture
PlayerInfo.PlayerName.Text = tostring(Player)

local RealBags = game.ReplicatedStorage.Equippable.Bags

local EquipButton = QuickViewMenu.EquipButton
local equipButtonXP = EquipButton.Position.X.Scale
local equipButtonXS = EquipButton.Size.X.Scale
EquipButton.MouseButton1Down:Connect(function()
	PressGUIButton(EquipButton, UDim2.new(equipButtonXP, 0, 0.859, 0), UDim2.new(equipButtonXS, 0, .114, 0))
end)
EquipButton.MouseLeave:Connect(function()
	PressGUIButton(EquipButton, UDim2.new(equipButtonXP, 0, 0.851, 0), UDim2.new(equipButtonXS, 0, .121, 0))
end)
EquipButton.MouseButton1Up:Connect(function()
	PressGUIButton(EquipButton, UDim2.new(equipButtonXP, 0, 0.851, 0), UDim2.new(equipButtonXS, 0, .121, 0))
end)

EquipButton.Activated:Connect(function()
	PressGUIButton(EquipButton, UDim2.new(equipButtonXP, 0, 0.851, 0), UDim2.new(equipButtonXS, 0, .121, 0))
	
	if EquipButton.Visible == true then
		EquipButton.Active = false
		
		local ItemName = QuickViewMenu.ItemName.Text
		local ItemType = QuickViewMenu.ItemType.Value
		local EquipType = QuickViewMenu.EquipType.Value
		
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
		local InventoryMenu = DataMenu.InventoryMenu:FindFirstChild(ItemType .. "Menu")
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

wait(5)
script.Parent.OpenDataMenuButton.Active = true

