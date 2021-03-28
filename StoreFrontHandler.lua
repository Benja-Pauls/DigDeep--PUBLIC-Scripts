--(Local Script)
--Handles Shop Keeper NPC data to fill player's StoreFrontGui once they interact with an NPC
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local Player = game.Players.LocalPlayer
local PlayerUserId = Player.UserId
local EventsFolder = game.ReplicatedStorage.Events
local GuiElements = game.ReplicatedStorage.GuiElements

local StoreFrontGui = script.Parent
local StoreFrontMenu = StoreFrontGui.StoreFrontMenu
local ProductDisplay = StoreFrontMenu.ProductDisplay
local ItemStatView = StoreFrontMenu.ItemStatView

local UpdateStoreFront = EventsFolder.GUI:WaitForChild("UpdateStoreFront")
local MoveAllBaseScreenUI = EventsFolder.GUI:WaitForChild("MoveAllBaseScreenUI")
local GetShortMoneyValue = EventsFolder.Utility:WaitForChild("GetShortMoneyValue")

if StoreFrontGui.StoreFrontMenu.Visible == true then
	StoreFrontGui.StoreFrontMenu.Visible = false
end

local Character = game.Workspace.Players:WaitForChild(tostring(Player))
local DefaultWalkSpeed = Character.Humanoid.WalkSpeed
local DefaultJumpPower = Character.Humanoid.JumpPower

----------------------<|Utility|>-------------------------------------------------------------------------------------------------------------

local function DisplayStoreFrontGUI()
	StoreFrontMenu.Visible = true
	
	--Move GUIs off screen
	StoreFrontMenu.ItemStatView.Position = UDim2.new(0.362, 0, 1.35, 0)
	StoreFrontMenu["NPC Info"].Position = UDim2.new(0.381, 0, -0.1, 0)
	StoreFrontMenu.PlayerCashDisplay.Position = UDim2.new(-0.55, 0, 0.032, 0)
	StoreFrontMenu.ExitStoreButton.Position = UDim2.new(0.01, 0, 1.15, 0)
	StoreFrontMenu.NextPage.Position = UDim2.new(0.747, 0, 1.15, 0)
	StoreFrontMenu.PreviousPage.Position = UDim2.new(0.747, 0, -0.15, 0)
	StoreFrontMenu.PurchaseItemButton.Position = UDim2.new(0.109, 0, 1.15, 0)

	--Tween GUIs into view
	StoreFrontMenu.ItemStatView:TweenPosition(UDim2.new(0.362, 0, 0.667, 0), "Out", "Quint", .4)
	StoreFrontMenu["NPC Info"]:TweenPosition(UDim2.new(0.381, 0, 0.035, 0), "Out", "Quint", .4)
	wait(.2)
	StoreFrontMenu.PlayerCashDisplay:TweenPosition(UDim2.new(0.054, 0, 0.032, 0), "Out", "Quint", .4)
	StoreFrontMenu.PreviousPage:TweenPosition(UDim2.new(0.747, 0, 0.047, 0), "Out", "Quint", .4)
	wait(.3)
	StoreFrontMenu.ExitStoreButton:TweenPosition(UDim2.new(0.01, 0, 0.846, 0), "Out", "Quint", .4)
	StoreFrontMenu.PurchaseItemButton:TweenPosition(UDim2.new(0.109, 0, 0.846, 0), "Out", "Quint", .4)
	StoreFrontMenu.NextPage:TweenPosition(UDim2.new(0.747, 0, 0.909, 0), "Out", "Quint", .4)
	wait(.3)
end

local function CleanUpMenu() --Remove information; blank slate
	StoreFrontGui.Visible = false
end

StoreFrontGui.Open.Changed:Connect(function(value)
	local ProxObject = StoreFrontGui.InteractedObject.Value
	if value == true then
		ProxObject.ProxPromptAttach.DisplayButtonGUI.Enabled = false
	else
		ProxObject.ProxPromptAttach.DisplayButtonGUI.Enabled = true
	end
end)

------------------------<|Cutscene Manager|>---------------------------------------------------------------------------------------------------
local Camera = game.Workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

local function MoveCamera(StartPart, EndPart, Duration, EasingStyle, EasingDirection)
	Camera.CameraType = Enum.CameraType.Scriptable
	Camera.CFrame = StartPart.CFrame
	local Cutscene = TweenService:Create(Camera, TweenInfo.new(Duration, EasingStyle, EasingDirection), {CFrame = EndPart.CFrame})
	Cutscene:Play()
	wait(Duration)
end

