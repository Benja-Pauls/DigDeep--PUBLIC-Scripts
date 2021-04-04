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
local StoreFrontPurchase = EventsFolder.Utility:WaitForChild("StoreFrontPurchase")

if StoreFrontGui.StoreFrontMenu.Visible == true then
	StoreFrontGui.StoreFrontMenu.Visible = false
end

local Character = game.Workspace.Players:WaitForChild(tostring(Player))
local DefaultWalkSpeed = Character.Humanoid.WalkSpeed
local DefaultJumpPower = Character.Humanoid.JumpPower

local TextAnimate = require(game.ReplicatedStorage:WaitForChild("TextAnimate"))
local SoundEffects = require(game.ReplicatedStorage:WaitForChild("SoundEffects"))

----------------------<|Utility|>--------------------------------------------------------------------------------------------------------------
local StarterGui = game:GetService("StarterGui")

local function DisplayStoreFrontGUI(bool) --Bathroom break. do comments
	StoreFrontMenu.Visible = bool
	StoreFrontMenu.CurrentPage.Value = 1
	
	if bool == true then --Display
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		
		for i,statDisplay in pairs (StoreFrontMenu.ItemStatView:GetChildren()) do
			if statDisplay:IsA("ImageLabel") then
				statDisplay.Visible = false
			end
		end
		
		StoreFrontMenu.PurchaseItemButton.Active = false
		StoreFrontMenu.PurchaseItemButton.Visible = false
		StoreFrontMenu["NPC Dialogue"].Visible = false
		StoreFrontMenu.NextMessage.Visible = false
		
		--Move GUIs off screen
		StoreFrontMenu.ItemStatView.Position = UDim2.new(0.362, 0, 1.35, 0)
		StoreFrontMenu["NPC Info"].Position = UDim2.new(0.381, 0, -0.1, 0)
		StoreFrontMenu.PlayerCashDisplay.Position = UDim2.new(-0.55, 0, 0.032, 0)
		StoreFrontMenu.ExitStoreButton.Position = UDim2.new(0.01, 0, 1.15, 0)
		StoreFrontMenu.NextPage.Position = UDim2.new(0.747, 0, 1.15, 0)
		StoreFrontMenu.PreviousPage.Position = UDim2.new(0.747, 0, -0.15, 0)
		StoreFrontMenu.PurchaseItemButton.Position = UDim2.new(0.109, 0, 1.15, 0)
		StoreFrontMenu.TalkButton.Position = UDim2.new(-0.15, 0, 0.677, 0)

		--Tween GUIs into view
		StoreFrontMenu.ItemStatView:TweenPosition(UDim2.new(0.362, 0, 0.667, 0), "Out", "Quint", .4)
		StoreFrontMenu["NPC Info"]:TweenPosition(UDim2.new(0.381, 0, 0.035, 0), "Out", "Quint", .4)
		wait(.2)
		StoreFrontMenu.PlayerCashDisplay:TweenPosition(UDim2.new(0.054, 0, 0.032, 0), "Out", "Quint", .4)
		StoreFrontMenu.ExitStoreButton:TweenPosition(UDim2.new(0.01, 0, 0.846, 0), "Out", "Quint", .4)
		StoreFrontMenu.TalkButton:TweenPosition(UDim2.new(0.01, 0, 0.677, 0), "Out", "Quint", .4)
		StoreFrontMenu.PurchaseItemButton:TweenPosition(UDim2.new(0.109, 0, 0.846, 0), "Out", "Quint", .4)
		wait(.2)
	else --Close StoreFrontMenu: Reset Menu
		StoreFrontGui.InteractedObject.Value = nil
		StoreFrontMenu.CurrentPage.Value = 0
		StoreFrontMenu.CurrentTile.Value = nil
		
		--Delete all pages in product display
		for i,page in pairs (ProductDisplay:GetChildren()) do
			page:Destroy()
		end
		
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end
end

local function Round(n)
	return math.floor(n + 0.5)
end

StoreFrontGui.Open.Changed:Connect(function(value)
	local ProxObject = StoreFrontGui.InteractedObject.Value
	if value == true then
		ProxObject.ProxPromptAttach.DisplayButtonGUI.Enabled = false
	else
		ProxObject.ProxPromptAttach.DisplayButtonGUI.Enabled = true
	end
end)

local function PlayerVisibility(Transparency)
	for i,characterPart in pairs (Character:GetChildren()) do
		if characterPart:IsA("MeshPart") or characterPart:IsA("Part") then
			if tostring(characterPart) ~= "HumanoidRootPart" then
				characterPart.Transparency = Transparency
			end
		elseif characterPart:IsA("Accessory") then
			characterPart.Handle.Transparency = Transparency
		end
	end
