--(Script)
--Entrance to everyone's business, the door you have to go through in order to purchase any plot/structure

--**This is a deprecated script and will be replaced since players "purchase" an ISLAND once they unlock it
-----------------------------------------------------------------------------------------------------------------------------------------------
local PlayerStatManager = require(game.ServerScriptService:WaitForChild("PlayerStatManager"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClaimTycoonGui = ReplicatedStorage.Events.Tycoon.ClaimTycoonGui
local ClaimTycoon = ReplicatedStorage.Events.Tycoon.ClaimTycoon
local CancelClaimTycoon = ReplicatedStorage.Events.Tycoon.CancelClaimTycoon
local LocalLoadTycoon = ReplicatedStorage.Events.Tycoon.LocalLoadTycoon
local LoadTycoon = ReplicatedStorage.Events.Tycoon.LoadTycoon

local debounce = false
--Player Touches entrance to tycoon
script.Parent.Head.Touched:connect(function(hit)
	local tycoon = script.Parent.Parent.Parent
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player ~= nil and debounce == false then

		local PlayerData = game.ServerStorage:FindFirstChild("PlayerData")
		local PlayerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
		if PlayerDataFile ~= nil then 

			local ownstycoon = PlayerDataFile:FindFirstChild("OwnsTycoon") 
			if ownstycoon ~= nil and ownstycoon.Value == nil then 
				
				if script.Parent.Parent.Parent.Owner.Value == nil then 
					debounce = true
					local stat = PlayerStatManager:getStat(player, script.Parent.Parent.Name)							
					--Check if this tycoon has been previously owned
					if stat == false then
						print(tostring(player) .. " has never bought the entrance before")
						ClaimTycoonGui:FireClient(player,tycoon)
						
						CancelClaimTycoon.OnServerEvent:Connect(function(player,tycoon)
							if tycoon == script.Parent.Parent.Parent then
								print(tostring(tycoon) .. " has been claim cancelled")
							end
						end)
						wait(3)
						debounce = false
						
					elseif stat == true then
						print(tostring(player) .. " has re-loaded " .. tostring(tycoon))

						script.Parent.Parent.Parent.Owner.Value = player 
						ownstycoon.Value = script.Parent.Parent.Parent
						LocalLoadTycoon:FireClient(player,tycoon)
						wait(2) --allow savehandler to load buttons (stats == false)
						
						script.Parent.Name = player.Name.."'s Facility" 
						script.Parent.Head.Transparency = 0.7 
						script.Parent.Head.CanCollide = false 
						player.TeamColor = script.Parent.Parent.Parent.TeamColor.Value

						wait(1)
						debounce = false
					else
						wait()
						debounce = false
					end
				end
			end
		end
	end
end)

local claimed = false
--Never Bought Tycoon Before
ClaimTycoon.OnServerEvent:Connect(function(player,tycoon)
	if script.Parent.Parent.Parent == tycoon and claimed == false then
		
		local PlayerData = game.ServerStorage:FindFirstChild("PlayerData")
		local PlayerDataFile = PlayerData:FindFirstChild(tostring(player.UserId))
		local PlayerCash = PlayerDataFile:FindFirstChild("Currencies"):FindFirstChild("UniversalCurrencies"):FindFirstChild("Coins")
		
		
		print("CHANGE THIS SCRIPT LATER SO NON-SERVER SCRIPT DOESN'T ACCESS SERVERSTORAGE")
		
		local ownstycoon = PlayerDataFile:FindFirstChild("OwnsTycoon")
		if PlayerCash.Value >= script.Parent.Parent.Price.Value then
			if tycoon:WaitForChild("Owner").Value == nil then
				claimed = true
				tycoon.Owner.Value = player 
				ownstycoon.Value = tycoon
		
				PlayerCash.Value = PlayerCash.Value - tycoon.Entrance.Price.Value
				local MoneyDisplay = game.Players:FindFirstChild(tostring(player)).PlayerGui.MoneyDisplay
				MoneyDisplay["Coin Display"].Frame.Amount.Text = tostring(PlayerCash.Value)
		
				LocalLoadTycoon:FireClient(player,tycoon)

				wait(2) --how long it takes til door and team changes to player's name and tycoon
				script.Parent.Name = player.Name.."'s Facility" 
				script.Parent.Head.Transparency = 0.7 
				script.Parent.Head.CanCollide = false 
				player.TeamColor = tycoon.TeamColor.Value

				PlayerStatManager:ChangeStat(player, tycoon.Entrance.Name, true)
			else
				print("Two players tried to claim a tycoon at once")
				local TycoonOwnerShipWarning = player.PlayerGui.TycoonPurchaseGui.OwnershipWarning
				TycoonOwnerShipWarning.Visible = true
				wait(2)
				TycoonOwnerShipWarning.Visible = false
			end
		else
			print("Not enough money")	
		end
	end
end)

