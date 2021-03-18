--(Script)
--Handles special processes that occur with some purchases
----------------------------------------------------------------------------------------------------------------------------------------------


--the amount of local functions can definetely be made more efficient with an overall check,
--but the seperate function increase readability

local Tycoon = script.Parent
local PurchasedObjectsModel = Tycoon:WaitForChild("PurchasedObjects")

--Special Buy Functions
local function changeMaterial(purchase,group,number)
	local objectName = purchase.ObjectName.Value
	
	if Tycoon ~= nil then
		if purchase ~= nil then 
			if purchase:FindFirstChild("Material"..number) ~= nil then
				if purchase.Parent == PurchasedObjectsModel then
					local material = purchase:FindFirstChild("Material"..number).Value
					local ChangedParts = purchase.Parent.Parent.PurchasedObjects:WaitForChild(objectName).Model:FindFirstChild(group):GetChildren()
					for i = 1,#ChangedParts,1 do
						ChangedParts[i].Material = material
					end
				end
			end
		end
	end
end

local function changeColor (purchase,group,number)
	local objectName = purchase.ObjectName.Value
	
	if Tycoon ~= nil then
		if purchase ~= nil then
			if purchase:FindFirstChild("Color"..number) ~= nil then
				if purchase.Parent == PurchasedObjectsModel then
					local color = purchase:FindFirstChild("Color"..number).Value
					local ChangedParts = purchase.Parent.Parent.PurchasedObjects:WaitForChild(objectName).Model:FindFirstChild(group):GetChildren()
					for i =1,#ChangedParts,1 do
						ChangedParts[i].BrickColor = BrickColor.new(color)
					end
				end
			end
		end
		
	end
end

local function changeObjectTeamColor (purchase,group)
	local objectName = purchase.ObjectName.Value
	
	if Tycoon ~= nil then
		if purchase ~= nil then
			if purchase.Parent == PurchasedObjectsModel then
				local actualTeamColor = purchase.Parent.Parent.TeamColor.Value
				local ChangedParts = purchase.Parent.Parent.PurchasedObjects:WaitForChild(objectName).Model:FindFirstChild(group):GetChildren()
				purchase.teamColor.Value = actualTeamColor
				for i = 1,#ChangedParts,1 do
					ChangedParts[i].BrickColor = purchase.teamColor.Value
				end
			end
		end
	end
end

local function upgradeMachine (purchase,level)
	local objectName = purchase.ObjectName.Value
	
	if Tycoon ~= nil then
		if purchase ~= nil then
			if purchase.Parent == PurchasedObjectsModel then
				local upgrade = purchase.MachineUpgrade
				local upgradedObject = PurchasedObjectsModel:WaitForChild(objectName)
				upgrade.Name = "Upgrade"..level
				upgrade.Parent = upgradedObject.Upgrades
				print(upgrade.Parent)
			end
		end
	end
end

local function upgradeConveyor (purchase,level)

	if Tycoon ~= nil then
		if purchase ~= nil then
			if purchase.Parent == PurchasedObjectsModel then
				local conveyorTerminal = purchase.Parent:WaitForChild("ConveyorTerminal")
				local ConveyorUpgrade = purchase:FindFirstChild("ConveyorUpgrade")
				ConveyorUpgrade.Name = "Upgrade"..level
				wait(0.5)
				ConveyorUpgrade.Parent = conveyorTerminal.Upgrades
			end
		end
	end
end

local function TerminalUpgrade (purchase,level)
	
	if Tycoon ~= nil then
		if purchase ~= nil then
			if purchase.Parent == PurchasedObjectsModel then
				local TerminalLevelModel = Tycoon.Essentials.TerminalLevel
				local Upgrade = purchase.TerminalLevel
				Upgrade.Name = "Upgrade"..level
				wait(0.5)
				Upgrade.Parent = TerminalLevelModel
			end
		end
	end
end

