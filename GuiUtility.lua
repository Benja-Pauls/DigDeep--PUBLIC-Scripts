local GuiUtility = {}

function GuiUtility.GetItemInfo(statName, typeOnly)
	for _,itemType in pairs (game.ReplicatedStorage.InventoryItems:GetChildren()) do
		if itemType:FindFirstChild(statName) then
			if typeOnly then
				return itemType
			else
				return itemType:FindFirstChild(statName)
			end
		end
	end
end

function GuiUtility.GetStatImage(stat)
	local itemInfo = GuiUtility.GetItemInfo(tostring(stat))

	if itemInfo then
		if itemInfo["GUI Info"].StatImage then
			return itemInfo["GUI Info"].StatImage.Value
		end
	end
end

--------------<|Text Effects|>-------------------------------------------------------------

function GuiUtility.typeWrite(guiObject, text, delayBetweenChars)
	guiObject.Visible = true
	guiObject.AutoLocalize = false

	local displayText = text
	guiObject.Text = displayText

	local index = 0
	for first, last in utf8.graphemes(displayText) do
		index = index + 1
		guiObject.MaxVisibleGraphemes = index
		wait(delayBetweenChars)
	end
end

function GuiUtility.ManageSearchVisual(searchInput)
	searchInput.Text = "Search..."
	searchInput.Focused:Connect(function()
		searchInput.Text = ""
	end)
	searchInput.FocusLost:Connect(function()
		searchInput.Text = "Search..."
	end)
end

-----------<|Exclusively Calculations|>------------------------------------

