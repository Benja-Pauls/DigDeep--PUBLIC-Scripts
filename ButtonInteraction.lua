--(LocalScript)
--GUI handler for purchases around the tycoon (still refered to as buttons)
------------------------------------------------------------------------------------------------------------------------------------------------
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)
wait(1)

local Player = game.Players.LocalPlayer
local Tycoons = workspace["Tycoon Game"]:WaitForChild("Tycoons") 
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HumanoidRootPart = game.Workspace.Players:WaitForChild(tostring(Player)):WaitForChild("HumanoidRootPart")
local Mouse = Player:GetMouse()
local PurchaseObject = ReplicatedStorage.Events.Utility.PurchaseObject
local LocalLoadTycoon = ReplicatedStorage.Events.Tycoon:WaitForChild("LocalLoadTycoon")
local UIS = game:GetService("UserInputService")

local Menu = script.Parent.Menu
local ButtonGui = script:WaitForChild("ButtonGUI")

script.Parent.IgnoreGuiInset = true

if LocalLoadTycoon then
	print("Local Load Tycoon Event has been found")
end

LocalLoadTycoon.OnClientEvent:Connect(function(tycoon)
	print("LocalLoadTycoon event has been fired")
	local Buttons = tycoon.Buttons:GetChildren()
	for i,button in pairs (Buttons) do
		ButtonGui:Clone().Parent = button
	end
	
	EInteract(tycoon)
 end)

local function GetStatImage(File, Stat)
	local ImageId
	if Stat.Name then
		ImageId = game.ReplicatedStorage:FindFirstChild(tostring(File)):FindFirstChild(Stat.Name)["GUI Info"].StatImage.Value
	else
		ImageId = game.ReplicatedStorage:FindFirstChild(tostring(File)):FindFirstChild(Stat)["GUI Info"].StatImage.Value
	end
	return ImageId
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

