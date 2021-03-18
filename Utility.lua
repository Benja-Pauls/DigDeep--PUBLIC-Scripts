--(ModuleScript)
--Small module script for repetitive processes
------------------------------------------------------------------------------------------------------------------------------------------------
local Utility = {}

function Utility:UpdateMoneyDisplay(Player, NewPlayerCash)
	local MoneyDisplay = game.Players:FindFirstChild(tostring(Player)).PlayerGui:WaitForChild("MoneyDisplay")
	MoneyDisplay.Display.Frame.Money.Text = "$" .. tostring(NewPlayerCash)
	
	--Also updates where money is displayed in PlayerMenu
	Player.PlayerGui.DataMenu.DataMenu.PlayerMenu["Default Menu"].PlayerInfo.PlayerCash.Text = "$" .. tostring(NewPlayerCash)
end

function Utility:ConvertShort(Filter_Num)
	--print(Filter_Num) = money amount player has in total
	local x = tostring(Filter_Num)
	--print(x) = money amount player has in total
	if #x>=10 then
		local important = (#x-9)
		return x:sub(0,(important)).."."..(x:sub(#x-7,(#x-7))).."B"
	elseif #x>=7 then
		local important = (#x-6)
		return x:sub(0,(important)).."."..(x:sub(#x-5,(#x-5))).."M"
	elseif #x>=4 then
		local important = (#x-3)
		return x:sub(0,(important)).."."..(x:sub(#x-2,(#x-2))).."K"
	else
		return Filter_Num
	end
end

return Utility
