--(ModuleScript)
--Handles the assets in each player tycoon (drop collectors, drops, purchaseable objects)
------------------------------------------------------------------------------------------------------------------------------------------------
local Objects = {}

repeat wait() until script.Parent:FindFirstChild("Buttons") --Script has been moved to tycoon

local Tycoon = script.Parent
local CollectibleCash = Tycoon.CurrencyToCollect
local PurchasedObjects = Tycoon.PurchasedObjects
local CompletedResearch = Tycoon.CompletedResearch

local PlayerDataFolder = game.ServerStorage:FindFirstChild("PlayerData")

local SoundEffects = require(game.ReplicatedStorage:WaitForChild("SoundEffects"))
local PlayerStatManager = require(game.ServerScriptService:FindFirstChild("PlayerStatManager"))
local Utility = require(game.ServerScriptService:WaitForChild("Utility"))

local PurchaseObject = game:GetService("ReplicatedStorage").Events.Utility.PurchaseObject
local UpdateInventory = game.ReplicatedStorage.Events.GUI:FindFirstChild("UpdateInventory")

--local TeamColor = Tycoon:WaitForChild("TeamColor").Value
--Tycoon.Essentials.Spawn.TeamColor = TeamColor
--Tycoon.Essentials.Spawn.BrickColor = TeamColor

-------------------<|Utility|>---------------------------------------------------------------------------------------------------------------------------

local function GetPlayer(WantedPlayer)
	print("WANTED PLAYER: " .. tostring(WantedPlayer))
	local Players = game.Players:GetChildren()
	local lookingForPlayer = true
	for i,v in pairs (Players) do
		if tostring(v.UserId) == WantedPlayer then
			lookingForPlayer = false
			return v
		end
	end
	if lookingForPlayer == true then
		warn("Something went wrong, cannot find " .. tostring(WantedPlayer))
	end
end

----------------<|Collector Functions|>------------------------------------------------------------------------------------------------------------------

local Debris = game:GetService("Debris")
local HandleDropMaterialsEvent = game.ReplicatedStorage.Events.Tycoon:WaitForChild("HandleDropMaterials")
local function PrepDropCollectors(collector)
	collector.Touched:connect(function(Part)
		if Part:FindFirstChild("Cash") then
			HandleDropMaterialsEvent:Fire(Tycoon, Part)

			CollectibleCash.Value = CollectibleCash.Value + Part.Cash.Value
			Debris:AddItem(Part,0.1)
		end
	end)
end

for i,collector in pairs (Tycoon.Essentials:GetChildren()) do
	if collector.Name == "DropCollector" then 
		PrepDropCollectors(collector)
	end
end
Tycoon.Essentials.ChildAdded:Connect(function(newCollector)
	if newCollector.Name == "DropCollector" then
		PrepDropCollectors(newCollector)
	end
end)

---------------------<|Giver Functions|>--------------------------------------------------------------------------------------------------------------------

local function PrepGiverButton(giver)
	debounce = false
	giver.Touched:connect(function(hit)
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)

		if player ~= nil then
			if Tycoon.Owner.Value == player then
				if hit.Parent:FindFirstChild("Humanoid") then
					if hit.Parent.Humanoid.Health > 0 then
						if debounce == false then
							debounce = true 
							giver.BrickColor = BrickColor.new("Bright red")

							local PlayerDataFile = PlayerDataFolder:FindFirstChild(tostring(player.UserId))
							local PlayerCash = PlayerDataFile:FindFirstChild("Currencies"):FindFirstChild("UniversalCurrencies"):FindFirstChild("Currency")
							if PlayerCash ~= nil then 
								local ListedPlayer = game.Players:FindFirstChild(tostring(player))
								if ListedPlayer ~= nil then
									SoundEffects:PlaySound(giver, SoundEffects.Tycoon.Collect) 

									PlayerCash.Value = PlayerCash.Value + CollectibleCash.Value --add dropper cash to player cash

									Utility:UpdateMoneyDisplay(hit.Parent.Name, PlayerCash.Value)
									if CollectibleCash.Value ~= 0 then
										UpdateInventory:FireClient(player, "Currency", "Currencies", nil, CollectibleCash.Value, "Inventory", "Money1")
									end	

									CollectibleCash.Value = 0 
									wait(1)
									giver.BrickColor = BrickColor.new("Sea green")
									debounce = false 
								else
									print("Breaking Giver Loop for " .. tostring(player))
								end
							end
						end
					end
				end
			end
		end
	end)