local function DisplayButtonMaterials(Button)
	local CostList = Menu.CostsList
	local Slots
	local OriginalSlot = game.ReplicatedStorage.GuiElements:FindFirstChild("TycoonPurchaseMaterialSlot")
	
	local MoneySlot = OriginalSlot:Clone()
	MoneySlot.Parent = CostList
	MoneySlot.Position = UDim2.new(0.064, 0, 0.02, 0)
	MoneySlot.Amount.Text = tostring(Button.Price.Value)
	MoneySlot.DisplayName.Text = "Cash"
	MoneySlot.Picture.Image = "rbxgameasset://Images/Money1"
	Slots = CostList:GetChildren()	
	MoneySlot.Name = "Slot" .. tostring(#Slots)
	
	if Button:FindFirstChild("MaterialPrice") ~= nil then
		local MaterialFiles = Button.MaterialPrice:GetChildren()
		for i,file in pairs(MaterialFiles) do
			for i,material in pairs (file:GetChildren()) do
				Slots = CostList:GetChildren()
				local NewSlot = OriginalSlot:Clone()
				NewSlot.Parent = CostList
				NewSlot.Name = "Slot" .. tostring(#Slots + 1)
				NewSlot.DisplayName.Text = tostring(material)
				NewSlot.Amount.Text = tostring(material.Value)
				
				if CostList:FindFirstChild("Slot" .. tostring(#Slots)) then
					local PrevSlot = CostList:FindFirstChild("Slot" .. tostring(#Slots))
					local PrevSlotX = PrevSlot.Position.X.Scale
					local PrevSlotY = PrevSlot.Position.Y.Scale
					NewSlot.Position = UDim2.new(PrevSlotX, 0, PrevSlotY + 0.08, 0)
				end
				
				local ImageId = GetStatImage(file, material)
				NewSlot.Picture.Image = ImageId
			end
		end
	end	
end

local function DisplayInformation(Button)
	local InfoList = Menu.InformationList
	local ReplicatedTycoonPurchases = game.ReplicatedStorage.TycoonPurchases
	local ButtonType = Button:WaitForChild("Type").Value
	local OriginalObject
	if ReplicatedTycoonPurchases:FindFirstChild(tostring(ButtonType)) then
		local TypeFile = ReplicatedTycoonPurchases:FindFirstChild(tostring(ButtonType))
		OriginalObject = TypeFile:FindFirstChild(tostring(Button.Object.Value))
	else
		OriginalObject = ReplicatedTycoonPurchases:FindFirstChild(tostring(Button.Object.Value))
	end
	Menu.Object.Text = tostring(Button.Object.Value)
	Menu.Type.Text = tostring(ButtonType)
	
	local UpgradeCheck = CheckUpgrade(OriginalObject, InfoList)
	
	--Maybe make rarity a calculated value from price and other variables, or just name each?
	
	local ImprovCharacterCount = string.len(tostring(InfoList.Improvement1.Text))
	InfoList.Improvement1.Size = UDim2.new(0, ImprovCharacterCount * 9, 0, 45)
	
	
	InfoList.Description.Text = tostring(Button.Description.Value)
	local DescCharacterCount = string.len(tostring(Button.Description.Value))
	print(DescCharacterCount)
	InfoList.Description.Position = UDim2.new(0.146, 0, InfoList.Improvement1.Position.Y.Scale + 0.043, 0)
	InfoList.Description.Size = UDim2.new(0, 400, 0, DescCharacterCount/1.5)	
end

local function DestroyButtonVisuals(Button)
	local CostList = Menu.CostsList
	local InfoList = Menu.InformationList
	
	for i,visual in pairs(CostList:GetChildren()) do
		visual:Destroy()
	end
	
	--for i,visual in pairs(InfoList:GetChildren()) do --No tracked parts / changing parts yet
		--visual:Destroy()
	--end	
end

local press = false

function EInteract(PlayerTycoon)
	print("EInteract has been called")
	UIS.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.E then	
			if Mouse.Target and (Mouse.Target.Position - HumanoidRootPart.Position).magnitude < 20 then
				local Button = Mouse.Target
				if Button:FindFirstChild("Price") ~= nil and Button.Parent == PlayerTycoon.Buttons then
					if Menu.Visible == false and Button.Visible.Value == true then
						
						DisplayButtonMaterials(Button)
						DisplayInformation(Button)
						
						local purchaseButton = Menu.PurchaseButton
						local exitButton = Menu.ExitButton
						Menu.Visible = true
						
						purchaseButton.Activated:Connect(function()
							if press == false then
								--EFFICIENCY NOTE: it still runs through
								--every button thats been interacted with in the current session
								press = true
								PurchaseObject:FireServer(Button)
								wait(.1) --Wait For PurchaseHandler Money Check to Finish
								
								if Menu.CashWarning.Visible == false then
									Menu.Visible = false
									wait(1)
									DestroyButtonVisuals(Button)
									--Should set Mouse.Target to nil?
								end
								
								press = false
							end
						end)
						
						exitButton.Activated:Connect(function()
							if press == false and Menu.Visible == true then 
								press = true
								Menu.Visible = false
								DestroyButtonVisuals(Button)
								wait(.1)
								press = false
							end
						end)
					end
				end
			end
		end
	end)
			
	local debounce = false
	
	--Mouse.Target.Changed:Connect(function(target)
	
	--Graphical (Again, is there a way to make this more efficient?)
	while PlayerTycoon.Owner.Value == Player do --Way to make while loop more efficient?
		wait(.1)
		if Mouse.Target then
			for i,v in pairs (PlayerTycoon.Buttons:GetChildren()) do
				if Mouse.Target == v and (Mouse.Target.Position - HumanoidRootPart.Position).magnitude < 20 then 
					if debounce == false and v.CanCollide == true then
						debounce = true
						v:WaitForChild("ButtonGUI").Enabled = true
					end
				else
					if debounce == true and v:WaitForChild("ButtonGUI").Enabled == true then
						v:WaitForChild("ButtonGUI").Enabled = false
						debounce = false
					end
				end
			end
		end
	end
end
