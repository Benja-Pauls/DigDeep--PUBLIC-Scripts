--(Script)
--Handles mining, mine generation, and ore generation after ore is mined (generates a new block around mined block that were previously nothing)

------------------------------------------------------------------------------------------------------------------------------------------------
local PlayerStatManager = require(game.ServerScriptService:WaitForChild("PlayerStatManager"))
local PlayerData = game.ServerStorage:WaitForChild("PlayerData")
local TeleportButton = game.ReplicatedStorage.Events.GUI:WaitForChild("TeleportButton")

--Put pickaxe functionality scripts in pickaxes
local PickServer = script:FindFirstChild("PickServer")
local PickaxeScript = script:FindFirstChild("Pickaxe Script")
for i,pickaxe in pairs (game.ReplicatedStorage.Equippable.Tools.Pickaxes:GetChildren()) do
	local PickServerClone = PickServer:Clone()
	local PickaxeScriptClone = PickaxeScript:Clone()
	
	PickServerClone.Parent = pickaxe
	PickServerClone.Disabled = false
	PickaxeScriptClone.Parent = pickaxe
	PickaxeScriptClone.Disabled = false
end

--------------<|Utility Functions|>-------------------------------------------------------------------------------------------
local Utility = require(game.ServerScriptService.Utility)
	
local function FillObjectTables(folder, IsA, Table) --Folder Read Setup
	for _,item in pairs(folder) do
		if item:IsA(IsA) or item:IsA("Model") then 
			table.insert(Table, item)
		end
	end
end

local function ApplyOffsets(target, offsetName)
	if target:FindFirstChild(offsetName) then
		local offset = target:FindFirstChild(offsetName).Value
		local x = offset.X
		local y = offset.Y
		local z = offset.Z
		
		if offsetName == "Pos Offset" then
			target.Position = target.Position + Vector3.new(x,y,z)
			
			for _,childPart in pairs(target:GetChildren()) do
				if childPart:IsA("MeshPart") or childPart:IsA("Part") then
					childPart.Position = childPart.Position + Vector3.new(x,y,z)
				end
			end
			
		elseif offsetName == "Rot Offset" then
			target.Parent:SetPrimaryPartCFrame(target.Parent:GetPrimaryPartCFrame()*CFrame.fromEulerAnglesXYZ(math.pi*x,math.pi*y,math.pi*z))
		end
	end
end


local Ores = {}
local Regions = {}

local miningItemInfo = game.ReplicatedStorage.InventoryItems.Mining:GetChildren()
local foragingItemInfo = game.ReplicatedStorage.InventoryItems.Foraging:GetChildren()
local OriginalRegions = game.ReplicatedStorage.MineRegions:GetChildren()

FillObjectTables(miningItemInfo, "BasePart", Ores)
FillObjectTables(foragingItemInfo, "BasePart", Ores)
FillObjectTables(OriginalRegions, "Folder", Regions)


local function GetObjectFromId(Object,Id)
	return Object[Id]
end

local function InsertIntoTable(Chance, Table, Index) --Put into Utility script
	for i=1,Chance do
		table.insert(Table,Index)
	end
end

local UsedPositions = {} --Used cave block positions table

local function PositionKey(x,y,z)
	return x..","..y..","..z
end

local function CalculateInterferingY(Bounds, y, Mining, sourceBlockDist)
	local Y

	if Mining then --breaking structures if "source" block broken (mining)
		Y = y+sourceBlockDist 
	else --Structures checking for structures already present(generation)
		if Bounds == "BlockAbove" or Bounds == "Block2Below" then
			Y = y+1 --below source block
		else
			Y = y-1 --above source block
		end
	end

	return Y
end

--------------------

local function NoiseAcceptable(BoundsName, sourceBlockDist, Noise, x, y, z, Ceiling, Min, Mining)
	--If selected block is within noise bounds
	local Bounds
	local NoiseBool
	local NoiseCheck = Noise >= 0.48 or Noise <= -0.48

	if not NoiseCheck and not Ceiling then
		NoiseBool = true
		--print("IF: ", BoundsName)
	elseif Ceiling then --ceiling structure (need to check if at top already)
		--print("ELSEIF: ", BoundsName)
		if not NoiseCheck or (y-1)<Ceiling then
			if Min then --multi-block
				if Mining then
					if y > (Min - 2) then
						NoiseBool = true
					end
				elseif y > Min then
					NoiseBool = true
				end
			else
				NoiseBool = true
			end
		end
	end
	
	--Check Structure Positioning
	if NoiseBool then 
		if not Mining then
			Bounds = true
		else --Possibly mining block near a structure
			local Y = CalculateInterferingY(BoundsName, y, Mining, sourceBlockDist)
			local SelectedBlock = UsedPositions[PositionKey(x,Y,z)]
			if SelectedBlock ~= nil and SelectedBlock ~= false then --exists and not air
				if SelectedBlock:FindFirstChild("SpecialStructure") then
					Bounds = true
				end
			end
		end
	end
	
	return Bounds