end

local function ManageNearbyPlayerVisibility()
	
end

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
	Character.Humanoid.WalkSpeed = 0
	Character.Humanoid.JumpPower = 0
	
	PlayerVisibility(1)
	
	local CutsceneFolder = NPC:FindFirstChild("CutsceneCameras")
	MoveCamera(Camera, CutsceneFolder.Camera1, 1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
end

local function MoveCameraBackToPlayer()
	PlayerVisibility(0)
	MoveAllBaseScreenUI:Fire()
	
	Character.Humanoid.WalkSpeed = DefaultWalkSpeed
	Character.Humanoid.JumpPower = DefaultJumpPower
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = game.Players.LocalPlayer.Character:WaitForChild("Humanoid")
end


----------------------<|PageManager Functions|>-----------------------------------------------------------------------------------------------

local PageDebounce = false

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
	
	VisiblePage.ZIndex -= 1
	PageDebounce = false
end

local function CountPages()
	local HighPage = 0
	for i,page in pairs (ProductDisplay:GetChildren()) do
		if page:IsA("Frame") then
			local PageNumber = string.gsub(page.Name, "Page", "")
			if tonumber(PageNumber) > HighPage then
				HighPage = tonumber(PageNumber)
			end
		end
	end
	return HighPage
end


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
			SlotCount = 0
		else
			NewPage.Name = "Page1"
			NewPage.Visible = true
		end
		NewPage.Parent = ProductDisplay
		Page = NewPage
	end
	
	return Page,SlotCount
end

local function FinalizePageChange(NewPage, OldPage, NewYValue)
	PageDebounce = true
	
	NewPage.Visible = true
	OldPage:TweenPosition(UDim2.new(0, 0, NewYValue, 0), "Out", "Quint", .4)
	NewPage:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quint", .4)
	wait(.4)
	
	ManagePageInvis(NewPage)
end

StoreFrontMenu.NextPage.Activated:Connect(function()
	local OldPage = ProductDisplay:FindFirstChild("Page" .. tostring(StoreFrontMenu.CurrentPage.Value))
	
	if PageDebounce == false then
		local HighPage = CountPages()
		
		if HighPage ~= 1 then
			local NewPage

			if StoreFrontMenu.CurrentPage.Value + 1 > HighPage then
				NewPage = ProductDisplay:FindFirstChild("Page1")
				StoreFrontMenu.CurrentPage.Value = 1
			else
				NewPage = ProductDisplay:FindFirstChild("Page" .. tostring(StoreFrontMenu.CurrentPage.Value+1))
				StoreFrontMenu.CurrentPage.Value = StoreFrontMenu.CurrentPage.Value+1
			end

			NewPage.Position = UDim2.new(0,0,1,0)
			FinalizePageChange(NewPage, OldPage, -1)
		else --Bounce effect
			PageDebounce = true
			ProductDisplay:FindFirstChild("Page1"):TweenPosition(UDim2.new(0,0,0.02,0), "Out", "Quint", .1)
			wait(.1)
			ProductDisplay:FindFirstChild("Page1"):TweenPosition(UDim2.new(0,0,0,0), "Out" , "Bounce", .25)
			wait(.25)
			PageDebounce = false
		end
	end
end)

StoreFrontMenu.PreviousPage.Activated:Connect(function()
	local OldPage = ProductDisplay:FindFirstChild("Page" .. tostring(StoreFrontMenu.CurrentPage.Value))
	
	if PageDebounce == false then
		local HighPage = CountPages()

		if HighPage ~= 1 then
			local NewPage
			
			if StoreFrontMenu.CurrentPage.Value + 1 > HighPage then
				NewPage = ProductDisplay:FindFirstChild("Page1")
				StoreFrontMenu.CurrentPage.Value = 1
			else
				NewPage = ProductDisplay:FindFirstChild("Page" .. tostring(StoreFrontMenu.CurrentPage.Value+1))
				StoreFrontMenu.CurrentPage.Value = StoreFrontMenu.CurrentPage.Value+1
			end

			NewPage.Position = UDim2.new(0,0,-1,0)
			FinalizePageChange(NewPage, OldPage, 1)
		else --Bounce effect
			PageDebounce = true
			ProductDisplay:FindFirstChild("Page1"):TweenPosition(UDim2.new(0,0,-0.02,0), "Out", "Quint", .1)
			wait(.1)
			ProductDisplay:FindFirstChild("Page1"):TweenPosition(UDim2.new(0,0,0,0), "Out" , "Bounce", .25)
			wait(.25)
			PageDebounce = false
		end
	end
end)

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
		StoreFrontMenu.PurchaseItemButton.Active = true
		StoreFrontMenu.PurchaseItemButton.Visible = true
		
		local PreviousTile = StoreFrontMenu.CurrentTile.Value
		if PreviousTile then
			PreviousTile.BorderColor3 = Color3.fromRGB(27, 42, 53)
			PreviousTile.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			PreviousTile.BorderSizePixel = 1
		end

		StoreFrontMenu.CurrentTile.Value = Tile
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

					ManageStatDisplay(Stat[1], StatValue, Item, ImageType)
				end
			end
		else
			ManageStatDisplay("Bag Capacity", Item.Value, Item, "StatBar")
		end
		
		Tile.EquipType.Value = tostring(EquipType)
		
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
			
			--Move model into position
			DisplayedItem.CFrame = Camera.CFrame
			DisplayedItem.CFrame = DisplayedItem.CFrame + DisplayedItem.CFrame.lookVector * 6.5 --Move in front of camera
			local cFrame = DisplayedItem.CFrame
			DisplayedItem.CFrame = cFrame*CFrame.Angles(-math.pi/2,0,0)
			local ItmPos = DisplayedItem.Position
			DisplayedItem.Position = Vector3.new(ItmPos.X, ItmPos.Y + 0.7, ItmPos.Z)
			
			--Continuously rotate while model is selected item
			coroutine.resume(coroutine.create(function()
				while DisplayedItem do
					wait()
					local ItmOrient = DisplayedItem.Orientation
					DisplayedItem.Orientation = Vector3.new(ItmOrient.X, ItmOrient.Y, ItmOrient.Z+2)
				end
			end))
		end
		
		if Tile.AlreadyPurchased.Value == true then
			StoreFrontMenu.PurchaseItemButton.BackgroundColor3 = Color3.fromRGB(143, 136, 128)
			StoreFrontMenu.PurchaseItemButton.BorderColor3 = Color3.fromRGB(88, 84, 79)
		else
			StoreFrontMenu.PurchaseItemButton.BackgroundColor3 = Color3.fromRGB(19, 188, 112)
			StoreFrontMenu.PurchaseItemButton.BorderColor3 = Color3.fromRGB(0, 126, 0)
		end
	end)
