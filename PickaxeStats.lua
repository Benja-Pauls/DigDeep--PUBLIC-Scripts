--(ModuleScript)
--ModuleScript that every level of pickaxe will have to easily access it's information
-----------------------------------------------------------------------------------------------------------------------------------------------

local Pickaxe = {
	
	["Stats"] = {
		{"PickaxesEfficiency", 6},
		{"PickaxesDelay", 0.5},
		{"PickaxesReach", 4},
		{"TestStat", true} --Test ImageName index check to fill Tool Slot statistic bars
			
	},
	
	["Images"] = { --ImageId, Type = (Where it will be placed) (no index 2 means no display of stat in tile or ItemViewer)
		["PickaxesEfficiencyImage"] = {"rbxassetid://6471867379", "StatBar"},
		["PickaxesDelayImage"] = {"rbxassetid://6471867379", "StatBar"},
		["PickaxesReachImage"] ={"rbxassetid://6471867379", "StatBar"},
		--["TestStatImage"] = {"TestStatImageId", "Badge"}
		
	}
	
	
}


return Pickaxe

