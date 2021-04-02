--(ModuleScript)
--Older sound effects module script, planned to be used in final game, but current sound effects are placed with model
------------------------------------------------------------------------------------------------------------------------------------------------
local SoundEffects = {

	["Tycoon"] = {
		["Purchase"] = 203785492, -- The sound that plays when a player buys a button he can afford
		["Collect"] = 131886985, -- The sound that plays when a player collects his currency
		["ErrorBuy"] = 138090596
	
	}

}

function SoundEffects:PlaySound(part, id, setDelay)
	if part:FindFirstChild("Sound") then
		return
	else
		local sound = Instance.new("Sound",part)
		sound.SoundId = "rbxassetid://"..tostring(id)
		sound:Play()
		
		if not setDelay then
			delay(sound.TimeLength, function()
				sound:Destroy()
			end)
		else
			wait(setDelay)
			sound:Destroy()
		end
	end
end

return SoundEffects

