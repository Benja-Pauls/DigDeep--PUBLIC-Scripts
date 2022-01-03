--(LocalScript)
--GUI handler for everything the player interacts with using DisplayButtonGUIs
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

wait(5) --**change this later to add to the loading screen that the game is still loading assets
--all assets that player can interact with will probably have to be loaded before the player can begin playing and utilizing this script

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ProximityPromptService = game:GetService("ProximityPromptService")

local UIS = game:GetService("UserInputService")
local DisplayButtonGui = script:WaitForChild("DisplayButtonGUI")

local LocalLoadTycoon = game.ReplicatedStorage.Events.Tycoon:WaitForChild("LocalLoadTycoon")

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

LocalLoadTycoon.OnClientEvent:Connect(function(tycoon)
	local Buttons = tycoon.Buttons:GetChildren()
	for i,button in pairs (Buttons) do
		local ProxPrompt = DisplayButtonGui:Clone()

		ProxPrompt:SetAttribute("InteractType", "TycoonPurchase")
		ProxPrompt.ActionText = "View Blueprint"
		ProxPrompt.ObjectText = button.Object.Value
		ProxPrompt.Parent = button

		button.DisplayButtonGUI.Enabled = button.Visible.Value

		button.Visible.Changed:Connect(function() --Only display ProxPrompt when button is visible
			button.DisplayButtonGUI.Enabled = button.Visible.Value
			--Since the ProximityPrompt is placed by the local script, no other player will see other players' prompts
			--(so no need to check if proxprompt object is within player's owned tycoon
		end)
	end
end)

---------------------------------------<|High-Traffic Functions|>--------------------------------------------------------------------------------------------

ProximityPromptService.PromptTriggered:Connect(function(promptObject, player)
	local interactType = promptObject:GetAttribute("InteractType")
	local interactEvent = game.ReplicatedStorage.Events.HotKeyInteract:FindFirstChild(interactType .. "Interact")
	
	if interactType == "TycoonPurchase" then
		interactEvent:Fire(promptObject.Parent, player)
	else
		if interactEvent:IsA("BindableEvent") then
			interactEvent:Fire(promptObject)
		elseif interactEvent:IsA("RemoteEvent") then
			local AssociatedObject = promptObject.AssociatedObject.Value
			interactEvent:FireServer(AssociatedObject)
		end
	end
	
	
	
	--Later types may include opening a door or interacting with another player to friend, trade, etc
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