end

local function InsertProductTile(npcData, ItemData, ItemAlreadyPurchased)
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
		
		if (slotNumber == 5 or slotNumber == #npcData["Items"]) and Page.Name == "Page1" then
			StoreFrontMenu.NextPage:TweenPosition(UDim2.new(0.747, 0, 0.919, 0), "Out", "Quint", .4)
			StoreFrontMenu.PreviousPage:TweenPosition(UDim2.new(0.747, 0, 0.047, 0), "Out", "Quint", .4)
		end
	else --First tile in page
		NewProductTile.Name = "Slot1"
		NewProductTile.Position = UDim2.new(0.06, 0, 1.2, 0)
		NewProductTile.Parent = Page
		InsertProductInfo(NewProductTile, ItemData)
		NewProductTile:TweenPosition(UDim2.new(0.06, 0, 0.106, 0), "Out", "Quint", .4)
		wait(.2)
	end
	
	NewProductTile.AlreadyPurchased.Value = ItemAlreadyPurchased
	if NewProductTile.AlreadyPurchased.Value == true then
		NewProductTile.ItemCost.Text = "Purchased"
	end
end

---------------------<|ItemStatView Functions|>------------------------------------------------------------------------------------------------

function ManageStatDisplay(StatName, StatValue, Item, ImageType)
	local StatImage = Item["GUI Info"].StatImage.Value
	
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
						statDisplay.StatName.Text = string.gsub(StatName, tostring(Item.Parent), "")
						statDisplay.ProgressBar.Progress.Size = UDim2.new(StatValue/MaxStatValue, 0, 1, 0)
					end
				end
			end
		end
	end
end

---------------------<|NPC Dialogue Functions|>------------------------------------------------------------------------------------------------
local CharactersPerLine = 15
local NPCDialogue = StoreFrontMenu["NPC Dialogue"]
local NextMessage = StoreFrontMenu.NextMessage
local CurrentNPC

local function CountDownDialogue()
	NPCDialogue.TimeLeft.Value = 0

	for i = 1,10,1 do
		if NPCDialogue.TimeLeft.Value == i - 1 then
			NPCDialogue.TimeLeft.Value = i
			if i == 10 then --Close NPC Dialogue
				NPCDialogue:TweenPosition(UDim2.new(0.178, 0, 0.412, 0), "Out", "Quint", .5)
				NPCDialogue:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Quint", .5)
				wait(.5)

				NPCDialogue.Visible = false
				NPCDialogue.Text = ""
				NPCDialogue.Position = UDim2.new(0.14, 0, 0.412, 0)
				NPCDialogue.Size = UDim2.new(0.32/4, 0, 0.07)
				
				NextMessage.Visible = false
				NextMessage.Active = false
				NextMessage.Selectable = false
			end
		else
			break
		end
		wait(1)
	end
end

local function CheckToReplaceText(String, Find, Replace)
	if string.find(String, Find) then
		String = string.gsub(String, Find, Replace)
	end
	
	return String
end

local function ShowNPCDialogue(npcData, SetResponse, Index, MissingFunds)

	local Message = npcData["Dialogue"][SetResponse][Index]
	
	Message = CheckToReplaceText(Message, "PLAYER", tostring(Player))
	Message = CheckToReplaceText(Message, "MISSINGFUNDS", "$" .. tostring(MissingFunds))
	
	if StoreFrontMenu.CurrentTile.Value ~= nil then
		Message = CheckToReplaceText(Message, "ITEM", StoreFrontMenu.CurrentTile.Value.DisplayName.Text)
	end
	
	local CharacterCount = string.len(Message)
	local LineCount = Round(CharacterCount/CharactersPerLine)
	
	NPCDialogue.Visible = false
	NextMessage.Visible = false
	NPCDialogue.Text = ""
	NPCDialogue.UIPadding.PaddingBottom = UDim.new(0.05, 0)
	NPCDialogue.Position = UDim2.new(0.14, 0, 0.412, 0)
	NPCDialogue.Size = UDim2.new(0.32/4, 0, 0.07, 0)
	
	NPCDialogue.Visible = true
	NPCDialogue:TweenPosition(UDim2.new(0.018, 0, 0.412 - (0.07 * LineCount), 0), "Out", "Quint", .5)
	NPCDialogue:TweenSize(UDim2.new(0.32, 0, 0.07 * LineCount, 0), "Out", "Quint", .5)
	
	--Message = [[Welcome to my shop<br /><font size="46" color="rgb(255,50,25)">Test Man!</font>]]
	--NPCDialogue.Text = Message
	
	coroutine.resume(coroutine.create(function()
		TextAnimate.typeWrite(NPCDialogue, Message, 0.045)
	end))
	
	for i = 1,CharacterCount/math.sqrt(2),1 do
		SoundEffects:PlaySound(StoreFrontGui.InteractedObject.Value, npcData["Voice"]["Neutral"], 0.045*math.sqrt(2))
	end
	
	wait(.5)
	NextMessage.CurrentIndex.Value = Index
	if #npcData["Dialogue"][SetResponse] > 1 and NextMessage.CurrentIndex.Value ~= #npcData["Dialogue"][SetResponse] then
		if SetResponse ~= "Starters" and SetResponse ~= "Goodbyes" then
			NextMessage.ConversationName.Value = SetResponse
			NextMessage.CurrentIndex.Value = Index
			
			coroutine.resume(coroutine.create(function()
				for i = 1,25,1 do
					NPCDialogue.UIPadding.PaddingBottom = UDim.new(0.05 + (0.45/LineCount)/(26-i), 0)
					wait()
				end
			end))
			
			NextMessage.Position = UDim2.new(0.14, 0, 0.402, 0)
			NextMessage.Size = UDim2.new(0.32/4, 0, 0, 0)
			
			wait(.3)
			NextMessage.Visible = true
			NextMessage.Active = true 
			NextMessage.Selectable = true
			
			NPCDialogue:TweenPosition(UDim2.new(0.018, 0, 0.412 - (0.07 * LineCount) - 0.05, 0), "In", "Quint", .5)
			NPCDialogue:TweenSize(UDim2.new(0.32, 0, (0.07 * LineCount) + 0.05, 0), "In", "Quint", .5)
			NextMessage:TweenPosition(UDim2.new(0.14, 0, 0.412 - 0.05, 0), "In", "Quint", .5)
			NextMessage:TweenSize(UDim2.new(0.32/4, 0, 0.038, 0), "In", "Quint", .5)
			wait(.5)
		else
			coroutine.resume(coroutine.create(function()
				CountDownDialogue()
			end))
		end
	else
		coroutine.resume(coroutine.create(function()
			CountDownDialogue()
		end))
	end
end

---------------------<|Button-Press Functions|>------------------------------------------------------------------------------------------------

StoreFrontMenu.PurchaseItemButton.Activated:Connect(function()
	local CurrentTile = StoreFrontMenu.CurrentTile.Value
	local ItemName = CurrentTile.DisplayName.Text
	
	if CurrentTile.AlreadyPurchased.Value == false then
		local NPC = StoreFrontGui.InteractedObject.Value.Name
		local ItemType = CurrentTile.ItemType.Text
		local EquipType = CurrentTile.EquipType.Value
		
		StoreFrontPurchase:FireServer(NPC, ItemName, ItemType, EquipType)
		
		--Shiny effect for new item of type on PlayerItem tiles
		local PlayerMenu = StoreFrontGui.Parent.DataMenu.DataMenu.PlayerMenu
		if PlayerMenu:FindFirstChild(ItemType) then
			local MenuButton = PlayerMenu:FindFirstChild(ItemType)
			if MenuButton.NewItem.Value == false then
				MenuButton.NewItem.Value = true
			end
		end
	else
		ShowNPCDialogue(CurrentNPC, "Item Already Purchased", 1)
	end
end)

StoreFrontMenu.ExitStoreButton.Activated:Connect(function()
	ShowNPCDialogue(CurrentNPC, "Goodbyes", math.random(1,2))
	CurrentNPC = nil

	if Camera:FindFirstChild("ShownStoreItem") then
		Camera.ShownStoreItem:Destroy()
	end
	
	StoreFrontGui.Open.Value = false
	MoveCameraBackToPlayer()
	DisplayStoreFrontGUI(false)
end)

StoreFrontMenu.TalkButton.Activated:Connect(function()
	ShowNPCDialogue(CurrentNPC, "Dialogue1", 1)
end)

NextMessage.Activated:Connect(function()
	ShowNPCDialogue(CurrentNPC, NextMessage.ConversationName.Value, NextMessage.CurrentIndex.Value+1)
end)

---------------------<|StoreFront Events|>----------------------------------------------------------------------------------------------------

UpdateStoreFront.OnClientEvent:Connect(function(NPC, npcData, AlreadyPurchased)
	if StoreFrontGui.Open.Value == false then
		StoreFrontGui.InteractedObject.Value = NPC
		StoreFrontGui.Open.Value = true
		CurrentNPC = npcData
		
		MoveCameraToStore(NPC)
		MoveAllBaseScreenUI:Fire("Hide")
		wait(.5)
		
		coroutine.resume(coroutine.create(function()
			DisplayStoreFrontGUI(true)
		end))
		
		--Hide players that are nearby until the player exits the store front
		--Other player touches radius part turns invisible
		--Player reappears no longer touching radius part: left radpart or radpart was deleted
		
		local Items = npcData["Items"]
		for item = 1,#Items,1 do
			
			local ItemAlreadyPurchased = false
			for i = 1,#AlreadyPurchased,1 do
				local PurchasedItem = AlreadyPurchased[i]
				if PurchasedItem.Parent == Items[item][1].Parent then
					if AlreadyPurchased[i] == Items[item][1] then
						ItemAlreadyPurchased = true
					end
				end
			end
			
			InsertProductTile(npcData, Items[item], ItemAlreadyPurchased)	
		end
		
		ShowNPCDialogue(npcData, "Starters", math.random(1,3))
		
		--NPC will be used to physical change his face, produce sounds, and play animations while shopping
	end
end)

StoreFrontPurchase.OnClientEvent:Connect(function(Item, MissingFunds)
	if MissingFunds then
		coroutine.resume(coroutine.create(function()
			ShowNPCDialogue(CurrentNPC, "Cannot Afford Item", 1, tostring(MissingFunds))
		end))
		
		--SoundEffects:PlaySound(StoreFrontGui.InteractedObject.Value, SadVoice, math.sqrt(2))
	else
		print(tostring(Player) .. " has successfully purchased " .. tostring(Item))
		local Tile = StoreFrontMenu.CurrentTile.Value
		Tile.ItemCost.Text = "Purchased"
		Tile.AlreadyPurchased.Value = true
		
		StoreFrontMenu.PurchaseItemButton.BackgroundColor3 = Color3.fromRGB(143, 136, 128)
		StoreFrontMenu.PurchaseItemButton.BorderColor3 = Color3.fromRGB(88, 84, 79)
		
		coroutine.resume(coroutine.create(function()
			ShowNPCDialogue(CurrentNPC, "Thank You For Purchase", 1)
		end))
		
		
		
		--SoundEffects:PlaySound(StoreFrontGui.InteractedObject.Value, HappyVoice, math.sqrt(2))
	end
end)

