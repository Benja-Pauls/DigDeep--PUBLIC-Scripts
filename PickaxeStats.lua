--(ModuleScript)
--ModuleScript that every level of pickaxe will have to easily access it's information
-----------------------------------------------------------------------------------------------------------------------------------------------
--This is similar to creating a class in Python, we're defining the "property" of Eff for the 
--"object" Pickaxe

local Pickaxe = {
	
	["Stats"] = {
		{"Dig Efficiency", 6},
		{"Swing Delay", 0.5},
		{"Pickaxe Reach", 4},
		{"EquipmentType", true} --Test ImageName index check to fill Tool Slot statistic bars
			
	},
	
	["Images"] = { --ImageId, Type = (Where it will be placed) (no index 2 means no display of stat in tile or ItemViewer)
		["Dig EfficiencyImage"] = {"rbxassetid://6471867379", "StatBar"},
		["Swing DelayImage"] = {"rbxassetid://6471867379", "StatBar"},
		["Pickaxe ReachImage"] ={"rbxassetid://6471867379", "StatBar"},
		["EquipmentTypeImage"] = {"rbxassetid://6893434091", "Badge"}
	}
	
	
}


return Pickaxe