end

local calcNoiseCount = 0
local function CalculateNoise(x,y,z,Mining)
	calcNoiseCount = calcNoiseCount + 1
	local Bounds
	local sourceBlockDist
	
	local BelowNoise = math.noise(x/25, (y+1)/15, z/25)
	local TwoBelowNoise = math.noise(x/25, (y+2)/15, z/25)
	if NoiseAcceptable("BlockBelow", -1, BelowNoise, x, y, z, nil, nil, Mining) then
		--print("BlockBelow")
		Bounds = "BlockBelow"
		sourceBlockDist = -1
		--print("TRIAL " .. tostring(calcNoiseCount) .. ": BlockBelow")
	end
	
	if Bounds ~= "BlockBelow" then
		if NoiseAcceptable("Block2Below", -2, TwoBelowNoise, x, y, z, nil, 3, Mining) then
			--print("Block2Below")
			Bounds = "Block2Below"
			sourceBlockDist = -2
			--print("TRIAL " .. tostring(calcNoiseCount) .. ": Block2Below")
		end
	end
	
	local AboveNoise = math.noise(x/25, (y-1)/15, z/25)
	local TwoAboveNoise = math.noise(x/25, (y-2)/15, z/25)
	if NoiseAcceptable("BlockAbove", 1, AboveNoise, x, y, z, 3, nil, Mining) then
		
		local gamble = 0
		if Bounds == "BlockBelow" then
			gamble = math.random(1,2)
		end
		
		if gamble == 2 then
			--print("BlockAbove")
			Bounds = "BlockAbove"
			sourceBlockDist = 1
		else
			--print("BlockBelow again")
		end
		--print("TRIAL " .. tostring(calcNoiseCount) .. ": BlockAbove")
	end
	
	if Bounds ~= "BlockAbove" and Bounds ~= "BlockBelow" then
		if NoiseAcceptable("Block2Above", 2, TwoAboveNoise, x, y, z, 4, 3, Mining) then
			--print("Block2Above")
			Bounds = "Block2Above"
			sourceBlockDist = 2
			--print("TRIAL " .. tostring(calcNoiseCount) .. ": Block2Above")
		end
	end
	
	--print("----------------------------------------")

	return Bounds, sourceBlockDist
end

TeleportButton.OnServerEvent:Connect(function(player, button)
	local PlayersFolder = workspace:FindFirstChild("Players")
	if PlayersFolder:FindFirstChild(tostring(player)) ~= nil then
		if button.Name == "ToSurfaceButton" then
			local Player = PlayersFolder:FindFirstChild(tostring(player))
			Player.LowerTorso.CFrame = workspace.SpawnLocation.CFrame
		end
	end
end)

local function CalculateChance(y,Selection)
	local MaxDepth, MinDepth = (Selection.MaxDepth.Value > 0 and Selection.MaxDepth.Value) or 9999, (Selection.MinDepth.Value > 0 and Selection.MinDepth.Value) or 1
	local Range = MaxDepth - MinDepth + 1
	local MinDistance = y - MinDepth + 1
	local MaxDistance = MaxDepth - y + 1
	local MaxRarity, MinRarity = Selection.MaxRarity.Value, Selection.MinRarity.Value

	--math.ceil means round up
	local Chance = math.ceil(((MinDistance/Range) * MinRarity + (MaxDistance/Range) * MaxRarity) / 2)
	if y >= MinDepth and y <= MaxDepth then
		return Chance
	end
end