local function DestroyPurchasedObject (purchase,object,DestroyGroup,GroupNumber)
	
	if Tycoon ~= nil then
		if purchase ~=nil then
			if purchase.Parent == PurchasedObjectsModel then
				local DestroyPurchase = purchase.Parent:WaitForChild(object)
				if DestroyPurchase ~= nil then
					DestroyPurchase:WaitForChild(DestroyGroup):WaitForChild(GroupNumber):Destroy()
				end
			end
		end
	end
end 

local function Demolish (purchase,group)
	
	if Tycoon ~= nil then
		if purchase ~= nil then
			if purchase.Parent == PurchasedObjectsModel then
				local Object = purchase.Parent.Parent.DemolishedObjects:WaitForChild(group)
				Object:Destroy()
			end
		end
	end
end

--[[ Timed Purchases
local function buildTimedObject (purchase,group,firstTime)
	
	if Tycoon ~= nil then
		if purchase ~= nil then
			if purchase.Parent == PurchasedObjectsModel then
				local Group = purchase:FindFirstChild(group)
				local LoadedGroups = Group:GetChildren()
				local Increments = purchase.Timed.Value
				local Timer = purchase.Timer.Value
				if firstTime == true then
					for g = 1,#LoadedGroups,1 do --First Load, set all transparent
						for i = 1,Increments,1 do
							if LoadedGroups[g].Name == "Slot"..i then
								local LoadedParts = LoadedGroups[g]:GetChildren()
								for p = 1,#LoadedParts,1 do
									LoadedParts[p].Transparency = 1
								end
							end
						end
					end
					for g = 1,#LoadedGroups,1 do --Timer starts, start setting parts non-transparent
						for i = 1,Increments,1 do
							if LoadedGroups[g].Name == "Slot"..i then
								local LoadedPart = LoadedGroups[g]:GetChildren()
								for p = 1,#LoadedPart,1 do
									LoadedPart[p].Transparency = 0
									wait(Timer)
								end
							end
						end
					end
				end
				if firstTime == false then --Bought Before, no timer needed
					for g = 1,#LoadedGroups,1 do 
						for i = 1,Increments,1 do
							if LoadedGroups[g].Name == "Slot"..i then
								local LoadedPart = LoadedGroups[g]:GetChildren()
								for p = 1,#LoadedPart,1 do
									LoadedPart[p].Transparency = 0
								end
							end
						end
					end
				end
			end
		end
	end
end
]]

--When Object is Purchased
PurchasedObjectsModel.ChildAdded:Connect(function(purchase)
	
	--Make associated name with purchase find function name or some other, more efficient, way
	
	if purchase:FindFirstChild("Material1") ~= nil then
		local Group = purchase.AffectedGroup1.Value
		changeMaterial(purchase,Group,"1")
	end	
	 
	if purchase:FindFirstChild("Material2") ~= nil then
		local Group = purchase.AffectedGroup2.Value
		changeMaterial(purchase,Group,"2")
	end
	
	if purchase:FindFirstChild("Color1") ~= nil then
		local Group = purchase.AffectedGroup1.Value
		changeColor(purchase,Group,"1")
	end
	
	if purchase:FindFirstChild("Color2") ~= nil then
		local Group = purchase.AffectedGroup2.Value
		changeColor(purchase,Group,"2")
	end
	
	if purchase:FindFirstChild("teamColor") ~= nil then
		local Group = purchase.AffectedGroup1.Value
		changeObjectTeamColor(purchase,Group)
	end
	
	if purchase:FindFirstChild("MachineUpgrade") ~= nil then
		local Level = purchase.UpgradeLevel.Value
		upgradeMachine(purchase,Level)
	end
	
	if purchase:FindFirstChild("Destroy") ~= nil then
		local Group = purchase.ObjectName.Value
		Demolish(purchase,Group)
	end
	
	if purchase:FindFirstChild("GroupPortionDestroy") ~= nil then
		local Object = purchase.GroupPortionDestroy.Value
		local DestroyGroup = purchase.GroupPortionDestroy.DestroyGroup.Value
		local GroupNumber = purchase.GroupPortionDestroy.GroupNumber.Value
		DestroyPurchasedObject(purchase,Object,DestroyGroup,GroupNumber)
	end
	
	if purchase:FindFirstChild("GroupPortionDestroy2") ~= nil then
		local Object = purchase.GroupPortionDestroy2.Value
		local DestroyGroup = purchase.GroupPortionDestroy2.DestroyGroup.Value
		local GroupNumber = purchase.GroupPortionDestroy2.GroupNumber.Value
		DestroyPurchasedObject(purchase,Object,DestroyGroup,GroupNumber)
	end
	
	if purchase:FindFirstChild("ConveyorUpgrade") ~= nil then
		local level = purchase.ConveyorUpgrade.Value
		upgradeConveyor(purchase,level)
	end
		
	if purchase:FindFirstChild("TerminalLevel") ~= nil then
		local level = purchase.TerminalLevel.Value
		TerminalUpgrade(purchase,level)
	end
		
	if purchase:FindFirstChild("Giver") ~= nil then
		local Giver = purchase.Giver
		Giver.Parent = script.Parent.Essentials.Givers
	end
	
end)


