--(LocalScript)
--Mining visuals handler (mining progress bar, denoting selected block, and return to surface button)
-----------------------------------------------------------------------------------------------------------------------------------------------
local Player = game.Players.LocalPlayer
local PlayerCharacterList = workspace:WaitForChild("Players")
local HRP = PlayerCharacterList:WaitForChild(tostring(Player)):WaitForChild("HumanoidRootPart")
print("HumanoidRootPart has been found")

local ItemInteractionGui = script.Parent
local ItemLabel = ItemInteractionGui:WaitForChild("ItemLabel")
local ProgressBar = ItemInteractionGui:WaitForChild("ProgressBarBillboardGui")
local MineshaftItems = game.ReplicatedStorage.ItemLocations.Mineshaft

repeat wait() until workspace.CurrentCamera.SelectedItem ~= nil

local OriginalSelectOreColor = ItemInteractionGui.SelectedOre.Color3

local function CheckSelectedItem()
	if workspace.CurrentCamera.SelectedItem.Value ~= nil then
		
		local Target = workspace.CurrentCamera.SelectedItem.Value
		ItemInteractionGui.SelectedOre.Adornee = Target
		
		local RealOre
		if Target.Name == "Target" then
			RealOre = MineshaftItems:FindFirstChild(Target.Parent.Name)
		else
			RealOre = MineshaftItems:FindFirstChild(Target.Name)
		end
		
		if RealOre then
			ItemLabel.TextColor3 = RealOre.OreColor.Value
			
			local ProgressBarClone = ProgressBar:Clone()
			ProgressBarClone.Parent = Target
			ProgressBarClone.Adornee = Target
			ProgressBarClone.ProgressBar.TimeLeft.BackgroundColor3 = RealOre.OreColor.Value
			
			while Target == workspace.CurrentCamera.SelectedItem.Value do
				wait()
				if Target.Reflectance > 0 then --and Target:FindFirstChild("Owner")
					ProgressBarClone.Enabled = true
					local Progress = Target.Reflectance
					
					--Maybe set it at start to ore color, then switch it to blue when not interacted
					ItemInteractionGui.SelectedOre.Color3 = Color3.new(0.7 - (Progress * 0.7),1,1 - (Progress * 0.7))
					ItemInteractionGui.SelectedOre.SurfaceColor3 = Color3.new(0.7 - (Progress * 0.7),1,1 - (Progress * 0.6))

					ProgressBarClone.ProgressBar.TimeLeft.Size = UDim2.new(Progress,0,1,0)
					--ProgressBar.Parent.Enabled = true
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

local ToSurfaceButton = ItemInteractionGui:WaitForChild("ToSurfaceButton")
local TeleportButton = game:GetService("ReplicatedStorage").Events.GUI:WaitForChild("TeleportButton")

coroutine.resume(coroutine.create(function()
	while wait(0.1) do
		--Maybe change this to a function call to be more efficient? no more while loops, unless in function?
		local RawPosition = game.Players.LocalPlayer.Character.LowerTorso.Position
		local CompactPos = Vector3.new(0 + RawPosition.X/7,(RawPosition.Y - -5)/(-7),RawPosition.Z/7)
		if math.floor(CompactPos.X) > 0 and math.floor(CompactPos.Y) < 1 and math.floor(CompactPos.Z) > 0 then
			ToSurfaceButton.Visible = true
		else
			ToSurfaceButton.Visible = false
		end
	end
end))

local RegionNotifier = ItemInteractionGui.RegionNotifier
local ExclaimRegion = game.ReplicatedStorage.Events.GUI:WaitForChild("ExclaimRegion")
ExclaimRegion.OnClientEvent:Connect(function(Region)
	--coroutine.resume(coroutine.create(function()
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
	--end))
end)

ToSurfaceButton.Activated:Connect(function()
	if ToSurfaceButton.Visible == true then
		TeleportButton:FireServer(ToSurfaceButton)
	end
end)

CheckSelectedItem()
workspace.CurrentCamera.SelectedItem.Changed:connect(CheckSelectedItem)

