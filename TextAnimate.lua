local Players = game:GetService("Players")

local translator = nil

local AnimateUI = {}

function AnimateUI.typeWrite(guiObject, text, delayBetweenChars)
	guiObject.Visible = true
	guiObject.AutoLocalize = false
	
	local displayText = text
	guiObject.Text = displayText
	
	local index = 0
	for first, last in utf8.graphemes(displayText) do
		index = index + 1
		guiObject.MaxVisibleGraphemes = index
		wait(delayBetweenChars)
	end
end

return AnimateUI