function GuiUtility.ConvertShort(Filter_Num) --this function is also in PlayerStatManager for server
	local x = tostring(Filter_Num)
	
	if #x>=10 then
		local important = (#x-9)
		return x:sub(0,(important)).."."..(x:sub(#x-7,(#x-7))).."B"
	elseif #x>=7 then
		local important = (#x-6)
		return x:sub(0,(important)).."."..(x:sub(#x-5,(#x-5))).."M"
	elseif #x>=4 then
		local important = (#x-3)
		return x:sub(0,(important)).."."..(x:sub(#x-2,(#x-2)))..(x:sub(#x-1,(#x-1))) .. "K"
	else
		return Filter_Num
	end
end

function GuiUtility.SlotCountToXY(PageSlotCount, tilesPerRow)
	local tileNumber = PageSlotCount
	local rowValue = math.floor(tileNumber / tilesPerRow)
	local columnValue = (PageSlotCount % (tilesPerRow))
	return columnValue, rowValue
end

-------------<|Tween Functions|>------------------------------------------------------
local TweenService = game:GetService("TweenService")


local CurrentTweens = {}
local function PressGUIButton(button, newPosition, newSize, moveType)
	if button.Visible == true then
		if button.Position ~= newPosition and button.Size ~= newSize then

			local opposingMoveType
			if moveType == "neutral" then
				opposingMoveType = "press"
			else
				opposingMoveType = "neutral"
			end
			if CurrentTweens[tostring(button.Parent) .. tostring(button) .. opposingMoveType] then
				local opposingTween = CurrentTweens[tostring(button.Parent) .. tostring(button) .. opposingMoveType]
				opposingTween:Pause()
			end

			if CurrentTweens[tostring(button.Parent) .. tostring(button) .. moveType] then
				local tween = CurrentTweens[tostring(button.Parent) .. tostring(button) .. moveType]
				tween:Pause()
				tween:Play()
			else
				local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				local tween = TweenService:Create(button, tweenInfo, {Position = newPosition, Size = newSize})

				tween:Play()
				CurrentTweens[tostring(button.Parent) .. tostring(button) .. moveType] = tween
			end
		end
	end
end

function GuiUtility.SetUpPressableButton(button, scaleChange)
	local neutralPosition = button.Position
	local neutralSize = button.Size
	local pressPosition = UDim2.new(neutralPosition.X.Scale, 0, neutralPosition.Y.Scale + (scaleChange + scaleChange*.2), 0)
	local pressSize = UDim2.new(neutralSize.X.Scale, 0, neutralSize.Y.Scale - scaleChange, 0)

	button.MouseButton1Down:Connect(function()
		PressGUIButton(button, pressPosition, pressSize, "press")
	end)
	button.MouseLeave:Connect(function()
		PressGUIButton(button, neutralPosition, neutralSize, "neutral")
	end)
	button.MouseButton1Up:Connect(function()
		PressGUIButton(button, neutralPosition, neutralSize, "neutral")
	end)
end

--possible page/tile change tween manager here as well..?

-------------<|Menu Display Functions|>------------------------------------------------

function GuiUtility.Display3DModels(Player, viewport, displayModel, bool, displayAngle)
	--possibly clear all viewports once menu is closed? (or once viewport is not visible?)
	--print("Display3DModels: ", Player, viewport, displayModel, bool, displayAngle)
	if bool == true then
		GuiUtility.Display3DModels(Player, viewport, displayModel:Clone(), false) --reset current viewPort

		local rootPart
		if displayModel.Name == tostring(Player) then
			displayModel.Parent = viewport.Physics
			rootPart = displayModel.HumanoidRootPart

			local idleAnimation = displayModel.Humanoid:LoadAnimation(displayModel.Animate.idle.Animation1)
			idleAnimation:Play()
		else
			local ParentModel = Instance.new("Model", viewport.Physics)
			displayModel.Parent = ParentModel
			rootPart = displayModel
			displayModel = ParentModel
		end
		local vpCamera = Instance.new("Camera",viewport)

		rootPart.Name = "RootPart"
		rootPart.Anchored = true
		viewport.CurrentCamera = vpCamera

		--Move Camera Around Object & Auto FOV
		local referenceAngle = Instance.new("NumberValue", rootPart)
		referenceAngle.Name = "ReferenceAngle"
		referenceAngle.Value = displayAngle
		local modelCenter, modelSize = displayModel:GetBoundingBox()	

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

		local minDist = (maxExtent/4)/tan + diagonal
		game:GetService("RunService").RenderStepped:Connect(function(dt)
			referenceAngle.Value += (1*dt*60)/3
			vpCamera.CFrame = modelCenter * CFrame.fromEulerAnglesYXZ(0, math.rad(referenceAngle.Value), 0) * CFrame.new(0, 0, minDist + 3)
		end)
	else
		viewport.CurrentCamera = nil
		for i,view in pairs (viewport.Physics:GetChildren()) do
			view:Destroy()
		end
	end
end

function GuiUtility.Reset3DObject(Player, viewport, displayModel, angle)
	viewport.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then
			if displayModel == nil then
				local differentDisplayModel = viewport.Physics.Model.RootPart
				local differentAngle = viewport.Physics.Model.RootPart.ReferenceAngle.Value
				if differentDisplayModel ~= nil then
					GuiUtility.Display3DModels(Player, viewport, differentDisplayModel:Clone(), true, differentAngle)
				end
			else
				GuiUtility.Display3DModels(Player, viewport, displayModel:Clone(), true, angle)
			end
		end
	end)
end

function GuiUtility.ManageTextBoxSize(frame, inputText, charactersPerRow, rowSize)
	local characterAmount = string.len(inputText)
	local rowCount = characterAmount/charactersPerRow

	if rowCount < 1 then
		rowCount = 1
	--else
		--rowCount = math.ceil(rowCount)
	end

	frame.Size = UDim2.new(frame.Size.X.Scale, 0, rowSize * rowCount, 0)
end





---------------<|Page Manager Functions|>--------------------

function GuiUtility.CommitPageChange(changedToPage, delayAmount)
	changedToPage.ZIndex += 1
	changedToPage.Visible = true
	changedToPage:TweenPosition(UDim2.new(0,0,0,0), "Out", "Quint", delayAmount)
	wait(.25)

	--Manage Page Invisibility
	for i,page in pairs (changedToPage.Parent:GetChildren()) do
		if page:IsA("Frame") then
			if page ~= changedToPage then
				page.Visible = false
			else
				page.Visible = true
			end
			page.Position = UDim2.new(0, 0, 0, 0)
		end
	end
	changedToPage.ZIndex -= 1
	
	return false
end

function GuiUtility.ManageTilePlacement()
	
end







return GuiUtility