local function DecideSelection(y, Table, RegionSpecific)
	
	local Lottery = {}
	
	for Index,Selection in pairs(Table) do
		if not Selection:FindFirstChild("SpecialStructure") then
			local Chance = CalculateChance(y,Selection)

			if Chance ~= nil then
				if not RegionSpecific then --Ore generated is NOT in region
					if not Selection:FindFirstChild("RegionSpecial") then
						InsertIntoTable(Chance,Lottery,Index)
					end
					
				else --Ore generated is in region
					if Selection:FindFirstChild("RegionSpecial") then
						if Selection.RegionSpecial.Value == tostring(RegionSpecific) then
							InsertIntoTable(Chance,Lottery,Index)
						end
					else
						if Selection.Name ~= "Stone" then
							Chance = math.ceil(Chance/50) --Non-region ores, other than stone, are less likely to spawn in regions
						end
						InsertIntoTable(Chance,Lottery,Index)
					end
				end				
			end
		end
	end
	
	local Id = Lottery[math.random(1,#Lottery)]
	
	--print(GetObjectFromId(Table,Id))
	
	return GetObjectFromId(Table,Id)
end

local function SpawnStructures(x,y,z,Bounds,Region,sourceBlockDist)
	
	local Lottery = {}
	
	--Randomly select region structures with bounds met, then put into roulette for spawning
	for i,item in pairs (Ores) do
		if item:FindFirstChild("SpecialStructure") and item:FindFirstChild("RegionSpecial").Value == tostring(Region) then
			if item.SpecialStructure.Value == tostring(Bounds) then
				local Chance = CalculateChance(y,item)
				InsertIntoTable(Chance,Lottery,i)
			end
		end
	end
	
	if #Lottery > 0 then --if something can spawn
		local Id = Lottery[math.random(1,#Lottery)]
		local FinalSelection = GetObjectFromId(Ores,Id)
					
		local SpawnChance = math.random(1,FinalSelection.MaxRarity.Value)

		if SpawnChance <= FinalSelection.MaxRarity.Value/FinalSelection["1/SpawnChance"].Value then 
			local Structure = FinalSelection:Clone()
			UsedPositions[PositionKey(x,y,z)] = Structure

			Structure.Parent = workspace.Mine
			
			if Structure:IsA("Model") then
				Structure:SetPrimaryPartCFrame(CFrame.new(0+x*7, -5+y*(-7), 0+z*7))
			else
				Structure.CFrame = CFrame.new(0+x*7, -5+y*(-7), 0+z*7)
			end

			if Structure:FindFirstChild("Target") then	
				local target = Structure.Target
				
				ApplyOffsets(target, "Rot Offset")
				ApplyOffsets(target, "Pos Offset")
				
				--How to get lookvector for rotation?
				--local r = math.random(1,3)
				--Structure:SetPrimaryPartCFrame(Structure:GetPrimaryPartCFrame() * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(90*r)))
			end
			
			if FinalSelection:FindFirstChild("SpecialStructure") then
				local YDirection = FinalSelection.SpecialStructure.Value

				local Y = CalculateInterferingY(YDirection, y, nil, sourceBlockDist)--looking for structure already present within shape
					
				--print("BLOCK ABOVE: " .. tostring(FinalSelection) .. " " .. tostring(UsedPositions[PositionKey(x,y+1,z)]))
				--print("BLOCK BELOW: " .. tostring(FinalSelection) .. " " .. tostring(UsedPositions[PositionKey(x,y-1,z)]))
				
				if Y then
					if UsedPositions[PositionKey(x,Y,z)] ~= nil and UsedPositions[PositionKey(x,Y,z)] ~= false then
						local connectedBlock = UsedPositions[PositionKey(x,Y,z)]
						local connectedBlockInfo = Utility:GetItemInfo(tostring(connectedBlock))
						if connectedBlockInfo:FindFirstChild("SpecialStructure") then 
							print("DESTROYING STRUCTURE")
							Structure:Destroy()
							UsedPositions[PositionKey(x,y,z)] = false
						end
					end
				end
			end
			
		end
	end
end

--Immediate blocks around 0,0,0 (cave/region generation pattern)
local VectorsGen = {
	Vector3.new(-1,0,0),
	Vector3.new(1,0,0),
	Vector3.new(0,-1,0),	
	Vector3.new(0,1,0),
	Vector3.new(0,0,1),
	Vector3.new(0,0,-1)
}

--Blocks around and prepping below with widened top (mining pattern)
local VectorsMine = {
	Vector3.new(-1,0,0),
	Vector3.new(1,0,0),
	Vector3.new(0,-1,0),
	Vector3.new(0,1,0),
	Vector3.new(0,0,1),
	Vector3.new(0,0,-1),
	Vector3.new(0,2,0),
	Vector3.new(-1,0,-1),
	Vector3.new(1,0,1),
	Vector3.new(-1,0,1),
	Vector3.new(1,0,-1)
}

local GCounts = {} --Amount of blocks in generation array

local ExclaimRegion = game.ReplicatedStorage.Events.GUI.ExclaimRegion
local HighestYValue = 0
function GenerateOre(x,y,z,Override,PresetPoint,Region,Player)
	if (UsedPositions[PositionKey(x,y,z)] == nil or Override == true) and y > 0 then
		
		local Noise = math.noise(x/25,y/15,z/25) --math.noise is a perlin noise calculator, #'s are near each other, hence ability to make "natural" caves

		local CompactPos = Vector3.new(x,y,z)
		
		--Cave Generation (generates until all blocks are "taken", including VectorsGen nearby blocks)
		if y > 2 and ((Noise >= 0.48) or (Noise <= -0.48)) then --.525?
			
			UsedPositions[PositionKey(x,y,z)] = false
			
			if y > HighestYValue then --highest y value, lowest point in cave
				HighestYValue = y 
			end
		
			if Override ~= "Branch" then --If not a branch of a cave's source block, start cave generation
				HighestYValue = 0
				local Origin = PositionKey(x,y,z)
				GCounts[Origin] = 0 --Creating table with name of origin, definitive non-changing distinguishable point
				
				local Region = DecideSelection(y,Regions)
				GCounts[Region] = Region
				
				if Player then --Player is not nil when source block is first mined (function, later, doesn't signifiy)
					ExclaimRegion:FireClient(Player,Region)
				end
				
				print("REGION: " .. tostring(GCounts[Region]))
				
				--For setting the region apart from just a cave, maybe a closer to zero noise value will be used to generate nearby solids?
				--(make blocks around cave region specific as well)
				
				coroutine.resume(coroutine.create(function()
					for i,Vec in pairs(VectorsGen) do
						local NewPos = CompactPos + Vec

						if UsedPositions[PositionKey(NewPos.x,NewPos.y,NewPos.z)] == nil then 
							GCounts[Origin] = GCounts[Origin] + 1
							GenerateOre(NewPos.x,NewPos.y,NewPos.z,"Branch",Origin,Region)
							
							--Branch will start actual cave generation, checking Noise everytime
							--Noise correlates to natural shape
						end
					end
				end))
				
				--[[
				coroutine.resume(coroutine.create(function() --After the entire mine has been generated, check the true value for high
					wait(1)
					print("The true highest value for y is " .. tostring(HighestYValue))
					
					--**for liquid generation, entire cave will probably have to be deciated to be a water cave
					--(Then no structures will spawn, but ores still will)
					----Probably make this once fishing is in the game since water regions and etc have to be
					----understood before generating liquids
					
					
					--For liquid generation, how will it be mined? Long mine, where you mine the entire body of liquid, or individual chunks?)
				end))
				]]
				
				
			else --Generating ores in region
				local Origin = PresetPoint --Assigned as Origin from non-branch if statement
				local Bounds,sourceBlockDist = CalculateNoise(x,y,z)
				
				if Bounds then
					SpawnStructures(x,y,z,Bounds,Region,sourceBlockDist)
				end
				
				for i,Vec in pairs(VectorsGen) do
					local NewPos = CompactPos + Vec
					if UsedPositions[PositionKey(NewPos.x,NewPos.y,NewPos.z)] == nil then
						GCounts[Origin] = GCounts[Origin] + 1
						if GCounts[Origin] % 250 == 0 then --Wait every 100
							wait()
						end
						GenerateOre(NewPos.x,NewPos.y,NewPos.z,"Branch",Origin,Region)
					end
				end
			end		
			
		else --not cave, only generate ore (if in region is signified)
			local Ore = DecideSelection(y,Ores,Region):Clone()
			--Ore = DecideOre(y,(Override == "Branch")):Clone()

			for i,v in pairs(Ore:GetChildren()) do --Makes spawns more efficient
				if v:IsA("StringValue") or v:IsA("NumberValue") or v:IsA("Color3Value") or v:IsA("IntValue") or v:IsA("Folder") then
					v:Destroy()
				end
			end
			
			if GCounts[Region] ~= nil then
				local RegionColor = GCounts[Region]:FindFirstChild("BlockColor").Value
				Ore.Color = RegionColor
				
				local AmbientLighting = Instance.new("PointLight",Ore)
				AmbientLighting.Color = RegionColor

				--print(GCounts[Region], RegionColor.R, RegionColor.G, RegionColor.B, RegionColor.R + RegionColor.G + RegionColor.B)
				if RegionColor.R + RegionColor.G + RegionColor.B <= 1 then
					AmbientLighting.Brightness = 5
					AmbientLighting.Range = 15
				elseif RegionColor.R + RegionColor.G + RegionColor.B >= 2 then
					AmbientLighting.Brightness = 1.5
					AmbientLighting.Range = 8
				end
				
				if tostring(GCounts[Region]) == "Normal" then
					AmbientLighting.Brightness = 0.5
					AmbientLighting.Range = 5
				end
			end

			Ore.Parent = workspace.Mine
			if Ore:IsA("Model") then
				Ore:SetPrimaryPartCFrame(CFrame.new(0+x*7, -5+y*(-7), 0+z*7))
			else
				Ore.CFrame = CFrame.new(0+x*7, -5+y*(-7), 0+z*7)
			end
			--Ore.Transparency = math.abs(1*Noise)
			
			UsedPositions[PositionKey(x,y,z)] = Ore
			return Ore
		end
	end		
end

local MineOre = game.ReplicatedStorage.Events.Utility:WaitForChild("MineOre")
local UpdateItemCount = game.ReplicatedStorage.Events.GUI:WaitForChild("UpdateItemCount")

MineOre.Event:Connect(function(Player, ore)
	local itemInfo
	if ore.Name == "Target" then
		itemInfo = Utility:GetItemInfo(ore.Parent.Name)
		ore = ore.Parent
	else
		itemInfo = Utility:GetItemInfo(ore.Name)
	end
	
	local associatedSkill = itemInfo.AssociatedSkill.Value
	local itemType = string.gsub(associatedSkill, "Skill", "")
	
	local itemAmount = PlayerStatManager:getItemCount(Player, itemType)
	local maxItemAmount = PlayerStatManager:getEquippedData(Player, "MaterialBags", "Bags") --Bag capacity
	
	if maxItemAmount  then --Check bag again before finally breaking block
		if itemAmount < maxItemAmount  then
			if ore:FindFirstChild("Claimed") == nil then
				
				local Hitbox
				if ore:IsA("Model") then
					Hitbox = ore:FindFirstChild("GenerationPosition")
				else
					Hitbox = ore
				end
				local CompactPos = Vector3.new(0 + Hitbox.Position.X/7,(Hitbox.Position.Y - -5)/(-7),Hitbox.Position.Z/7)
				
				UsedPositions[PositionKey(CompactPos.X,CompactPos.Y,CompactPos.Z)] = false
				
				for i,Vector in pairs(VectorsMine) do
					local NewPos = CompactPos + Vector
					if UsedPositions[PositionKey(NewPos.x,NewPos.y,NewPos.z)] == nil then
						GenerateOre(NewPos.x,NewPos.y,NewPos.z,false,nil,nil,Player)
					end
				end
				
				local Bounds,sourceBlockDist = CalculateNoise(CompactPos.X,CompactPos.Y,CompactPos.Z,true)
				
				if Bounds then --If structure nearby, break structure (growing from/hanging from) destroyed block
					--local Y = CalculateInterferingY(Bounds, CompactPos.Y, nil, sourceBlockDist)--for connected structure
					local connectedOre = UsedPositions[PositionKey(CompactPos.X,CompactPos.Y+sourceBlockDist,CompactPos.Z)]
					
					if typeof(connectedOre) ~= "boolean" then
						if connectedOre:FindFirstChild("SpecialStructure") then
							local orePosition
							if connectedOre:IsA("Model") then
								orePosition = connectedOre.GenerationPosition.Position
							else
								orePosition = connectedOre.Position
							end
							local connectedOreInfo = Utility:GetItemInfo(tostring(connectedOre))
							local connectedOreColor = connectedOreInfo["GUI Info"].OreColor.Value
							MakeDustParticles(orePosition, connectedOreColor)
							connectedOre:Destroy()
						end
					end
				end
				
				--Add Ore to inventory
				local mined = PlayerStatManager:getStat(Player, ore.Name)
				local experience = PlayerStatManager:getStat(Player, "MiningSkill")
				--print(typeof(mined),typeof(experience))
				if typeof(mined) == "number" and typeof(experience) == "number" then
					local PlayerDataFile = PlayerData:WaitForChild(tostring(Player.UserId))
					
					local PlayerInventory = PlayerDataFile:WaitForChild("Inventory")
					PlayerStatManager:ChangeStat(Player, ore.Name, 1, "Inventory")
					
					local PlayerExperience = PlayerDataFile:WaitForChild("Experience")
					local InitialOreExperience = itemInfo.Experience.Value
					local associatedSkill = itemInfo.AssociatedSkill.Value
					PlayerStatManager:ChangeStat(Player, associatedSkill, InitialOreExperience, "Experience")
					
					local AssociatedFolder = PlayerInventory:WaitForChild(itemType)
					local CurrentOre = AssociatedFolder:FindFirstChild(ore.Name)
					local SkillsFolder = PlayerExperience:WaitForChild("Skills")
					local CurrentSkill = SkillsFolder:FindFirstChild("MiningSkill")
					
					
					--Change player discovered value if this is first time acquired
					local DiscoverValue = CurrentOre:FindFirstChild(tostring(ore) .. "Discovered")
					if DiscoverValue.Value == false then
						print("Changing " .. tostring(DiscoverValue) .. " to true")
						DiscoverValue.Value = true
						PlayerStatManager:ChangeStat(Player, tostring(ore) .. "Discovered", true, tostring(AssociatedFolder))
					end
				else
					warn("mined or experience cannot be saved")
				end
				
				local OrePosition
				if ore:IsA("Model") then
					OrePosition = ore.GenerationPosition.Position
				else
					OrePosition = ore.Position
				end
				
				ore:Destroy()
				
				local oreColor = itemInfo["GUI Info"].OreColor.Value
				MakeDustParticles(OrePosition,oreColor)
			end
		else
			print("Inventory has reached capacity with current bag")
			--Notify player that their inventory is full and they should sell/deposit their items 
			--(Pop Up GUI: Inventory Capacity Warning)
		end
	else
		print("Player does not have a bag equipped")
		--Notify player they have no bag they can fill
		--(Pop Up GUI: No Associated Bag Warning)
	end
end)

function MakeDustParticles(OrePosition, OreColor)
	--Perhaps have an event fire to all players to check if player has particles enabled?
	--(Could also be used to check magnitude to mined position to see if they need to be made for their screen at all)
	
	coroutine.resume(coroutine.create(function()
		local LeftoverDust = game.ReplicatedStorage.GuiElements.BlockDestroy:Clone()

		--To make the particles look less like they're coming off one source, make multiple small emitters offset from source
		LeftoverDust.Parent = workspace
		LeftoverDust.CFrame = CFrame.new(OrePosition)
		LeftoverDust.Particles.Color = ColorSequence.new(OreColor)
		LeftoverDust.Particles.Enabled = true
		wait(0.05)
		LeftoverDust.Particles.Enabled = false
		wait(0.5)
		LeftoverDust:Destroy()
	end))	
end

local function GenerateMine()
	print("GENERATING MINESHAFT")
	
	workspace.Regen.Transparency = 0
	workspace.Regen.CanCollide = true
	workspace.Regen.CFrame = CFrame.new(355, -10, 11) --model covers cave during generation
	
	for i,Player in pairs(workspace.Players:GetChildren()) do
		if Player:FindFirstChild("LowerTorso") then
			local RawPosition = Player.LowerTorso.Position
			local CompactPos = Vector3.new(0 + RawPosition.X/7,(RawPosition.Y - -5)/(-7),RawPosition.Z/7)
			if math.floor(CompactPos.X) > 0 and -math.floor(CompactPos.Y) < 10 and math.floor(CompactPos.Z) > 0 then
				Player.LowerTorso.CFrame = workspace.SpawnLocation.CFrame
			end
		end
	end
	
	local count = 1
	for i,Ore in pairs(workspace.Mine:GetChildren()) do
		Ore:Destroy()
		count = count + 1
		if count > 50 then
			count = 1
			wait()
		end
	end
	
	UsedPositions = {} --Reset Table
	for x=1,27 do
		for z=1,27 do
			GenerateOre(x,1,z,false,nil,true)
		end
	end
	
	wait(1)
	
	workspace.Regen.Transparency = 1
	workspace.Regen.CanCollide = false
	workspace.Regen.CFrame = CFrame.new(355, 10, 11)
	
	repeat wait(10) until #workspace.Mine:GetChildren() > 5000
	print(tostring(#workspace.Mine:GetChildren()) .. ";consequently, mine is resetting")
	GenerateMine()
end

GenerateMine()


