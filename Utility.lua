--(ModuleScript)
--Small module script for repetitive processes
------------------------------------------------------------------------------------------------------------------------------------------------
local Utility = {}

function Utility:GetItemInfo(statName, typeOnly)
	for _,itemType in pairs (game.ReplicatedStorage.InventoryItems:GetChildren()) do
		if itemType:FindFirstChild(statName) then
			if typeOnly then
				return itemType
			else
				return itemType:FindFirstChild(statName)
			end
		end
	end
end

function Utility:UpdateMoneyDisplay(Player, newPlayerCash)
	local PlayerGui = game.Players:FindFirstChild(tostring(Player)).PlayerGui
	local MoneyDisplay = PlayerGui:WaitForChild("MoneyDisplay")
	
	MoneyDisplay["Coin Display"].Amount.Text = "$" .. tostring(newPlayerCash)
	PlayerGui.DataMenu.DataMenu.PlayerMenu.PlayerInfo.PlayerCash.Text = tostring(newPlayerCash)
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
		return x:sub(0,(important)).."."..(x:sub(#x-2,(#x-2)))..(x:sub(#x-1,(#x-1))) .. "K"
	else
		return Filter_Num
	end
end

return Utility