--[[ Buttons group for time check on timed destruction/build objects
local Buttons = script.Parent.Buttons:GetChildren()

for b = 1,#Buttons,1 do

local purchaseName = Buttons[b].Object.Value
local PurchasedObjects = script.Parent.PurchasedObjects
if Buttons[b]:FindFirstChild("Timed") ~= nil then	

	if PurchasedObjects:WaitForChild(purchaseName) ~= nil then
		local purchase = PurchasedObjects:WaitForChild(purchaseName)
		local Group = PurchasedObjects:WaitForChild(purchaseName).AffectedGroup1.Value
		buildTimedObject(purchase,Group,false)
	else
		if Buttons[b].Head.Touched ~= nil then
			local Button = Buttons[b].Parent
				Button.Head.Touched:connect(function(hit)
				local purchase = PurchasedObjects:WaitForChild(purchaseName)
				local player = game.Players:GetPlayerFromCharacter(hit.Parent)
					if player ~= nil then
						if script.Parent.Owner.Value == player then
							if hit.Parent:FindFirstChild("Humanoid") then
								if hit.Parent.Humanoid.Health > 0 then
									local Group = PurchasedObjects:WaitForChild(purchaseName).AffectedGroup1.Value
									buildTimedObject(purchase,Group,true)
								end
							end
						end
					end
				end)
			end
		end
	end
end
	



--[[
	if PurchasedObjects.Buttons[i]:FindFirstChild("Timed") ~= nil then
		local ButtonName = purchase:FindFirstChild("ButtonName").Value
		local PurchasedObjects = script.Parent.PurchasedObjects
		local ButtonItem = Buttons:FindFirstChild(ButtonName).Object.Value
		print(ButtonItem)
		
		if PurchasedObjects:FindFirstChild(ButtonItem) ~= nil then --Already Bought
			local Group = purchase.AffectedGroup1.Value
			buildTimedObject(purchase,Group,false)
		end
	
		if PurchasedObjects:FindFirstChild(ButtonItem) == nil then	
			if Buttons:FindFirstChild(ButtonName).Head.Touched ~= nil then --First TimeBuyting
				Buttons:FindFirstChild(ButtonName).Head.Touched:connect(function(hit)
				local player = game.Players:GetPlayerFromCharacter(hit.Parent)
					if player ~= nil then
						if script.Parent.Owner.Value == player then
							if hit.Parent:FindFirstChild("Humanoid") then
								if hit.Parent.Humanoid.Health > 0 then
									print("It worked!")
									local Group = purchase.AffectedGroup1.Value
									buildTimedObject(purchase,Group,true)
								end
							end
						end
					end
				end)
			end
		end
	end
	]]
