--(Local Script)
--Handles Shop Keeper NPC data to fill player's StoreFrontGui once they interact with an NPC
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local Player = game.Players.LocalPlayer
local PlayerUserId = Player.UserId
local EventsFolder = game.ReplicatedStorage.Events
local GuiElements = game.ReplicatedStorage.GuiElements

local StoreFrontGui = script.Parent
local StoreFrontMenu = StoreFrontGui.StoreFrontMenu
local ProductsDisplay = StoreFrontMenu.ProductsDisplay
local ItemStatView = StoreFrontMenu.ItemStatView

local UpdateStoreFront = EventsFolder.GUI:WaitForChild("UpdateStoreFront")
local MoveAllBaseScreenUI = EventsFolder.GUI:WaitForChild("MoveAllBaseScreenUI")
local StoreFrontPurchase = EventsFolder.Utility:WaitForChild("StoreFrontPurchase")

if StoreFrontGui.StoreFrontMenu.Visible == true then
	StoreFrontGui.StoreFrontMenu.Visible = false
end

local Character = game.Workspace.Players:WaitForChild(tostring(Player))
local DefaultWalkSpeed = Character.Humanoid.WalkSpeed
local DefaultJumpPower = Character.Humanoid.JumpPower

local GuiUtility = require(game.ReplicatedStorage:WaitForChild("GuiUtility"))
local SoundEffects = require(game.ReplicatedStorage:WaitForChild("SoundEffects"))

----------------------<|Utility|>--------------------------------------------------------------------------------------------------------------
local StarterGui = game:GetService("StarterGui")

local function DisplayStoreFrontGUI(bool)
	StoreFrontMenu.Visible = bool
	--StoreFrontMenu.CurrentPage.Value = 1
	
	if bool == true then --Display
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		
		for i,statDisplay in pairs (StoreFrontMenu.ItemStatView:GetChildren()) do
			statDisplay.Visible = false
		end
		
		--StoreFrontMenu.PurchaseItemButton.Active = false
		--StoreFrontMenu.PurchaseItemButton.Visible = false
		--StoreFrontMenu.NextMessage.Visible = false
		
		for i,guiElement in pairs (StoreFrontMenu:GetChildren()) do
			guiElement.Visible = true
		end
		StoreFrontMenu["NPC Dialogue"].Visible = false
		
		--**Temporarily commented off since final positions have not been decided yet
		--[[
		--Move GUIs off screen
		StoreFrontMenu.ItemStatView.Position = UDim2.new(0.362, 0, 1.35, 0)
		StoreFrontMenu["NPC Info"].Position = UDim2.new(0.381, 0, -0.1, 0)
		StoreFrontMenu.PlayerCashDisplay.Position = UDim2.new(-0.55, 0, 0.032, 0)
		StoreFrontMenu.ExitStoreButton.Position = UDim2.new(0.01, 0, 1.15, 0)
		StoreFrontMenu.NextPage.Position = UDim2.new(0.747, 0, 1.15, 0)
		StoreFrontMenu.PreviousPage.Position = UDim2.new(0.747, 0, -0.15, 0)
		StoreFrontMenu.PurchaseItemButton.Position = UDim2.new(0.109, 0, 1.15, 0)
		--StoreFrontMenu.TalkButton.Position = UDim2.new(-0.15, 0, 0.677, 0)

		--Tween GUIs into view
		StoreFrontMenu.ItemStatView:TweenPosition(UDim2.new(0.362, 0, 0.667, 0), "Out", "Quint", .4)
		StoreFrontMenu["NPC Info"]:TweenPosition(UDim2.new(0.381, 0, 0.035, 0), "Out", "Quint", .4)
		wait(.2)
		StoreFrontMenu.PlayerCashDisplay:TweenPosition(UDim2.new(0.054, 0, 0.032, 0), "Out", "Quint", .4)
		StoreFrontMenu.ExitStoreButton:TweenPosition(UDim2.new(0.01, 0, 0.846, 0), "Out", "Quint", .4)
		--StoreFrontMenu.TalkButton:TweenPosition(UDim2.new(0.01, 0, 0.677, 0), "Out", "Quint", .4)
		StoreFrontMenu.PurchaseItemButton:TweenPosition(UDim2.new(0.109, 0, 0.846, 0), "Out", "Quint", .4)
		wait(.2)
		]]
	else --Close StoreFrontMenu: Reset Menu
		StoreFrontGui.InteractedShop.Value = nil
		--StoreFrontMenu.CurrentPage.Value = 0
		StoreFrontMenu.CurrentTile.Value = nil
		
		--Delete all pages in product display
		for i,product in pairs (ProductsDisplay:GetChildren()) do
			product:Destroy()
		end
		
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end
end

