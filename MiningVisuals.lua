--(LocalScript)
--Mining visuals handler (mining progress bar, denoting selected block, and return to surface button)
-----------------------------------------------------------------------------------------------------------------------------------------------
local MiningGui = script.Parent
local OreLabel = MiningGui:WaitForChild("OreLabel")
local ProgressBar = script.Parent:WaitForChild("ProgressBarBillboardGui")
local ExclaimRegion = game.ReplicatedStorage.Events.GUI.ExclaimRegion
local MineshaftItems = game.ReplicatedStorage.ItemLocations.Mineshaft

repeat wait() until workspace.CurrentCamera.SelectedItem ~= nil

coroutine.resume(coroutine.create(function()
	while true do
		wait()
		--print(workspace.CurrentCamera.SelectedItem.Value)
		--if workspace.CurrentCamera.SelectedItem.Value then
			--print(workspace.CurrentCamera.SelectedItem.Value.ClassName)
		--end
	end
end))

local OriginalSelectOreColor = script.Parent.SelectedOre.Color3

local function SelectedItem()
	if workspace.CurrentCamera.SelectedItem.Value ~= nil then
		
		local Target = workspace.CurrentCamera.SelectedItem.Value
		
		--(Cannot have mouse.target be meshpart since it's a descendant of targetfiltered part)
		--if SelectedOre:FindFirstChild("MeshPart") then --Works because it's an object value
			--script.Parent.SelectedOre.Adornee = SelectedOre:FindFirstChild("MeshPart")
		--elseif workspace.CurrentCamera.SelectedItem.Value:FindFirstChild("MeshPart") then
			--script.Parent.SelectedOre.Adornee = nil
		--else
			script.Parent.SelectedOre.Adornee = Target
		--end

		--if SelectedOre:IsA("MeshPart") then --Select special shape
			--RealOre = Ores:FindFirstChild(SelectedOre.Parent.Name)
		--elseif SelectedOre:FindFirstChild("MeshPart") then --Special shape, but not looking at it
			--RealOre = nil
		--else --No special shape, select 7x7x7 box
			--RealOre = Ores:FindFirstChild(SelectedOre.Name)
		--end
		
		local RealOre
		if Target.Name == "Target" then
			RealOre = MineshaftItems:FindFirstChild(Target.Parent.Name)
		else
			RealOre = MineshaftItems:FindFirstChild(Target.Name)
		end
		
		if RealOre then
			OreLabel.TextColor3 = RealOre.OreColor.Value

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
					script.Parent.SelectedOre.Color3 = Color3.new(0.7 - (Progress * 0.7),1,1 - (Progress * 0.7))
					script.Parent.SelectedOre.SurfaceColor3 = Color3.new(0.7 - (Progress * 0.7),1,1 - (Progress * 0.6))

					ProgressBarClone.ProgressBar.TimeLeft.Size = UDim2.new(Progress,0,1,0)
					--ProgressBar.Parent.Enabled = true
				elseif Target.Reflectance == 0 then
					wait() --Here to allow for check reflection at 0
					script.Parent.SelectedOre.Color3 = OriginalSelectOreColor
					script.Parent.SelectedOre.SurfaceColor3 = OriginalSelectOreColor
					ProgressBarClone.Enabled = false --disappear when let go
				end
			end
			ProgressBarClone.Enabled = false --disappear when not let go, but look away from block
		end
	end
end

local ToSurfaceButton = script.Parent:WaitForChild("ToSurfaceButton")
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

local RegionNotifier = MiningGui.RegionNotifier
ExclaimRegion.OnClientEvent:Connect(function(Region)
	coroutine.resume(coroutine.create(function()
		repeat wait() until MiningGui.RegionLabel.Text == tostring(Region)
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
	end))
end)


ToSurfaceButton.Activated:Connect(function()
	if ToSurfaceButton.Visible == true then
		TeleportButton:FireServer(ToSurfaceButton)
	end
end)

SelectedItem()
workspace.CurrentCamera.SelectedItem.Changed:connect(SelectedItem)












