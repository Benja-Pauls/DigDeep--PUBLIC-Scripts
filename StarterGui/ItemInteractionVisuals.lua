--(LocalScript)
--Mining visuals handler (mining progress bar, denoting selected block, and return to surface button)
-----------------------------------------------------------------------------------------------------------------------------------------------
local Player = game.Players.LocalPlayer
local PlayerCharacterList = workspace:WaitForChild("Players")
local HRP = PlayerCharacterList:WaitForChild(tostring(Player)):WaitForChild("HumanoidRootPart")

local ItemInteractionGui = script.Parent
local ItemLabel = ItemInteractionGui:WaitForChild("ItemLabel")
local ProgressBar = ItemInteractionGui:WaitForChild("ProgressBarBillboardGui")
local inventoryItems = game.ReplicatedStorage.InventoryItems

local MoveAllBaseScreenUI = game.ReplicatedStorage.Events.GUI:WaitForChild("MoveAllBaseScreenUI")
local ToSurfaceButton = script.Parent:WaitForChild("ToSurfaceButton")
ToSurfaceButton.Visible = false

MoveAllBaseScreenUI.Event:Connect(function(ChangeTo)
	if ChangeTo == "Hide" then
		ToSurfaceButton:TweenPosition(UDim2.new(-.15, 0, ToSurfaceButton.Position.Y.Scale, 0), "Out", "Quint", 1)
	else
		ToSurfaceButton:TweenPosition(UDim2.new(0.01, 0, ToSurfaceButton.Position.Y.Scale, 0), "Out", "Quint", 1)
	end
end)


repeat wait() until workspace.CurrentCamera.SelectedItem ~= nil

local OriginalSelectOreColor = ItemInteractionGui.SelectedOre.Color3

local function CheckSelectedItem()
	if workspace.CurrentCamera.SelectedItem.Value ~= nil then
		
		local Target = workspace.CurrentCamera.SelectedItem.Value
		ItemInteractionGui.SelectedOre.Adornee = Target
		
		local itemInfo
		for _,itemType in pairs (inventoryItems:GetChildren()) do
			if itemType:FindFirstChild(Target.Parent.Name) or itemType:FindFirstChild(Target.Name) then
				if Target.Name == "Target" then
					itemInfo = itemType:FindFirstChild(Target.Parent.Name)
				else
					itemInfo = itemType:FindFirstChild(Target.Name)
				end
			end
		end
		
		if itemInfo then
			ItemLabel.TextColor3 = itemInfo["GUI Info"].OreColor.Value
			
			local ProgressBarClone = ProgressBar:Clone()
			ProgressBarClone.Parent = Target
			ProgressBarClone.Adornee = Target
			ProgressBarClone.ProgressBar.TimeLeft.BackgroundColor3 = itemInfo["GUI Info"].OreColor.Value
			
			while Target == workspace.CurrentCamera.SelectedItem.Value do
				wait()
				if Target.Reflectance > 0 then --and Target:FindFirstChild("Owner")
					ProgressBarClone.Enabled = true
					local Progress = Target.Reflectance
					
					--Maybe set it at start to ore color, then switch it to blue when not interacted
					ItemInteractionGui.SelectedOre.Color3 = Color3.new(0.7 - (Progress * 0.7),1,1 - (Progress * 0.7))
					ItemInteractionGui.SelectedOre.SurfaceColor3 = Color3.new(0.7 - (Progress * 0.7),1,1 - (Progress * 0.6))

					ProgressBarClone.ProgressBar.TimeLeft.Size = UDim2.new(Progress,0,1,0)
					
					--local hit = 
					--if hit.Value == true then
						--Change this so it creates a particle along with the animation that is played
						--Probably have a bool value in the tool called "hit" that is true when particles should
						--fly off of the mined block (drill would be constant, but pic wouldn't)
					--end
				elseif Target.Reflectance == 0 then
					wait() --Here to allow for check reflection at 0
					ItemInteractionGui.SelectedOre.Color3 = OriginalSelectOreColor
					ItemInteractionGui.SelectedOre.SurfaceColor3 = OriginalSelectOreColor
					ProgressBarClone.Enabled = false --disappear when let go
				end
			end
			ProgressBarClone.Enabled = false --disappear when not let go, but look away from block
		end
	end
end


------------------------<|GUI Management|>-----------------------------------------------------------------------------------------------------------------------------

local RegionNotifier = ItemInteractionGui.RegionNotifier
local ExclaimRegion = game.ReplicatedStorage.Events.GUI:WaitForChild("ExclaimRegion")
ExclaimRegion.OnClientEvent:Connect(function(Region)
	repeat wait() until ItemInteractionGui.RegionLabel.Text == tostring(Region)
	
	RegionNotifier.TextColor3 = Region["GUI Info"].GUIColor.Value
	RegionNotifier.Text = tostring(Region)
	RegionNotifier.TextTransparency = 1
	RegionNotifier.Visible = true
		
	for t = 1,20,1 do --fade in
		wait(.02)
		RegionNotifier.TextTransparency = RegionNotifier.TextTransparency - 0.05
	end
	wait(3)
	for t = 1,20,1 do --fade out
		wait(.02)
		RegionNotifier.TextTransparency = RegionNotifier.TextTransparency + 0.05
	end
		
	RegionNotifier.TextTransparency = 1
	RegionNotifier.Visible = false
end)

CheckSelectedItem()
workspace.CurrentCamera.SelectedItem.Changed:connect(CheckSelectedItem)

