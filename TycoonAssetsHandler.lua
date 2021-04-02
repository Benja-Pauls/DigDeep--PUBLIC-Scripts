--(ModuleScript)
--Handles the assets in each player tycoon (drop collectors, drops, purchaseable objects)
------------------------------------------------------------------------------------------------------------------------------------------------
local Objects = {}

repeat wait() until script.Parent:FindFirstChild("Buttons")

local Tycoon = script.Parent
local TeamColor = Tycoon:WaitForChild("TeamColor").Value
local CollectibleCash = Tycoon.CurrencyToCollect
local Debris = game:GetService('Debris')
local SoundEffects = require(game.ReplicatedStorage:WaitForChild("SoundEffects"))
local PurchaseObject = game:GetService("ReplicatedStorage").Events.Utility.PurchaseObject
local PlayerStatManager = require(game.ServerScriptService:FindFirstChild("PlayerStatManager"))
local PlayerData = game.ServerStorage:FindFirstChild("PlayerData")
local Utility = require(game.ServerScriptService:WaitForChild("Utility"))
local UpdateInventory = game.ReplicatedStorage.Events.GUI:FindFirstChild("UpdateInventory")

Tycoon.Essentials.Spawn.TeamColor = TeamColor
Tycoon.Essentials.Spawn.BrickColor = TeamColor

local function CheckDependencies(Dependencies)
	local CompletedDependencies = 0
	local PurchasedObjects = Tycoon.PurchasedObjects
	--local DependencyAmount = Dependencies:GetChildren()
	for i,v in pairs (Dependencies:GetChildren()) do
		if PurchasedObjects:FindFirstChild(tostring(v.Value)) then
			CompletedDependencies = CompletedDependencies + 1
		end
	end

	return CompletedDependencies
end

--DropCollector Processing, Checks Current Terminal Amount Cap
local HandleDropMaterialsEvent = game.ReplicatedStorage.Events.Tycoon:WaitForChild("HandleDropMaterials")
for i,v in pairs(Tycoon.Essentials:GetChildren()) do 
	if v.Name == "DropCollector" then 
		v.Touched:connect(function(Part)
			if Part:FindFirstChild("Cash") then
				HandleDropMaterialsEvent:Fire(Tycoon, Part)
				local TerminalLevels = Tycoon.Essentials.TerminalLevel:GetChildren()
				if #TerminalLevels == 1 then --Can make this more efficient, value check for <=
					if Part.Cash.Value + CollectibleCash.Value <= 100 then
						CollectibleCash.Value = CollectibleCash.Value + Part.Cash.Value
						Debris:AddItem(Part,0.1)
					else
						Debris:AddItem(Part,0.1)
					end
				end
				if #TerminalLevels == 2 then
					if Part.Cash.Value + CollectibleCash.Value <= 200 then
						CollectibleCash.Value = CollectibleCash.Value + Part.Cash.Value
						Debris:AddItem(Part,0.1)
					else
						Debris:AddItem(Part,0.1)
					end
				end
			end
		end)
	end
end

--Get Money From Collector
coroutine.resume(coroutine.create(function()
	local Givers = Tycoon.Essentials:WaitForChild("Givers")
	if Givers:WaitForChild("Giver") ~= nil then
		local loop = true
		while loop == true do --checks for amount of givers, way to make more efficient?
			wait(1)

			for i,v in pairs(Givers:GetChildren()) do
				debounce = false
				
				v.Touched:connect(function(hit)
					local player = game.Players:GetPlayerFromCharacter(hit.Parent)
					
					if player ~= nil then
						if Tycoon.Owner.Value == player then
							if hit.Parent:FindFirstChild("Humanoid") then
								if hit.Parent.Humanoid.Health > 0 then
									if debounce == false then
										debounce = true 
										v.BrickColor = BrickColor.new("Bright red")
										
										local PlayerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
										local PlayerCash = PlayerDataFile:FindFirstChild("Currencies"):FindFirstChild("UniversalCurrencies"):FindFirstChild("Currency")
										if PlayerCash ~= nil then 
											local ListedPlayer = game.Players:FindFirstChild(tostring(player))
											if ListedPlayer ~= nil then
												SoundEffects:PlaySound(v, SoundEffects.Tycoon.Collect) 
												
												--UPDATE PLAYER CASH VIA PLAYER STAT MANAGER
												--COLLECTIBLE CASH IS SAVED IN PLAYERDATA FOR THEIR TYCOON (OWNSTYCOON VALUE)
												--AND YOU COMPARE THAT VALUE (CHECK IF WITHIN SIGNIFICANCE LEVEL OF .05)
												
												PlayerCash.Value = PlayerCash.Value + CollectibleCash.Value --add dropper cash to player cash

												Utility:UpdateMoneyDisplay(hit.Parent.Name, PlayerCash.Value)
												if CollectibleCash.Value ~= 0 then
													UpdateInventory:FireClient(player, "Currency", "Currencies", nil, CollectibleCash.Value, "Inventory", "Money1")
												end	

												CollectibleCash.Value = 0 
												wait(1)
												v.BrickColor = BrickColor.new("Sea green")
												debounce = false 
											else
												print("Breaking Giver Loop for " .. tostring(player))
												loop = false
											end
										end
									end
								end
							end
						end
					end
				end)
			end
		end	
	end
end))

local function PrepButton(Button, Parts)
	Button:WaitForChild("Visible").Value = true
	for bp = 1,#Parts,1 do
		Parts[bp].Transparency = 0
		Button.CanCollide = true
	end
end

local function GetPlayer(WantedPlayer)
	print("WANTED PLAYER: " .. tostring(WantedPlayer))
	local Players = game.Players:GetChildren()
	local lookingForPlayer = true
	for i,v in pairs(Players) do
		if tostring(v.UserId) == WantedPlayer then
			lookingForPlayer = false
			return v
		end
	end
	if lookingForPlayer == true then
		warn("Something went wrong, cannot find player")
	end
end

--Prepping Tycoon Purchases
for i,button in pairs(Tycoon.Buttons:GetChildren()) do

	coroutine.resume(coroutine.create(function()

		local ButtonParts = button.Model:GetChildren()
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
			if Object ~= nil then --If object affiliated is in the purchases group
				Objects[Object.Name] = Object:Clone()
				--Object:Destroy() --All objects are stored in a table, not bought = destroyed until bought
				--print(tostring(Object).." was destroyed")
			else
				error("Button "..tostring(button).." doesn't have a valid object!")
			end

			if button:FindFirstChild("Dependencies") then
				button.CanCollide = false
				button:WaitForChild("Visible").Value = false
				for bp = 1,#ButtonParts,1 do
					ButtonParts[bp].Transparency = 1
				end
				coroutine.resume(coroutine.create(function()
					local repeating = true
					while repeating do
						wait(3)
						local Dependencies = button.Dependencies
						local DependencyAmount = button.Dependencies:GetChildren()

						local FulfilledDependencies = CheckDependencies(Dependencies)
						if FulfilledDependencies == #DependencyAmount then
							repeating = false
							PrepButton(button,ButtonParts)
						end
					end
				end))
			else
				button:WaitForChild("Visible").Value = true --WaitForChild is there for now, not all buttons have it yet
			end
		end
	end))
end

return Objects

