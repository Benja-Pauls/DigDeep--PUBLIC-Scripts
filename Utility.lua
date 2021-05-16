--(ModuleScript)
--Small module script for repetitive processes
------------------------------------------------------------------------------------------------------------------------------------------------
local Utility = {}

function Utility:UpdateMoneyDisplay(Player, NewPlayerCash)
	local PlayerGui = game.Players:FindFirstChild(tostring(Player)).PlayerGui
	
	local MoneyDisplay = PlayerGui:WaitForChild("MoneyDisplay")
	MoneyDisplay.Display.Frame.Money.Text = "$" .. tostring(NewPlayerCash)
	
	--Also updates wherever money is displayed GUI menus
	PlayerGui.DataMenu.DataMenu.PlayerMenu.PlayerInfo.PlayerCash.Text = tostring(NewPlayerCash)
	PlayerGui.StoreFrontGui.StoreFrontMenu.PlayerCashDisplay.PlayerCash.Text = "$" .. tostring(NewPlayerCash)
end

function Utility:CloneTable(OriginalTable)
	local copy = {}
	for i,tbl in pairs(OriginalTable) do
		if type(tbl) == "table" then
			tbl = Utility:CloneTable(tbl)
		end
		copy[i] = tbl
	end
	return copy
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

local GetShortMoneyValue = game.ReplicatedStorage.Events.Utility:WaitForChild("GetShortMoneyValue")
function GetShortMoneyValue.OnServerInvoke(player, Filter_Num)
	local ShortValue = Utility:ConvertShort(Filter_Num)
	return ShortValue
end

return Utility

