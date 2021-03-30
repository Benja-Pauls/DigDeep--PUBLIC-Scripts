--(LocalScript)
--GUI handler for purchases around the tycoon (still refered to as buttons)
------------------------------------------------------------------------------------------------------------------------------------------------
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)
wait(1)

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Tycoons = workspace:WaitForChild("Tycoons") 
local ProximityPromptService = game:GetService("ProximityPromptService")

local HumanoidRootPart = game.Workspace.Players:WaitForChild(tostring(Player)):WaitForChild("HumanoidRootPart")
local Mouse = Player:GetMouse()
local PurchaseObject = game.ReplicatedStorage.Events.Utility.PurchaseObject
local LocalLoadTycoon = game.ReplicatedStorage.Events.Tycoon:WaitForChild("LocalLoadTycoon")
local UIS = game:GetService("UserInputService")

local TycoonPurchaseMenu = script.Parent.TycoonPurchaseMenu
local DisplayButtonGui = script:WaitForChild("DisplayButtonGUI")

script.Parent.IgnoreGuiInset = true

----------------------------------------------<|Utility|>---------------------------------------------------------------------------------------------------

local function PrepInteractables()
	for i,storage in pairs (workspace.Storages.Computers:GetChildren()) do
		local ProxPrompt = script.DisplayButtonGUI:Clone()
		
		ProxPrompt:SetAttribute("InteractType", "Storage")
		ProxPrompt.HoldDuration = 1
		ProxPrompt.RequiresLineOfSight = false
		ProxPrompt.ObjectText = tostring(Player) .. "'s Computer"
		ProxPrompt.ActionText = "Open Storage"
		ProxPrompt.Parent = storage.InteractedModel.Main
	end
	
	for i,deposit in pairs (workspace.Storages.Deposits:GetChildren()) do
		local ProxPrompt = script.DisplayButtonGUI:Clone()
		
		ProxPrompt:SetAttribute("InteractType", "Deposit")
		ProxPrompt.MaxActivationDistance = 7
		ProxPrompt.KeyboardKeyCode = Enum.KeyCode.R
		ProxPrompt.ActionText = "Deposit Items"
		ProxPrompt.Parent = deposit.InteractedModel.Main
	end
	
	for i,NPC in pairs (workspace.NPCs:GetChildren()) do
		local ProxPrompt = script.DisplayButtonGUI:Clone()
		
		local AssociatedObject = Instance.new("ObjectValue", ProxPrompt)
		AssociatedObject.Name = "AssociatedObject"
		AssociatedObject.Value = NPC
		
		ProxPrompt:SetAttribute("InteractType", NPC["NPC Type"].Value)
		ProxPrompt.RequiresLineOfSight = false
		ProxPrompt.ActionText = "Talk With " .. tostring(NPC)
		ProxPrompt.ObjectText = NPC.Job.Value
		ProxPrompt.Parent = NPC.ProxPromptAttach
	end
end

local function GetProxPromptGui()
	local screenGui = PlayerGui:FindFirstChild("ProximityPrompts")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ProximityPrompts"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = PlayerGui
	end
	return screenGui
end

local function GetStatImage(File, Stat)
	local ImageId
	
	print(File, Stat)
	
	if Stat then
		for i,location in pairs (game.ReplicatedStorage.ItemLocations:GetChildren()) do
			if location:FindFirstChild(tostring(Stat)) and ImageId == nil then
				ImageId = location:FindFirstChild(tostring(Stat))["GUI Info"].StatImage.Value
			end
		end
	--else
		--ImageId = game.ReplicatedStorage:FindFirstChild(tostring(File)):FindFirstChild(Stat)["GUI Info"].StatImage.Value
	end
	return ImageId
end

----------------------------------------------<|Tycoon-Related Functions|>-----------------------------------------------------------------------------------

