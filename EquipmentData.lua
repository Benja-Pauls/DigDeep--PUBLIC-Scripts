--One Module Script to reference every equipment value in the game across all scripts
--Server scripts require this script while local scripts use the GetItemStats remote function with checks in PlayerStatManager before returning cloned item info

local RS = game.ReplicatedStorage

local EquipmentData = {
	
	["Tools"] = {
		["Pickaxes"] = {
			
			["Glow Pickaxe"] = {
				["Stats"] = {
					{"Dig Power", 6},
					{"Mining Delay", 0.5},
					{"Swing Reach", 4}	
				},
				["Images"] = { --ImageId, Type = (Where it will be placed) (no index 2 means no display of stat in tile or ItemViewer)
					["Dig PowerImage"] = {"rbxassetid://6471867379", "StatBar"},
					["Mining DelayImage"] = {"rbxassetid://6471867379", "StatBar"},
					["Swing ReachImage"] = {"rbxassetid://6471867379", "StatBar"},
					["EquipmentTypeImage"] = {"rbxassetid://6893434091", "Badge"}
				},
				["referenceObject"] = RS.Equippable.Tools.Pickaxes["Glow Pickaxe"]
			},
			
			["Orange Pickaxe"] = {
				["Stats"] = {
					{"Dig Power", 6},
					{"Mining Delay", 0.5},
					{"Swing Reach", 4}	
				},
				["Images"] = { --ImageId, Type = (Where it will be placed) (no index 2 means no display of stat in tile or ItemViewer)
					["Dig PowerImage"] = {"rbxassetid://6471867379", "StatBar"},
					["Mining DelayImage"] = {"rbxassetid://6471867379", "StatBar"},
					["Swing ReachImage"] = {"rbxassetid://6471867379", "StatBar"},
					["EquipmentTypeImage"] = {"rbxassetid://6893434091", "Badge"}
				},
				["referenceObject"] = RS.Equippable.Tools.Pickaxes["Orange Pickaxe"]
			},
			
			["Pickaxe"] = {
				["Stats"] = {
					{"Dig Power", 6},
					{"Mining Delay", 0.5},
					{"Swing Reach", 4}	
				},
				["Images"] = { --ImageId, Type = (Where it will be placed) (no index 2 means no display of stat in tile or ItemViewer)
					["Dig PowerImage"] = {"rbxassetid://6471867379", "StatBar"},
					["Mining DelayImage"] = {"rbxassetid://6471867379", "StatBar"},
					["Swing ReachImage"] = {"rbxassetid://6471867379", "StatBar"},
					["EquipmentTypeImage"] = {"rbxassetid://6893434091", "Badge"}
				},
				["referenceObject"] = RS.Equippable.Tools.Pickaxes.Pickaxe
			}
			
		}
	},
	
	
	["Bags"] = {
		
		["MaterialBags"] = {
			
			["Beginner Bag"] = {
				["Stats"] = {
					["Bag Capacity"] = 100
				},
				["Images"] = {
					["Bag CapacityImage"] = {"rbxassetid://6471867379", "StatBar"}
				}
			},
			
			["Advanced Bag"] = {
				["Stats"] = {
					["Bag Capacity"] = 200
				},
				["Images"] = {
					["Bag CapacityImage"] = {"rbxassetid://6471867379", "StatBar"}
				}
			},
	
		}
	},
	
	
	
	
	
	
	
	["Pets"] = {
		
		
	},
	
	["Mounts"] = {
		
		
	}
}




return EquipmentData