local function TweenCashFlaps(decimalPresent) --0.25 seconds to work with
	local costFlaps = StoreFrontMenu.PurchaseBox.CostFlaps
	local finalYHeight
	local style
	
	if decimalPresent == nil then --Hide all flaps
		finalYHeight = -0.1
		style = "In"
	else
		if decimalPresent == false then
			local changeTo = costFlaps.Decimal.Position.X.Scale
			costFlaps.Number2.Position = UDim2.new(changeTo, 0, 0, 0)
			costFlaps.Number3.Position = UDim2.new(changeTo + costFlaps.Number2.Size.X.Scale + 0.017, 0, 0, 0)
			costFlaps.Letter.Visible = false
			--Position directly below where flaps will come from
		else
			costFlaps.Letter.Visible = true		
		end
		finalYHeight = -4.6
		style = "Out"
	end
	
	--Move all flaps
	for i,flap in pairs (costFlaps:GetChildren()) do
		if flap:IsA("Frame") then
			flap.Visible = flap.Utilized.Value
		end
		
		if flap:IsA("Frame") and flap.Position.Y.Scale ~= finalYHeight then
			if finalYHeight ~= -0.1 then
				if flap.Name == "Decimal" then
					flap:TweenPosition(UDim2.new(flap.Position.X.Scale, 0, -2.115, 0), style, "Quint", 0.041/3)
				else
					flap:TweenPosition(UDim2.new(flap.Position.X.Scale, 0, finalYHeight, 0), style, "Quint", 0.041)
				end
			else
				flap:TweenPosition(UDim2.new(flap.Position.X.Scale, 0, finalYHeight, 0), style, "Quint", 0.041)
			end

			wait(.041)
		end
	end
	
	if style == "In" then
		costFlaps.Number2.Position = UDim2.new(0.541, 0, finalYHeight, 0)
		costFlaps.Number3.Position = UDim2.new(0.681, 0, finalYHeight, 0)
	end
end

local function ManageStatDisplay(StatName, StatValue, Item, ImageType)
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

local function GetSlotCount()
	local slotCount = 0
	for i,slot in pairs (ProductsDisplay:GetChildren()) do
		if slot:IsA("ViewportFrame") and string.find(slot.Name, "Slot") then
			slotCount += 1
		end
	end
	
	return slotCount
end