local function MoveCameraToStore(NPC)
	--Invis Player
	
	Character.Humanoid.WalkSpeed = 0
	Character.Humanoid.JumpPower = 0
	
	local CutsceneFolder = NPC:FindFirstChild("CutsceneCameras")
	MoveCamera(Camera, CutsceneFolder.Camera1, 1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
end

local function MoveCameraBackToPlayer()
	--UnInvis Player
	
	
	Character.Humanoid.WalkSpeed = DefaultWalkSpeed
	Character.Humanoid.JumpPower = DefaultJumpPower
end


----------------------<|Page Handler Functions|>-----------------------------------------------------------------------------------------------

local function ManageProductPage(MaxTileAmount)
	local Pages = ProductDisplay:GetChildren()
	
	local Page
	local Over
	local SlotCount = 0
	for i,page in pairs (Pages) do	
		if i == #Pages then --Last page
			for i,slot in pairs (page:GetChildren()) do
				if slot:IsA("TextButton") then
					SlotCount = SlotCount + 1
				end
			end

			if SlotCount < MaxTileAmount then
				Page = page
			else
				Over = page
			end
		end
	end
	
	--Make new page
	if Page == nil then
		local NewPage = GuiElements.StoreFrontPage:Clone()
		if Over then
			local LastRarityPage = string.gsub(Over.Name, "Page" , "")
			NewPage.Name = "Page" .. tostring(tonumber(LastRarityPage) + 1)
			NewPage.Visible = false
		else
			NewPage.Name = "Page1"
			NewPage.Visible = true
		end
		NewPage.Parent = ProductDisplay
		Page = NewPage
	end
	
	return Page,SlotCount
end

-------------------------<|Tile Management Functions|>-----------------------------------------------------------------------------------------

local function InsertProductInfo(Tile, ItemData)
	local Item = ItemData[1]
	local Price = ItemData[2]
	local ShortenedPrice = GetShortMoneyValue:InvokeServer(Price)
	local ItemType = Item.Parent
	local EquipType = Item.Parent.Parent
	
	Tile.Picture.Image = Item["GUI Info"].StatImage.Value
	Tile.DisplayName.Text = tostring(Item)
	Tile.ItemType.Text = tostring(ItemType)
	Tile.ItemCost.Text = "$" .. tostring(ShortenedPrice)
	
	Tile.Activated:Connect(function()
		--Unhighlight other tile
		for i,tile in pairs (Tile.Parent:GetChildren()) do
			if tile.BorderColor3 == Color3.fromRGB(0, 170, 255) and tile.BorderSizePixel > 1 then
				tile.BorderColor3 = Color3.fromRGB(27, 42, 53)
				tile.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				tile.BorderSizePixel = 1
			end
		end
		
		Tile.BorderColor3 = Color3.fromRGB(0, 170, 255)
		Tile.BackgroundColor3 = Color3.fromRGB(232, 232, 232)
		Tile.BorderSizePixel = 4
		
		if EquipType.Name ~= "Bags" then
			local ItemStats = require(Item:FindFirstChild(tostring(Item) .. "Stats"))
			
			for stat = 1,#ItemStats["Stats"],1 do
				local Stat = ItemStats["Stats"][stat]
				if ItemStats["Images"][Stat[1] .. "Image"] then --Display Stat				
					local StatName = string.gsub(Stat[1], tostring(Item), "")
					local StatValue = Stat[2]
					local StatImage = ItemStats["Images"][Stat[1] .. "Image"][1]
					local ImageType = ItemStats["Images"][Stat[1] .. "Image"][2]

					ManageStatDisplay(Stat[1], StatValue, StatImage, ImageType)
				end
			end
		else
			ManageStatDisplay("Bag Capacity", Item.Value, Item["GUI Info"].StatImage.Value, "StatBar")
		end
		
		--Hide Remaining Stat Tiles and Reset All
		for i,statDisplay in pairs (ItemStatView:GetChildren()) do
			if statDisplay:FindFirstChild("Utilized") then
				statDisplay.Visible = statDisplay.Utilized.Value
				statDisplay.Utilized.Value = false
			end
		end
		
		local DisplayedItem
		if Item:FindFirstChild("Handle") then
			DisplayedItem = Item.Handle:Clone()
		else
			DisplayedItem = Item["GUI Info"].StatImage
		end
		
		if DisplayedItem:IsA("StringValue") then
			if Camera:FindFirstChild("ShownStoreItem") then
				Camera.ShownStoreItem:Destroy()
			end
			
			StoreFrontMenu.ItemViewOutline.Visible = true
			StoreFrontMenu.ItemViewOutline.Image = DisplayedItem.Value
		else
			StoreFrontMenu.ItemViewOutline.Visible = false
			
			if Camera:FindFirstChild("ShownStoreItem") then
				Camera.ShownStoreItem:Destroy()
			end
			
			DisplayedItem.Name = "ShownStoreItem"
			DisplayedItem.Parent = Camera
			DisplayedItem.CanCollide = true
			DisplayedItem.Anchored = true
			DisplayedItem.CFrame = Camera.CFrame
			
			
			DisplayedItem.CFrame = DisplayedItem.CFrame + DisplayedItem.CFrame.lookVector * 6
			local cFrame = DisplayedItem.CFrame
			DisplayedItem.CFrame = cFrame*CFrame.Angles(-math.pi/2,0,0)
			local ItmPos = DisplayedItem.Position
			DisplayedItem.Position = Vector3.new(ItmPos.X, ItmPos.Y + 0.6, ItmPos.Z)
			
			--Rotate part 
			coroutine.resume(coroutine.create(function()
				while DisplayedItem do
					wait()
					local ItmOrient = DisplayedItem.Orientation
					DisplayedItem.Orientation = Vector3.new(ItmOrient.X, ItmOrient.Y, ItmOrient.Z+2)
				end
			end))
			
		end
		
		
		
		
		--Grab Item model clone
		--Move model into position
		--Continuously rotate while model is selected item
	end)
end

local function InsertProductTile(ItemData)
	local NewProductTile = game.ReplicatedStorage.GuiElements:WaitForChild("StoreFrontSlot"):Clone()
	local Page,SlotCount = ManageProductPage(5)
	
	if SlotCount > 0 then --Page available to insert into
		local slotNumber = SlotCount + 1
		
		NewProductTile.Name = "Slot" .. tostring(slotNumber)
		NewProductTile.Position = UDim2.new(0.06, 0, 1.2, 0)
		NewProductTile.Parent = Page
		InsertProductInfo(NewProductTile, ItemData)
		NewProductTile:TweenPosition(UDim2.new(0.06, 0, 0.106+((SlotCount)*.162), 0), "Out", "Quint", .4)
		wait(.2)
	else --First tile in page
		NewProductTile.Name = "Slot1"
		NewProductTile.Position = UDim2.new(0.06, 0, 1.2, 0)
		NewProductTile.Parent = Page
		InsertProductInfo(NewProductTile, ItemData)
		NewProductTile:TweenPosition(UDim2.new(0.06, 0, 0.106, 0), "Out", "Quint", .4)
		wait(.2)
	end
	
	--Check if player already has item purchased, and change AlreadyPurchased boolvalue in NewProductTile
end

---------------------<|ItemStatView Functions|>------------------------------------------------------------------------------------------------

function ManageStatDisplay(StatName, StatValue, StatImage, ImageType)
	
	local FoundStatDisplay = false
	for i,statDisplay in pairs (ItemStatView:GetChildren()) do
		if FoundStatDisplay == false then
			if string.find(tostring(statDisplay), ImageType) and statDisplay:FindFirstChild("Utilized") then
				if statDisplay.Utilized.Value == false then
					statDisplay.Utilized.Value = true
					FoundStatDisplay = true

					statDisplay.Image = StatImage

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



---------------------<|Button-Press Functions|>------------------------------------------------------------------------------------------------

--Page Change Button: Move invisible page to position, visible new, move, invisible old, move old to neutral

StoreFrontMenu.ExitStoreButton.Activated:Connect(function()
	
	
	StoreFrontGui.Open.Value = false
end)

---------------------<|StoreFront Events|>----------------------------------------------------------------------------------------------------

UpdateStoreFront.OnClientEvent:Connect(function(NPC, npcData)
	if StoreFrontGui.Open.Value == false then
		StoreFrontGui.InteractedObject.Value = NPC
		StoreFrontGui.Open.Value = true
		
		--Put Player's backpack in table to give back when they leave menu (remove so toolbar doesn't interfere with GUI)
		
		--Continue to hide players that are nearby until the player exits the store front
		
		MoveCameraToStore(NPC)
		MoveAllBaseScreenUI:Fire("Hide")
		wait(.5)
		DisplayStoreFrontGUI(true)
		
		--Transition screen (Show all UIs with tweens)
		
		--Show all storefront basic information like NPC name, store name, etc.
		
		local Items = npcData["Items"]
		for item = 1,#Items,1 do
			InsertProductTile(Items[item])	
		end
			
		--Show items in frames
		--Page system? (horizontal long boxes like paint file, or tiles?)
		
		--This function will be used to show the storefront information for the NPC that was interacted with, using
		--the npc data (and therefore item data) to fill the tiles of the StoreFront GUI
		
		--Display Basic Info
		
		
		--Move Frames into view
		
		--Transition screen fade out (or final camera movements) once info is inserted
		
		--NPC will be used to physical change his face, produce sounds, and play animations while shopping
	end
end)

