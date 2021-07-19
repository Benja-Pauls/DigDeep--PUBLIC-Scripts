--(LocalScript)
--GUI handling when player opens a blueprint for a tycoon object they wish to purchase
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Tycoons = workspace:WaitForChild("Tycoons") 

local GuiUtility = require(game.ReplicatedStorage:WaitForChild("GuiUtility"))

local TycoonPurchaseMenu = script.Parent:WaitForChild("TycoonPurchaseMenu")
TycoonPurchaseMenu.Visible = false

local PurchaseObject = game.ReplicatedStorage.Events.Utility:WaitForChild("PurchaseObject")
local GetItemCountSum = game.ReplicatedStorage.Events.Utility:WaitForChild("GetItemCountSum")
local TycoonPurchaseInteract = game.ReplicatedStorage.Events.HotKeyInteract:WaitForChild("TycoonPurchaseInteract")

local CostList = TycoonPurchaseMenu.CostsList
local PageManager = TycoonPurchaseMenu:WaitForChild("PageManager")

PageManager.Position = UDim2.new(0.722, 0, PageManager.Position.Y.Scale - 0.150, 0)

------------------------<|Utility Functions|>---------------------------------------------------------------------------------------------------------------------

local function ManageCostTextColor(Price, PlayerAmount, Slot)
	if PlayerAmount >= Price then
		Slot.CostAmount.TextColor3 = Color3.fromRGB(91, 170, 111)
	else
		Slot.CostAmount.TextColor3 = Color3.fromRGB(170, 0, 0)
	end
end

local function CheckUpgrade(OriginalObject, InfoList)
	if OriginalObject:FindFirstChild("UpgradeLevel") then
		InfoList.Upgrade.Status.Image = "rbxgameasset://Images/greencheck1"
		return true
	else
		InfoList.Upgrade.Status.Image = "rbxgameasset://Images/redx1"
		return false
	end
end

local function DestroyButtonVisuals(Button)
	local InfoList = TycoonPurchaseMenu.InformationList

	for i,visual in pairs(CostList:GetChildren()) do
		visual:Destroy()
	end
end

local NextPage = PageManager.NextPage
local PreviousPage = PageManager.PreviousPage

local function ManagePageButtonActive(bool, selectable)
	NextPage.Active = bool
	PreviousPage.Active = bool
	
	if selectable then
		print("Selectable")
		NextPage.Selectable = selectable
		PreviousPage.Selectable = selectable
	end
end


------------------------<|Tycoon Purchase Functions|>-------------------------------------------------------------------------------------------------------------

