--(ModuleScript)
--ModuleScript that every level of pickaxe will have to easily access it's information
-----------------------------------------------------------------------------------------------------------------------------------------------
--This is similar to creating a class in Python, we're defining the "property" of Eff for the 
--"object" Pickaxe

local Pickaxe = {
	
	["Stats"] = {
		{"PickaxeEfficiency", 6},
		{"PickaxeDelay", 0.5},
		{"PickaxeReach", 4},
		{"TestStat", true} --Test ImageName index check to fill Tool Slot statistic bars
			
	},
	
	["Images"] = { --ImageId, Type = (Where it will be placed) (no index 2 means no display of stat in tile or ItemViewer)
		["PickaxeEfficiencyImage"] = {"rbxassetid://6471867379", "StatBar"},
		["PickaxeDelayImage"] = {"rbxassetid://6471867379", "StatBar"},
		["PickaxeReachImage"] ={"rbxassetid://6471867379", "StatBar"},
		--["TestStatImage"] = {"TestStatImageId", "Badge"}
		
	}
	
	
}


return Pickaxe