StoreFrontGui.Open.Changed:Connect(function(value)
	local ProxObject = StoreFrontGui.InteractedShop.Value
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

local function MoveCameraToStore(shopKeeper)
	Character.Humanoid.WalkSpeed = 0
	Character.Humanoid.JumpPower = 0
	
	PlayerVisibility(1)
	
	local CutsceneFolder = shopKeeper:FindFirstChild("CutsceneCameras")
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


----------------------<|Slot Change Manager Functions|>-----------------------------------------------------------------------------------------------
local slotDebounce = false
local infoBannerOpen = false

local function ChangeToSlot(direction)
	if slotDebounce == false then
		slotDebounce = true
		
		local currentTile = StoreFrontMenu.CurrentTile.Value
		local currentTileNumber = string.gsub(currentTile.Name, "Slot", "")
		local newTileNumber = tonumber(currentTileNumber) + direction
		
		--**Add tween effects later once everything is sorted and positions are finalized
			
		local newTile
		local nextTile
		local prevTile
		if ProductsDisplay:FindFirstChild("Slot" .. tostring(newTileNumber)) then
			newTile = ProductsDisplay:FindFirstChild("Slot" .. tostring(newTileNumber))
			nextTile = ProductsDisplay:FindFirstChild("Slot" .. tostring(newTileNumber + 1))
			prevTile = ProductsDisplay:FindFirstChild("Slot" .. tostring(newTileNumber - 1))
		else
			if direction == 1 then
				newTile = ProductsDisplay.Slot1
				nextTile = ProductsDisplay.Slot2
				
				newTile.Position = UDim2.new(1.25, 0, 0.5, 0)
				nextTile.Position = UDim2.new(1.25, 0, 0.5, 0)
				currentTile:TweenPosition(UDim2.new(-0.25, 0, 0.5, 0), "Out", "Quint", 0.4) --off screen to left
			else
				local totalSlots = GetSlotCount()
				newTile = ProductsDisplay:FindFirstChild("Slot" .. tostring(totalSlots))
				prevTile = ProductsDisplay:FindFirstChild("Slot" .. tostring(totalSlots - 1))
				
				newTile.Position = UDim2.new(-0.25, 0, 0.5, 0)
				prevTile.Position = UDim2.new(-0.25, 0, 0.5, 0)
				currentTile:TweenPosition(UDim2.new(1.25, 0, 0.4, 0), "Out", "Quint", 0.4) --off screen to right
			end
			currentTile:TweenSize(UDim2.new(0.211, 0, 0.364, 0), "Out", "Quint", 0.4)
		end
		
		local assocCurrentTile = ProductsDisplay:FindFirstChild("Slot" .. tonumber(currentTileNumber - direction))
		if assocCurrentTile then
			assocCurrentTile:TweenPosition(UDim2.new(0.5 - .75*direction, 0, 0.4, 0), "Out", "Quint", 0.4)
			assocCurrentTile:TweenSize(UDim2.new(0.183, 0, 0.317, 0), "Out", "Quint", 0.4)
		end
		
		local trueNewTileNumber = string.gsub(newTile.Name, "Slot", "")
		
		StoreFrontMenu.CurrentTile.Value = newTile
		newTile.Visible = true
		newTile:TweenPosition(UDim2.new(0.5, 0, 0.454, 0), "Out", "Quint", 0.4)
		newTile:TweenSize(UDim2.new(0.29, 0, 0.502, 0), "Out", "Quint", 0.4)
		
		if nextTile then
			nextTile.Visible = true
			nextTile:TweenPosition(UDim2.new(0.853, 0, 0.402, 0), "Out", "Quint", 0.4)
			nextTile:TweenSize(UDim2.new(0.211, 0, 0.364, 0), "Out", "Quint", 0.4)
		end
		if prevTile then
			prevTile.Visible = true
			prevTile:TweenPosition(UDim2.new(0.148, 0, 0.402, 0), "Out", "Quint", 0.4)
			prevTile:TweenSize(UDim2.new(0.211, 0, 0.364, 0), "Out", "Quint", 0.4)
		end
		
		local extraWait = 0
		if infoBannerOpen then
			infoBannerOpen = false
			extraWait = 0.5
		end
		
		wait(0.5 + extraWait) --wait for tweens
		
		--position all unseen tiles offscreen where they will be 'pulled' from
		for i,slot in pairs (ProductsDisplay:GetChildren()) do
			if slot:IsA("ViewportFrame") and string.find(slot.Name, "Slot") then
				local slotNumber = string.gsub(slot.Name, "Slot", "")
				
				if tonumber(slotNumber) < tonumber(trueNewTileNumber) - 1 then --off screen to left
					slot.Position = UDim2.new(-0.25, 0, 0.5, 0)
					slot.Size = UDim2.new(0.211, 0, 0.364, 0)
					slot.Visible = false
				elseif tonumber(slotNumber) > tonumber(trueNewTileNumber) + 1 then --off screen to right
					slot.Position = UDim2.new(1.25, 0, 0.5, 0)
					slot.Size = UDim2.new(0.211, 0, 0.364, 0)
					slot.Visible = false
				end
				end
		end
		
		slotDebounce = false
	end
end

GuiUtility.SetUpPressableButton(StoreFrontMenu.NextSlot, 0.004)
StoreFrontMenu.NextSlot.Activated:Connect(function()
	ChangeToSlot(1)
end)
StoreFrontMenu.SecondaryNextSlot.Activated:Connect(function()
	ChangeToSlot(1)
end)

GuiUtility.SetUpPressableButton(StoreFrontMenu.PreviousSlot, 0.004)
StoreFrontMenu.PreviousSlot.Activated:Connect(function()
	ChangeToSlot(-1)
end)
StoreFrontMenu.SecondaryPreviousSlot.Activated:Connect(function()
	ChangeToSlot(-1)
end)

-------------------------<|Tile Management Functions|>-----------------------------------------------------------------------------------------

--Update Product Info
StoreFrontMenu.LowShopBanner.Position = UDim2.new(0.33, 0, 0.028, 0)
StoreFrontMenu.CurrentTile.Changed:Connect(function()
	local tile = StoreFrontMenu.CurrentTile.Value
	
	if tile then
		local item = tile.ReferenceObject.Value
		local equipType = item.Parent.Parent
		
		local extraWait = 0
		if infoBannerOpen then
			infoBannerOpen = false
			extraWait = 0.5
		end
		--Update LowBanner with Rarity & Item Name
		coroutine.resume(coroutine.create(function()
			StoreFrontMenu.LowShopBanner:TweenPosition(UDim2.new(0.328, 0, -0.383, 0), "Out", "Quint", .24 + extraWait)
			wait(.24 + extraWait)
			StoreFrontMenu.LowShopBanner.ItemName.Text = tostring(item)
			--Update image of banner for rarity
			--Update and color info under banner
			StoreFrontMenu.LowShopBanner:TweenPosition(UDim2.new(0.328, 0, -0.295, 0), "Out", "Quint", .24)
		end))
		
	------Manage Stat Displays
		if item:FindFirstChild(tostring(item) .. "Stats") then
			local ItemStats = require(item:FindFirstChild(tostring(item) .. "Stats"))
			
			for stat = 1,#ItemStats["Stats"],1 do
				local Stat = ItemStats["Stats"][stat]
				if ItemStats["Images"][Stat[1] .. "Image"] then --Display Stat				
					local StatName = string.gsub(Stat[1], tostring(item), "")
					local StatValue = Stat[2]
					local StatImage = ItemStats["Images"][Stat[1] .. "Image"][1]
					local ImageType = ItemStats["Images"][Stat[1] .. "Image"][2]
					ManageStatDisplay(Stat[1], StatValue, item, ImageType)
				end
			end 
		end
		
		--Hide Remaining Stat Tiles and Reset All
		for i,statDisplay in pairs (ItemStatView:GetChildren()) do
			if statDisplay:FindFirstChild("Utilized") then
				statDisplay.Visible = statDisplay.Utilized.Value
				statDisplay.Utilized.Value = false
			end
		end
		
		--Display Name
		--Display Rarity
		--Display Item Cost
		--Change how purchase button looks
		--
		
		local alreadyPurchased = tile.AlreadyPurchased.Value
		StoreFrontMenu.PurchaseBox.PurchaseItemButton.Active = not alreadyPurchased
		--Change Purchase button image and active state based on purchaseValue
		--StoreFrontMenu.ItemPurchased.Visible = not purchaseValue
		
		
	------Manage cost value flaps above purchase button
		TweenCashFlaps() --Hide Flaps

		local shortCost = tostring(GuiUtility.ConvertShort(tile.ReferenceValue.Value))
		local costFlaps = StoreFrontMenu.PurchaseBox.CostFlaps
		
		local decimalPresent = false
		print(shortCost)
		if string.len(shortCost) == 5 then
			decimalPresent = true
		end
		
		for i,flap in pairs (costFlaps:GetChildren()) do
			if flap:IsA("Frame") then
				flap.Utilized.Value = false
			end
		end
		
		--Manage Cash Flap Text
		if tonumber(string.sub(shortCost, 1, 1)) > 0 then
			local prevNumberT = 0
			for t = 1,string.len(shortCost) do
				local char = string.sub(shortCost, t, t)

				if tonumber(char) then
					prevNumberT += 1
					local flap = costFlaps:FindFirstChild("Number" .. tostring(prevNumberT))
					flap.Number.Text = char
					flap.Utilized.Value = true
				elseif char == "." then
					costFlaps.Decimal.Decimal.Text = char
					costFlaps.Decimal.Utilized.Value = true
				else
					costFlaps.Letter.Letter.Text = char
					costFlaps.Letter.Utilized.Value = true
				end
				
				--Change currency label
				local currencyType = tile.ReferenceCashType.Value
				if currencyType ~= nil and currencyType ~= "" then
					local typeInfo = game.ReplicatedStorage.Currencies:FindFirstChild(currencyType)
					costFlaps.CurrencySymbol.Symbol.Image = typeInfo.Pile.Value
					costFlaps.CurrencySymbol.UIStroke.Color = typeInfo.Color.Value
					costFlaps.CurrencySymbol.Utilized.Value = true
				end
			end
			
			--Show Flaps (make this a function that can be used to show them as well)
			TweenCashFlaps(decimalPresent) --Show Flaps
		end
		
		wait(extraWait)
	end
end)

local function InsertProductTile(shopData, ItemData, ItemAlreadyPurchased)
	local newProductTile = game.ReplicatedStorage.GuiElements:WaitForChild("StoreFrontSlot"):Clone()
	
	local slotCount = GetSlotCount()
	newProductTile.Parent = ProductsDisplay
	if slotCount > 0 then --Slot already present to reference
		newProductTile.Name = "Slot" .. tostring(slotCount + 1)
		newProductTile.Position = UDim2.new(1.5, 0, 0.5, 0) --off screen to right
		newProductTile.Size = UDim2.new(0.211, 0, 0.364, 0)
		newProductTile.Visible = false
		
		--Position Slot2 off to side since this is positioning tiles on first open
		if slotCount + 1 == 2 then
			newProductTile.Position = UDim2.new(0.853, 0, 0.402, 0)
			newProductTile.Visible = true
		end
	else --First slot
		newProductTile.Name = "Slot1"
		newProductTile.Position = UDim2.new(0.5, 0, 0.454, 0)
		newProductTile.Size = UDim2.new(0.29, 0, 0.502, 0)
		newProductTile.Visible = true
	end
	
	newProductTile.AlreadyPurchased.Value = ItemAlreadyPurchased
	newProductTile.ReferenceObject.Value = ItemData[1]
	newProductTile.ReferenceValue.Value = ItemData[2]
	newProductTile.ReferenceCashType.Value = ItemData[3]
	
	--Display 3D Object in viewport
	local itemInfo = ItemData[1]
	local equipType = itemInfo.Parent.Parent.Name
	local object
	if equipType == "Tools" then
		object = itemInfo.Handle
	else
		if itemInfo:IsA("Part") or itemInfo:IsA("MeshPart") then
			object = itemInfo
		elseif itemInfo:IsA("Model") then
			object = itemInfo.Target
		else
			--nothing found to display, display placeholder object
			object = GuiElements:FindFirstChild("3DObjectPlaceholder")
		end
	end
	GuiUtility.Display3DModels(Player, newProductTile, object:Clone(), true, itemInfo["GUI Info"].DisplayAngle.Value)
end

---------------------<|NPC Dialogue Functions|>------------------------------------------------------------------------------------------------
local CharactersPerLine = 20
local dialogueBox = StoreFrontMenu.DialogueBox
local TalkButton = StoreFrontMenu.TalkButton
local CurrentNPC

local timeBeforeAppear = 5
local function CountDownDialogue()
	local timer = dialogueBox.TimeLeft
	timer.Value = 0
	
	coroutine.resume(coroutine.create(function()
		for sec = 1,timeBeforeAppear,1 do
			wait(1)
			
			if sec == timer.Value + 1 then
				timer.Value = sec
				if sec == timeBeforeAppear then --Close NPC Dialogue
					dialogueBox:TweenPosition(UDim2.new(dialogueBox.Position.X.Scale, 0, 1.05, 0), "Out", "Quint", .5)
					dialogueBox:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Quint", .5)
					wait(.5)

					dialogueBox.Visible = false
					dialogueBox.TextBox.TextLabel.Text = ""
					dialogueBox.Position = UDim2.new(0.019, 0, 1.05, 0)
					dialogueBox.Size = UDim2.new(0.337, 0, 0.323, 0)
				end
			
			--[[
			if dialogueBox.TimeLeft.Value == i - 1 then
				dialogueBox.TimeLeft.Value = i
				if i == 10 then --Close NPC Dialogue
					dialogueBox:TweenPosition(UDim2.new(0.178, 0, 0.412, 0), "Out", "Quint", .5)
					dialogueBox:TweenSize(UDim2.new(0, 0, 0, 0), "Out", "Quint", .5)
					wait(.5)

					dialogueBox.Visible = false
					dialogueBox.Text = ""
					dialogueBox.Position = UDim2.new(0.14, 0, 0.412, 0)
					dialogueBox.Size = UDim2.new(0.32/4, 0, 0.07)
					
					--NextMessage.Visible = false
					--NextMessage.Active = false
					--NextMessage.Selectable = false
				end
			end
			wait(1)
			]] 
			end
		end
	end))
end

local function CheckToReplaceText(String, Find, Replace)
	if string.find(String, Find) then
		String = string.gsub(String, Find, Replace)
	end
	
	return String
end

local function ShowNPCDialogue(shopData, SetResponse, Index, MissingFunds)

	local Message = shopData["Dialogue"][SetResponse][Index]
	
	Message = CheckToReplaceText(Message, "PLAYER", tostring(Player))
	Message = CheckToReplaceText(Message, "MISSINGFUNDS", "$" .. tostring(MissingFunds))
	
	if StoreFrontMenu.CurrentTile.Value ~= nil then
		Message = CheckToReplaceText(Message, "ITEM", tostring(StoreFrontMenu.CurrentTile.Value))
	end
	
	local CharacterCount = string.len(Message)
	local LineCount = math.floor(CharacterCount/CharactersPerLine + 0.5)
	
	dialogueBox.Visible = false
	--NextMessage.Visible = false
	dialogueBox.TextBox.TextLabel.Text = ""
	--dialogueBox.UIPadding.PaddingBottom = UDim.new(0.05, 0)
	dialogueBox.Position = UDim2.new(0.019, 0, 1.05, 0)
	dialogueBox.Size = UDim2.new(0.337, 0, 0.323, 0)
	
	dialogueBox.Visible = true
	dialogueBox:TweenPosition(UDim2.new(0.019, 0, 0.98 - LineCount*0.07, 0), "Out", "Quint", .5)
	dialogueBox:TweenSize(UDim2.new(0.337, 0, 0.07 * LineCount, 0), "Out", "Quint", .5)
	
	--Message = [[Welcome to my shop<br /><font size="46" color="rgb(255,50,25)">Test Man!</font>]]
	dialogueBox.TextBox.TextLabel.Text = Message
	
	coroutine.resume(coroutine.create(function()
		GuiUtility.typeWrite(dialogueBox, Message, 0.045)
	end))
	
	for i = 1,CharacterCount/math.sqrt(2),1 do
		SoundEffects:PlaySound(StoreFrontGui.InteractedShop.Value, shopData["Voice"]["Neutral"], 0.045*math.sqrt(2))
	end
	
	--**Change this so if the player clicks anywhere within the text box it skips to the next dialogue (if there
	--even will be instances where this happens)
	--**Make countdown timer work better since it appears to sometimes expire (look at how I fixed that problem in
	--the inventory with the displayinfo code)
	
	wait(.5)
	TalkButton.CurrentIndex.Value = Index
	if #shopData["Dialogue"][SetResponse] > 1 and TalkButton.CurrentIndex.Value ~= #shopData["Dialogue"][SetResponse] then
		if SetResponse ~= "Starters" and SetResponse ~= "Goodbyes" then
			--TalkButton.ConversationName.Value = SetResponse
			--TalkButton.CurrentIndex.Value = Index
			
			--Set up NextMessage button
			--coroutine.resume(coroutine.create(function()
				--for i = 1,25,1 do
					--NPCDialogue.UIPadding.PaddingBottom = UDim.new(0.05 + (0.45/LineCount)/(26-i), 0)
					--wait()
				--end
			--end))
			
			--NextMessage.Position = UDim2.new(0.14, 0, 0.402, 0)
			--NextMessage.Size = UDim2.new(0.32/4, 0, 0, 0)
			
			--wait(.3)
			--NextMessage.Visible = true
			--NextMessage.Active = true 
			--NextMessage.Selectable = true
			
			--dialogueBox:TweenPosition(UDim2.new(0.019, 0, 0.65, 0), "In", "Quint", .5)
			--dialogueBox:TweenSize(UDim2.new(0.337, 0, 0.07 * LineCount, 0), "In", "Quint", .5)
			--NextMessage:TweenPosition(UDim2.new(0.14, 0, 0.412 - 0.05, 0), "In", "Quint", .5)
			--NextMessage:TweenSize(UDim2.new(0.32/4, 0, 0.038, 0), "In", "Quint", .5)
			--wait(.5)
		else
			CountDownDialogue()
		end
	else
		CountDownDialogue()
	end
end

---------------------<|Button-Press Functions|>------------------------------------------------------------------------------------------------

StoreFrontMenu.PurchaseBox.PurchaseItemButton.Activated:Connect(function()
	local CurrentTile = StoreFrontMenu.CurrentTile.Value
	local ItemName = CurrentTile.DisplayName.Text
	
	if CurrentTile.AlreadyPurchased.Value == false then
		local NPC = StoreFrontGui.InteractedShop.Value.Name
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

local infoButton = StoreFrontMenu.LowShopBanner.InfoButton
local infoButtonTI = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local infoButtonEnterTween = TweenService:Create(infoButton, infoButtonTI, {Position = UDim2.new(0.87, 0, -0.124, 0)})
local infoButtonLeaveTween = TweenService:Create(infoButton, infoButtonTI, {Position = UDim2.new(0.87, 0, -0.196, 0)})

local function ManageInfoTween(playTween)
	infoButtonLeaveTween:Pause()
	infoButtonEnterTween:Pause()
	playTween:Play()
end

local infoButtonDebounce = false
infoButton.MouseEnter:Connect(function()
	if infoButtonDebounce == false then
		ManageInfoTween(infoButtonEnterTween)
	end
end)
infoButton.MouseLeave:Connect(function()
	if infoButtonDebounce == false then
		ManageInfoTween(infoButtonLeaveTween)
	end
end)
infoButton.Activated:Connect(function()
	if infoButtonDebounce == false then
		infoButtonDebounce = true
		ManageInfoTween(infoButtonLeaveTween)
		
		if infoBannerOpen then
			infoBannerOpen = false
			StoreFrontMenu.LowShopBanner:TweenPosition(UDim2.new(0.328, 0, -0.295, 0), "Out", "Quint", 0.6)
			wait(0.6)
		else
			infoBannerOpen = true
			StoreFrontMenu.LowShopBanner:TweenPosition(UDim2.new(0.328, 0, 0.115, 0), "Out", "Quint", 1)
			wait(1)
		end
		infoButtonDebounce = false
	end
end)

StoreFrontMenu.TalkButton.Activated:Connect(function()
	ShowNPCDialogue(CurrentNPC, "Dialogue1", 1)
end)

--**TalkButton and NextMessage Buttons have now become one button, utilizing the invisible hitbox of the
--TalkButton in front of the shop keeper, skiping to the next dialogue if a conversation already started, or
--starting a new one if the shop keeper was first clicked/previous conversation expired

--NextMessage.Activated:Connect(function()
	--ShowNPCDialogue(CurrentNPC, NextMessage.ConversationName.Value, NextMessage.CurrentIndex.Value+1)
--end)

---------------------<|StoreFront Events|>----------------------------------------------------------------------------------------------------

UpdateStoreFront.OnClientEvent:Connect(function(shopKeeper, shopData, AlreadyPurchased)
	if StoreFrontGui.Open.Value == false then
		StoreFrontGui.InteractedShop.Value = shopKeeper
		StoreFrontGui.Open.Value = true
		CurrentNPC = shopData
		
		MoveCameraToStore(shopKeeper)
		MoveAllBaseScreenUI:Fire("Hide")
		wait(.5)
		
		coroutine.resume(coroutine.create(function()
			DisplayStoreFrontGUI(true)
		end))
		
		--Hide players that are nearby until the player exits the store front
		--Other player touches radius part turns invisible
		--Player reappears no longer touching radius part: left radpart or radpart was deleted
		
		--Update Shop Banner
		StoreFrontMenu.ShopBanner.ShopName.Text = shopData["Shop Name"]
		StoreFrontMenu.ShopBanner.ShopType.Text = shopData["Shop Type"]
		
		local Items = shopData["Items"]
		for item = 1,#Items,1 do
			
			--Items[item][1] = ReplicatedStorage Item
			--Items[item][2] = Price
			
			local ItemAlreadyPurchased = false
			for i = 1,#AlreadyPurchased,1 do
				local PurchasedItem = AlreadyPurchased[i]
				
				--Ensure all info of already purchased item is true
				if PurchasedItem.Parent == Items[item][1].Parent then
					if AlreadyPurchased[i] == Items[item][1] then
						ItemAlreadyPurchased = true
					end
				end
			end
			
			--later also check for not already purchased items IF THEY HAVE BEEN RESEARCHED
			--(if something has been already purchased it is known it must be visible in the shop already)
			
			InsertProductTile(shopData, Items[item], ItemAlreadyPurchased)	
		end
		
		StoreFrontMenu.CurrentTile.Value = ProductsDisplay.Slot1

		local slotCount = GetSlotCount()
		local tipSlot = GuiElements.StoreFrontSlot:Clone()
		tipSlot.Name = "Slot" .. tostring(slotCount + 1)
		tipSlot.Visible = false
		tipSlot.Parent = ProductsDisplay

		local lockedBlock = GuiElements.LockedBlock
		tipSlot.ReferenceObject.Value = lockedBlock
		GuiUtility.Display3DModels(Player, tipSlot, lockedBlock:Clone(), true, lockedBlock["GUI Info"].DisplayAngle.Value)
		
		
		ShowNPCDialogue(shopData, "Starters", math.random(1,3))
		
		--NPC will be used to physical change his face, produce sounds, and play animations while shopping
		--**stop-motioney animations will help with time and may add stylization to the game
	end
end)

StoreFrontPurchase.OnClientEvent:Connect(function(Item, MissingFunds)
	if MissingFunds then
		coroutine.resume(coroutine.create(function()
			ShowNPCDialogue(CurrentNPC, "Cannot Afford Item", 1, tostring(MissingFunds))
		end))
		
		--SoundEffects:PlaySound(StoreFrontGui.InteractedShop.Value, SadVoice, math.sqrt(2))
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
		
		--SoundEffects:PlaySound(StoreFrontGui.InteractedShop.Value, HappyVoice, math.sqrt(2))
	end
end)