local function DisplayButtonMaterials(Button)
	
	--**In the future, tycoon purchases probably won't be bought with materials 
	--**Instead, research will be the only place players need to invest materials to progress, rather than confusing
	--them with multiple locations to put materials into
	
	
	local OriginalPage = game.ReplicatedStorage.GuiElements:FindFirstChild("DataMenuPage")
	local OriginalSlot = game.ReplicatedStorage.GuiElements:FindFirstChild("TycoonPurchaseMaterialSlot")

	local NewPage = OriginalPage:Clone()
	NewPage.Parent = CostList
	NewPage.Position = UDim2.new(0, 0, 0, 0)
	NewPage.Name = "Page1"

	local currencySlot = OriginalSlot:Clone() --Display cash cost even if 0
	currencySlot.Parent = NewPage
	currencySlot.Position = UDim2.new(0.064, 0, 0.032, 0)
	currencySlot.CostAmount.Text = tostring(Button.Price.Value)
	currencySlot.DisplayName.Text = "Cash"
	currencySlot.Picture.Image = "rbxgameasset://Images/Money1"	
	currencySlot.Name = "Slot1"

	currencySlot.Picture.BackgroundColor3 = game.ReplicatedStorage.GuiElements.RarityColors.Uncommon.TileColor.Value
	currencySlot.Picture.BorderColor3 = game.ReplicatedStorage.GuiElements.RarityColors.Uncommon.Value

	local PlayerCurrency = Player.PlayerGui.DataMenu.DataMenu.PlayerMenu.PlayerInfo.PlayerCash.Text
	currencySlot.PlayerSumAmount.Text = PlayerCurrency

	ManageCostTextColor(Button.Price.Value, tonumber(PlayerCurrency), currencySlot)

	if Button:FindFirstChild("MaterialPrice") then
		local MaterialFiles = Button.MaterialPrice:GetChildren()
		for i,file in pairs(MaterialFiles) do
			for i,material in pairs (file:GetChildren()) do
				local Pages = CostList:GetChildren()
				local CurrentPage = CostList:FindFirstChild("Page" .. tostring(#Pages))

				local ParentPage
				if #CurrentPage:GetChildren() == 4 then
					ParentPage = OriginalPage:Clone()
					ParentPage.Parent = CostList
					ParentPage.Name = "Page" .. tostring(#Pages + 1)
					ParentPage.Visible = false
				else
					ParentPage = CurrentPage
				end

				local Slots = ParentPage:GetChildren()
				local NewSlot = OriginalSlot:Clone()

				NewSlot.Parent = ParentPage
				NewSlot.Name = "Slot" .. tostring(#Slots + 1)
				NewSlot.DisplayName.Text = tostring(material)
				NewSlot.CostAmount.Text = tostring(material.Value)

				if ParentPage:FindFirstChild("Slot" .. tostring(#Slots)) then
					local PrevSlot = CurrentPage:FindFirstChild("Slot" .. tostring(#Slots))
					local PrevSlotX = PrevSlot.Position.X.Scale
					local PrevSlotY = PrevSlot.Position.Y.Scale
					NewSlot.Position = UDim2.new(PrevSlotX, 0, PrevSlotY + 0.242, 0)
				else
					NewSlot.Position = UDim2.new(0.064, 0, 0.032, 0)
				end

				local ImageId = GuiUtility.GetStatImage(material)
				NewSlot.Picture.Image = ImageId

				local itemInfo = GuiUtility.GetItemInfo(tostring(material))
				local Rarity = itemInfo["GUI Info"].RarityName.Value

				NewSlot.Picture.BackgroundColor3 = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(Rarity).TileColor.Value
				NewSlot.Picture.BorderColor3 = game.ReplicatedStorage.GuiElements.RarityColors:FindFirstChild(Rarity).Value

				local PlayerItemCount = GetItemCountSum:InvokeServer(tostring(material))
				NewSlot.PlayerSumAmount.Text = tostring(PlayerItemCount)

				ManageCostTextColor(material.Value, PlayerItemCount, NewSlot)
			end
		end
	end

	TycoonPurchaseMenu.PageManager.CurrentPage.Value = 1

	local Pages = CostList:GetChildren()
	PageManager.PageDisplay.PageNumbers.Text = tostring(PageManager.CurrentPage.Value) .. "/" .. tostring(#Pages)
end

local function DisplayButtonInformation(Button)
	local InfoList = TycoonPurchaseMenu.InformationList
	local ReplicatedTycoonPurchases = game.ReplicatedStorage.TycoonPurchases
	local ButtonType = Button:WaitForChild("Type").Value
	
	local OriginalObject
	if ReplicatedTycoonPurchases:FindFirstChild(tostring(ButtonType)) then
		local TypeFile = ReplicatedTycoonPurchases:FindFirstChild(tostring(ButtonType))
		OriginalObject = TypeFile:FindFirstChild(tostring(Button.Object.Value))
	else
		OriginalObject = ReplicatedTycoonPurchases:FindFirstChild(tostring(Button.Object.Value))
	end
	TycoonPurchaseMenu.Object.Text = tostring(Button.Object.Value)
	TycoonPurchaseMenu.Type.Text = tostring(ButtonType)

	local UpgradeCheck = CheckUpgrade(OriginalObject, InfoList)

	local ImprovCharacterCount = string.len(tostring(InfoList.Improvement1.Text))
	InfoList.Improvement1.Size = UDim2.new(0, ImprovCharacterCount * 9, 0, 45) --Change to use scale values over pixels

	InfoList.Description.Text = tostring(Button.Description.Value)
	local DescCharacterCount = string.len(tostring(Button.Description.Value))
	print(DescCharacterCount)
	InfoList.Description.Position = UDim2.new(0.146, 0, InfoList.Improvement1.Position.Y.Scale + 0.086, 0)
	InfoList.Description.Size = UDim2.new(0, 400, 0, DescCharacterCount/1.5)	
end

local press = false
TycoonPurchaseInteract.Event:Connect(function(Button, player)
	local TycoonOwner = Button.Parent.Parent.Owner.Value
	print("CHANGE HOW TYCOON OWNER WORKS LATER SO EXPLOITERS CANNOT CHANGE WORKSPACE VALUES")
	
	if TycoonOwner == player then
		if not Button.Parent.Parent.PurchasedObjects:FindFirstChild(Button.Object.Value) then
			if TycoonPurchaseMenu.Visible == false then
				
				DisplayButtonMaterials(Button)
				DisplayButtonInformation(Button)

				local purchaseButton = TycoonPurchaseMenu.PurchaseButton
				local exitButton = TycoonPurchaseMenu.ExitButton
				TycoonPurchaseMenu.Visible = true
				
				wait(0.4)
				local Pages = CostList:GetChildren()
				if #Pages > 1 then
					PageManager:TweenPosition(UDim2.new(0.722, 0, 0.976, 0), "Out", "Quart", 1)
					ManagePageButtonActive(true, true)
				else
					PageManager.Position = UDim2.new(0.722, 0, PageManager.Position.Y.Scale - 0.150, 0)
					ManagePageButtonActive(false, false)
				end

				purchaseButton.Activated:Connect(function()
					if press == false then
						press = true
						PurchaseObject:FireServer(Button)
						wait(.1) --Wait For PurchaseHandler Money Check to Finish

						if TycoonPurchaseMenu.CashWarning.Visible == false then
							TycoonPurchaseMenu.Visible = false
							wait(1)
							DestroyButtonVisuals(Button)
						end

						press = false
					end
				end)

				exitButton.Activated:Connect(function()
					if press == false and TycoonPurchaseMenu.Visible == true then 
						press = true
						TycoonPurchaseMenu.Visible = false
						DestroyButtonVisuals(Button)
						wait(.1)
						press = false
					end
				end)
			end
		end
	end
end)

local function ManagePageChange(Check, PageNumber1, PageNumber2, CTPos, CPPos, Bounce)
	local CurrentPage = CostList:FindFirstChild("Page" .. tostring(PageManager.CurrentPage.Value))
	local Pages = CostList:GetChildren()

	if #Pages > 1 then	
		local ChangeToPageNumber
		if PageManager.CurrentPage.Value == Check then
			ChangeToPageNumber = PageNumber1
		else
			ChangeToPageNumber = PageNumber2
		end

		PageManager.PageDisplay.PageNumbers.Text = tostring(ChangeToPageNumber) .. "/" .. tostring(#Pages)

		local ChangeToPage = CostList:FindFirstChild("Page" .. tostring(ChangeToPageNumber))
		ChangeToPage.Position = UDim2.new(CTPos, 0, 0, 0)
		ChangeToPage.Visible = true
		CurrentPage:TweenPosition(UDim2.new(CPPos, 0, 0, 0), "Out", "Quint", .5)
		ChangeToPage:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quint", .5)

		wait(.5)
		CurrentPage.Visible = false
		PageManager.CurrentPage.Value = ChangeToPageNumber
	else
		--Bounce effect
		CurrentPage:TweenPosition(UDim2.new(Bounce,0,0,0), "Out", "Quint", .1)
		wait(.1)
		CurrentPage:TweenPosition(UDim2.new(0,0,0,0), "Out" , "Bounce", .25)
		wait(.25)
	end
end

NextPage.Activated:Connect(function()
	ManagePageButtonActive(false)

	local Pages = CostList:GetChildren()
	ManagePageChange(#Pages, 1, PageManager.CurrentPage.Value + 1, 1, -1, 0.03)

	ManagePageButtonActive(true)
end)

PreviousPage.Activated:Connect(function()
	ManagePageButtonActive(false)

	local Pages = CostList:GetChildren()
	ManagePageChange(1, #Pages, PageManager.CurrentPage.Value - 1, -1, 1, -0.03)

	ManagePageButtonActive(true)
end)