LocalLoadTycoon.OnClientEvent:Connect(function(tycoon)
	local Buttons = tycoon.Buttons:GetChildren()
	for i,button in pairs (Buttons) do
		local ProxPrompt = DisplayButtonGui:Clone()
		
		ProxPrompt:SetAttribute("InteractType", "TycoonPurchase")
		ProxPrompt.ActionText = "View Blueprint"
		ProxPrompt.ObjectText = button.Object.Value
		ProxPrompt.Parent = button
		
		button.Visible.Changed:Connect(function() --Only display ProxPrompt when button is visible
			button.DisplayButtonGUI.Enabled = button.Visible.Value
			--Since the ProximityPrompt is placed by the local script, no other player will see other players' prompts
			--(so no need to check if proxprompt object is within player's owned tycoon
		end)
	end
 end)

local function CheckUpgrade(OriginalObject, InfoList)
	if OriginalObject:FindFirstChild("UpgradeLevel") then
		InfoList.Upgrade.Status.Image = "rbxgameasset://Images/greencheck1"
		return true
	else
		InfoList.Upgrade.Status.Image = "rbxgameasset://Images/redx1"
		return false
	end
end

local CostList = TycoonPurchaseMenu.CostsList
local function DisplayButtonMaterials(Button)
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
	InfoList.Description.Position = UDim2.new(0.146, 0, InfoList.Improvement1.Position.Y.Scale + 0.043, 0)
	InfoList.Description.Size = UDim2.new(0, 400, 0, DescCharacterCount/1.5)	
end

local function DestroyButtonVisuals(Button)
	local InfoList = TycoonPurchaseMenu.InformationList
	
	for i,visual in pairs(CostList:GetChildren()) do
		visual:Destroy()
	end
end

local press = false
local function TycoonPurchaseInteract(Button, player)
	local TycoonOwner = Button.Parent.Parent.Owner.Value
	if TycoonOwner == player then
		if Button.Parent.Parent.PurchasedObjects:FindFirstChild(Button.Object.Value) then
			if TycoonPurchaseMenu.Visible == false then
				DisplayButtonMaterials(Button)
				DisplayButtonInformation(Button)

				local purchaseButton = TycoonPurchaseMenu.PurchaseButton
				local exitButton = TycoonPurchaseMenu.ExitButton
				TycoonPurchaseMenu.Visible = true

				purchaseButton.Activated:Connect(function()
					if press == false then
						--EFFICIENCY NOTE: it still runs through
						--every button thats been interacted with in the current session
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
end

---------------------------------------<|High-Traffic Functions|>--------------------------------------------------------------------------------------------

ProximityPromptService.PromptTriggered:Connect(function(promptObject, player)
	
	local InteractType = promptObject:GetAttribute("InteractType")
	
	if InteractType == "TycoonPurchase" then
		TycoonPurchaseInteract(promptObject.Parent, player)
	else
		local InteractEvent = game.ReplicatedStorage.Events.HotKeyInteract:FindFirstChild(InteractType .. "Interact")
		
		if InteractEvent:IsA("BindableEvent") then
			print("Firing event " .. tostring(InteractEvent))
			InteractEvent:Fire(promptObject)
		elseif InteractEvent:IsA("RemoteEvent") then
			local AssociatedObject = promptObject.AssociatedObject.Value
			InteractEvent:FireServer(AssociatedObject)
		end
	end
	
	
	
	--Later types may include opening a door or interacting with another player
end)

--For custom proximity prompt GUIs
--[[
ProximityPromptService.PromptShown:Connect(function(promptObject, player)
	if promptObject.Style == Enum.ProximityPromptStyle.Default then
		return
	end
	
	local InteractType = promptObject:GetAttribute("InteractType")
	local InteractType = script:FindFirstChild(InteractType)
	
	local ProxPromptGui = GetProxPromptGui()
	
	
	--Check type to grab appropriate prompt gui in replicated storage
	
	--Add appropriate details to cloned prompt 
	
	--Parent and Adornee cloned prompt to object
	
	--Tween prompt appropriately for opening
	
	
	promptObject.PromptHidden:Wait()
	
	--CleanupPrompt()
	--Tween prompt appriopriately for closing
	--Destroy prompt
end)
]]

PrepInteractables()

