--(LocalScript)
--Visuals for asking if the player wants to buy the tycoon and loading the tycoon
------------------------------------------------------------------------------------------------------------------------------------------------
local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClaimTycoonGui = ReplicatedStorage.Events.Tycoon.ClaimTycoonGui
local ClaimTycoon = ReplicatedStorage.Events.Tycoon.ClaimTycoon
local CancelClaimTycoon = ReplicatedStorage.Events.Tycoon.CancelClaimTycoon
local LocalLoadTycoon = ReplicatedStorage.Events.Tycoon:WaitForChild("LocalLoadTycoon")
local LoadTycoon = ReplicatedStorage.Events.Tycoon.LoadTycoon

local debounce = false
local open

ClaimTycoonGui.OnClientEvent:Connect(function(tycoon)
	if debounce == false then
		local TycoonPurchaseGui = script.Parent
		TycoonPurchaseGui.PopUp.Visible = true
		local Yes = TycoonPurchaseGui.PopUp.Yes
		local No = TycoonPurchaseGui.PopUp.No
		open = true
		Yes.Activated:Connect(function()
			if open == true then
				debounce = true
				TycoonPurchaseGui.PopUp.Visible = false
				open = false
				ClaimTycoon:FireServer(tycoon)
				wait(3) 
				debounce = false
			end
		end)
		No.Activated:Connect(function()
			if open == true then
				debounce = true
				TycoonPurchaseGui.PopUp.Visible = false
				open = false
				CancelClaimTycoon:FireServer(tycoon)
				wait(2)
				debounce = false
			end
		end)
	else
		print("Cooldown for entrance hasn't finished")
	end
end)

LocalLoadTycoon.OnClientEvent:Connect(function(tycoon)
	print("Loading Tycoon: " .. tostring(tycoon))
	local LoadingTycoonGui = script.Parent.LoadingTycoonGui
	if tycoon.Owner.Value ~= nil then
		LoadTycoon:FireServer(tycoon)
		
		
		LoadingTycoonGui.Visible = true
		LoadingTycoonGui:TweenPosition(UDim2.new(0.625, 0, 0.835, 0), "Out", "Quint", 0.5)
		wait(.5)
		--coroutine.resume(coroutine.create(function()
			--put a progress bar here or the dots moving up and down 
			--(something to denote that the tycoon is loading)
			--Maybe just move bar out a little bit then go back down. Like floaty effect that dots would've had
		--end))
		wait(1.5)--Show UI as long as GateControl loads
		LoadingTycoonGui.Visible = false
	else
		print("tycoon.Owner.Value == nil")
	end
end)

