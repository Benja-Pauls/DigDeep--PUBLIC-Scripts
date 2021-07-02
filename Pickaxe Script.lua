--(LocalScript)
--Visual handler for mining, alerts other similar scripts
----------------------------------------------------------------------------------------------------------------------------------------------
local Player = game.Players.LocalPlayer
local PlayerCharacterList = workspace:WaitForChild("Players")
local HRP = PlayerCharacterList:WaitForChild(tostring(Player)):WaitForChild("HumanoidRootPart")

local ItemInteractionGui = Player.PlayerGui:WaitForChild("ItemInteractionGui")
local ItemLabel = ItemInteractionGui:WaitForChild("ItemLabel")
local RegionLabel = ItemInteractionGui:WaitForChild("RegionLabel") 
local CoordLabel = ItemInteractionGui:WaitForChild("CoordLabel")
local ToSurfaceButton = ItemInteractionGui:WaitForChild("ToSurfaceButton")
local OriginalSelectOreColor = ItemInteractionGui:WaitForChild("SelectedOre").Color3

ItemLabel.Visible = false
RegionLabel.Visible = false
CoordLabel.Visible = false
ToSurfaceButton.Visible = false

local getEquipmentStats = game.ReplicatedStorage.Events.Utility:WaitForChild("GetItemStats")

local equipType = script.Parent["GUI Info"].EquipType.Value
local itemType = script.Parent["GUI Info"].ItemType.Value
local itemName = tostring(script.Parent)
local toolStats = getEquipmentStats:InvokeServer("Equipment", equipType, itemType, itemName)

local Equipped = false
local Active = false

local function FindStatValue(Table, StatName)
	for item = 1,#Table,1 do
		if Table[item][1] == StatName then
			return Table[item][2]
		end
	end
end

local function SelectOre(Ore)
	if Ore:IsDescendantOf(workspace.Mine) then--and (Ore.Position - script.Parent.Parent.UpperTorso.Position).Magnitude <= 7 then
		if (Ore.Position - HRP.Position).magnitude <= FindStatValue(toolStats["Stats"], "Swing Reach") * 6.3 then
			
			--CONTROLS WHAT MOUSE HAS SELECTED
			if Ore.Name == "Target" then
				--Ore = Ore.Parent:FindFirstChild("MeshPart")
				ItemLabel.Text = Ore.Parent.Name
			else
				ItemLabel.Text = Ore.Name
			end
			workspace.CurrentCamera.SelectedItem.Value = Ore
			script.Parent.SetTarget:InvokeServer(Ore)
			
			if ItemLabel.Visible == false then
				ItemLabel.Visible = true
			end
			
			--Ore color doesn't match no region color
			if Ore.Color ~= game.ReplicatedStorage.ItemLocations.Mineshaft.Stone.Color then
				
				local GUIColor
				local RegionName
				for i,Region in pairs (game.ReplicatedStorage.MineRegions:GetChildren()) do --Get info and check if region exists
					if Region.BlockColor.Value == Ore.Color then
						RegionName = tostring(Region)
						GUIColor = Region["GUI Info"].GUIColor.Value
					end
				end
				
				if GUIColor and RegionName then 
					RegionLabel.Visible = true
					RegionLabel.Text = RegionName
					RegionLabel.TextColor3 = GUIColor
				end
			else
				RegionLabel.Visible = false
			end
		else
			Deactivate()
			Unselect()
			local SelectedOre = ItemInteractionGui.SelectedOre
			SelectedOre.Color3 = OriginalSelectOreColor
			SelectedOre.SurfaceColor3 = OriginalSelectOreColor
		end
	end
end

local UnselectDebounce = false
function Unselect()
	if UnselectDebounce == false then
		--print("Unselecting")
		UnselectDebounce = true
		workspace.CurrentCamera.SelectedItem.Value = nil
		script.Parent.SetTarget:InvokeServer(nil)
		--Selected = false
		ItemInteractionGui:WaitForChild("SelectedOre").Adornee = nil
		ItemLabel.Visible = false
		wait(.5)
		UnselectDebounce = false
	end
end

function Activate()
	if not Active then
		script.Parent.Activation:FireServer(true)
		Active = true
		while Active do
			wait(0.1)
			if workspace.CurrentCamera.SelectedItem.Value == nil then
				break
			end
		end
	end
end

function Deactivate()
	--print("Deactivating")
	script.Parent.Activation:FireServer(false)
	Active = false
end

local function PositionKey(x,y,z) --For coordinates display
	return x..","..y..","..z
end

--USE THIS LATER FOR ANIMATION TRIGGERING
--script.Parent.IsMining.Changed:Connect(function()
	--workspace.CurrentCamera.SelectedItem.Mining.Value = script.Parent.IsMining.Value
--end)
--workspace.CurrentCamera.SelectedItem.Mining.Value = script.Parent.IsMining.Value

local TeleportButton = game.ReplicatedStorage.Events.GUI:WaitForChild("TeleportButton")

script.Parent.Equipped:Connect(function(Mouse)
	Equipped = true
	Mouse = game.Players.LocalPlayer:GetMouse()
	
	while script.Parent.Enabled and script.Parent.Parent:FindFirstChild("Humanoid") do
		wait()
		local Ore
		if game:GetService("UserInputService").MouseEnabled then
			Ore = Mouse.Target
			if Ore and Equipped == true then
				if Ore.Name == "GenerationPosition" then
					Mouse.TargetFilter = Ore
					Ore.Size = Vector3.new(0.01,0.01,0.01) --Cannot delete, used for positional reference
					Ore = Ore.Parent:FindFirstChild("Target")
				end
				if Ore:IsDescendantOf(game.workspace.Mine) then --if item has Selectable string value, associated type with string value
					SelectOre(Ore)
					--print(tostring(Ore) .. " has been selected")
				else
					Unselect()
					if ItemLabel.Visible == true then
						ItemLabel.Visible = false
					end
				end
			else
				if ItemLabel.Visible == true then
					ItemLabel.Visible = false
				end
			end
		end
		
		local CompactPos = Vector3.new(0 + HRP.Position.X/7,(HRP.Position.Y - -5)/(-7),HRP.Position.Z/7)	
		--local RawPosition = game.Players.LocalPlayer.Character.LowerTorso.Position
		
		if -math.floor(CompactPos.Y) < 1 then
			ToSurfaceButton.Visible = true
			CoordLabel.Visible = true
			CoordLabel.Text = tostring(math.floor(CompactPos.Y)) .. " Meters"
		else
			ToSurfaceButton.Visible = false
			CoordLabel.Visible = false
		end
	end
	
	ToSurfaceButton.Visible = false
	CoordLabel.Visible = false
end)

local Mouse = game.Players.LocalPlayer:GetMouse()
Mouse.Button1Down:connect(function()
	if Equipped and game:GetService("UserInputService").MouseEnabled then
		Activate()
	end
end)

Mouse.Button1Up:connect(function()
	if Equipped and game:GetService("UserInputService").MouseEnabled then
		Deactivate()
	end
end)

script.Parent.Unequipped:Connect(function()
	Equipped = false
	Mouse.TargetFilter = nil
	CoordLabel.Visible = false
	Deactivate()
	Unselect()
end)

ToSurfaceButton.Activated:Connect(function()
	if ToSurfaceButton.Visible == true then
		TeleportButton:FireServer(ToSurfaceButton)
	end
end)