end

local Givers = Tycoon.Essentials:WaitForChild("Givers")

for i,giver in pairs (Givers:GetChildren()) do
	PrepGiverButton(giver)
end
Givers.ChildAdded:Connect(function(newGiver)
	PrepGiverButton(newGiver)
end)

-----------------------<|Tycoon Button Functions|>--------------------------------------------------------------------------------------------------------

local function UpdateButtonVisibility(Button, Parts, Bool, Transparency)
	Button:WaitForChild("Visible").Value = Bool
	for bp = 1,#Parts,1 do
		Parts[bp].Transparency = Transparency
		Button.CanCollide = Bool
	end
end

local function SeeIfObjectIsDependency(Dependencies, Object)
	for i,dependency in pairs (Dependencies) do
		
		--tostring(Object) = Value and type(tostring(Object)) does not output anything
		--***********
		
		print("Dependency value =",dependency.Value,Object,tostring(Object))
		print(type(dependency.Value, type(tostring(Object))))
		if dependency.Value == tostring(Object) then
			print("***")
			return true
		end
	end
end

local function CountDependencies(Dependencies, Folder)
	local CompletedDependencies = 0
	for i,v in pairs (Dependencies) do
		if Folder:FindFirstChild(tostring(v.Value)) then
			CompletedDependencies += 1
		end
	end

	return CompletedDependencies
end

local function ReviewDependencies(Button, ButtonParts)
	local Dependencies = Button.Dependencies
	local DependencyTypesToMeet = #Dependencies:GetChildren()
	local DependenciesMet = 0
	
	for i,dependency in pairs (Dependencies:GetChildren()) do
		if dependency.Value == true then
			DependenciesMet += 1
		end
	end
	
	if DependencyTypesToMeet == DependenciesMet then
		UpdateButtonVisibility(Button, ButtonParts, true, 0)
	end
end

local function SetUpDependencyChecks(Button, ButtonParts, CompletedOfType, DependencyType, Object)
	local Dependencies = Button.Dependencies
	local TypeDependencies = DependencyType:GetChildren()

	CompletedOfType.ChildAdded:Connect(function(newObject)
		print("New child for ",CompletedOfType)
		if not CompletedOfType:FindFirstChild(tostring(Object)) then --not already bought
			print("1",TypeDependencies,newObject)
			if SeeIfObjectIsDependency(TypeDependencies, newObject) then
				print("2")
				local FulfilledDependencies = CountDependencies(TypeDependencies, CompletedOfType)
				print(FulfilledDependencies, #TypeDependencies)
				if FulfilledDependencies == #TypeDependencies then
					DependencyType.Value = true
					ReviewDependencies(Button, ButtonParts)
				end
			end
		end
	end)
end

for i,button in pairs(Tycoon.Buttons:GetChildren()) do
	if button:FindFirstChild("Object") then 
		local TycoonPurchases = game.ReplicatedStorage:FindFirstChild("TycoonPurchases")
		local ButtonType = button:WaitForChild("Type").Value --Used for file management in TycoonPurchases file
		local Object
		
		if TycoonPurchases:FindFirstChild(tostring(ButtonType)) then
			local TypeFile = TycoonPurchases:FindFirstChild(tostring(ButtonType))
			Object = TypeFile:FindFirstChild(tostring(button.Object.Value))
		else
			Object = TycoonPurchases:FindFirstChild(button.Object.Value)
		end
		if Object then --If object affiliated is in the purchases group
			Objects[Object.Name] = Object:Clone()
		else
			error("Button "..tostring(button).." doesn't have a valid object!")
		end
		
		local ButtonParts = button.ButtonModel:GetChildren()
		if button:FindFirstChild("Dependencies") then
			local Dependencies = button.Dependencies
			UpdateButtonVisibility(button, ButtonParts, false, 1)
			
			if Dependencies:FindFirstChild("TycoonObjects") then
				local TycoonObjects = Dependencies.TycoonObjects
				SetUpDependencyChecks(button, ButtonParts, PurchasedObjects, TycoonObjects, Object)
			end
			if Dependencies:FindFirstChild("TycoonResearch") then
				local TycoonResearch = Dependencies.TycoonResearch
				SetUpDependencyChecks(button, ButtonParts, CompletedResearch, TycoonResearch, Object)
			end
		else
			UpdateButtonVisibility(button, ButtonParts, true, 0)
		end
	end
end

return Objects

