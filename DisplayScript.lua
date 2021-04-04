--(LocalScript)
--Updates money amount display, also waits for player to press the display's hide button
---------------------------------------------------------------------------------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local MoveAllBaseScreenUI = game.ReplicatedStorage.Events.GUI.MoveAllBaseScreenUI

local Display = script.Parent:WaitForChild("Display")
local Interact = Display:WaitForChild("Interact")
local Showing = false
local debounce = false

Interact.Activated:Connect(function()
	if debounce == false then
		debounce = true
		if Showing == false then --Pull out $ Display
			Interact.Text = ">>"
			Display:TweenPosition(UDim2.new(0.835, 0, 0.04, 0), "Out", "Bounce", 1)
			wait(1) --are the waits required?
			Showing = true
		else --Hide Display
			Interact.Text = "<<"
			Display:TweenPosition(UDim2.new(0.975, 0, 0.04, 0), "Out", "Quint", 1)
			wait(1)
			Showing = false
		end
		debounce = false
	end
	
	--[[
	Showing = true
	Display:TweenPosition(UDim2.new(0,0 , 0.865,0), "Out", "Bounce", 1)
	wait(.8)
	ShowButton.Visible = false
	ShowButton.Active = false
	PutAwayButton.Visible = true
	PutAwayButton.Active = true
	]]
end)


MoveAllBaseScreenUI.Event:Connect(function(ChangeTo)
	print("Hide All Base Screen UI bindable event has been fired")
	Showing = false --shelf display
	if ChangeTo == "Hide" then
		Display:TweenPosition(UDim2.new(1.03, 0, 0.04), "Out", "Quint", 1)
	else --Show
		Display:TweenPosition(UDim2.new(0.975, 0, 0.04, 0), "Out", "Quint", 1)
	end
	wait(.8)
end)

