-- Input/output:
-- "gold", "science", "resource:gold", "resource:uranium", "extract:gold"

local t = {
	economy = {
		{
			id = "mine",
			lvl = {
				[1] = {
					input = {
						["extract:gold"] = 10,
					},
					output = {
						["resource:gold"] = 10,
					},
					cost = 2500,
				},
				[2] = {
					input = {
						["extract:gold"] = 20,
					},
					output = {
						["resource:gold"] = 20,
					},
					cost = 5000,
				},
				[3] = {
					input = {
						["extract:gold"] = 30,
					},
					output = {
						["resource:gold"] = 30,
					},
					cost = 10000,
				},
				[4] = {
					input = {
						["extract:gold"] = 40,
					},
					output = {
						["resource:gold"] = 40,
					},
					cost = 20000,
				},
				[5] = {
					input = {
						["extract:uranium"] = 1,
					},
					output = {
						["resource:uranium"] = 1,
					},
					cost = 30000,
				},
			}
		},
		{
			id = "mint",
			lvl = {
				[1] = {
					input = {
						["resource:gold"] = 30,
					},
					output = {
						["gold"] = 3000,
					},
					cost = 10000,
				},
				[2] = {
					input = {
						["resource:gold"] = 60,
					},
					output = {
						["gold"] = 6000,
					},
					cost = 20000,
				},
				[3] = {
					input = {
						["resource:gold"] = 100,
					},
					output = {
						["gold"] = 10000,
					},
					cost = 40000,
				},
			}
		},
		{
			id = "bank",
			lvl = {
				[1] = {
					output = {
						["gold"] = 500,
					},
					cost = 5000,
				},
				[2] = {
					output = {
						["gold"] = 1500,
					},
					cost = 10000,
				},
				[3] = {
					output = {
						["gold"] = 2500,
					},
					cost = 15000,
				},
			}
		},
	},
	science = {
		{ 
			id = "university",
			lvl = {
				[1] = {
					input = {
						["gold"] = 1000
					},
					output = {
						["science"] = 1,
					},
					cost = 10000,
				},
			}
		},
		{ 
			id = "science_center",
			lvl = {
				[1] = {
					input = {
						["gold"] = 10000
					},
					output = {
						["science"] = 5,
					},
					cost = 100000,
				},
				[2] = {
					input = {
						["gold"] = 15000
					},
					output = {
						["science"] = 10,
					},
					cost = 150000,
				},
			}
		},
	},
	defense = {
		{ 
			id = "tower",
			lvl = {
				[1] = {
					cost = 5000,
				},
			}
		},
		{
			id = "beacon",
			lvl = {
				[1] = {
					cost = 5000,
				},
			}
		},
		{ 
			id = "fortress",
			lvl = {
				[1] = {
					defense_bonus = 1.4,
					cost = 2500,
				},
				[2] = {
					defense_bonus = 1.8,
					cost = 5000,
				},
				[3] = {
					defense_bonus = 2.6,
					cost = 10000,
				},
				[4] = {
					defense_bonus = 3.4,
					cost = 15000,
				},
				[5] = {
					defense_bonus = 4.2,
					cost = 20000,
				},
			}
		},
		{ 
			id = "hospital",
			lvl = {
				[1] = {
					cost = 10000,
				},
			}
		},
		{ 
			id = "air_defense",
			lvl = {
				[1] = {
					input = {
						["gold"] = 1000
					},
					cost = 15000,
				},
				[2] = {
					input = {
						["gold"] = 1000
					},
					cost = 35000,
				},
				[3] = {
					input = {
						["gold"] = 1000
					},
					cost = 55000,
				},
				[4] = {
					input = {
						["gold"] = 1000
					},
					cost = 75000,
				},
				[5] = {
					input = {
						["gold"] = 1000
					},
					cost = 95000,
				},
			}
		},
		{
			id = "missile_defense",
			lvl = {
				[1] = {
					cost = 100000
				},
			}
		},
		{
			id = "bridgehead",
			lvl = {
				[1] = {
					cost = 5000,
					damage_bonus = 1.35
				},
			}
		},
		{ 
			id = "weapon_factory",
			lvl = {
				[1] = {
					input = {
						["gold"] = 1600
					},
					output = {
						["resource:weapons"] = 400,
					},
					cost = 10000,
				},
				[2] = {
					input = {
						["gold"] = 3200
					},
					output = {
						["resource:weapons"] = 800,
					},
					cost = 20000,
				},
				[3] = {
					input = {
						["gold"] = 4800
					},
					output = {
						["resource:weapons"] = 1200,
					},
					cost = 30000,
				},
				[4] = {
					input = {
						["gold"] = 6400
					},
					output = {
						["resource:weapons"] = 1600,
					},
					cost = 40000,
				},
			}
		},
		{
			id = "aerodrome",
			lvl = {
				[1] = {
					air_attack_damage = 4000,
					break_building_chance = 0,
					cost = 10000,
				},
				[2] = {
					air_attack_damage = 6000,
					break_building_chance = 0.05,
					cost = 20000,
				},
				[3] = {
					air_attack_damage = 8000,
					break_building_chance = 0.1,
					cost = 30000,
				},
				[4] = {
					air_attack_damage = 10000,
					break_building_chance = 0.2,
					cost = 40000,
				},
				[5] = {
					air_attack_damage = 10000,
					break_building_chance = 0.3,
					cost = 50000,
				},
			}
		},
		{
			id = "chemical_factory",
			lvl = {
				[1] = {
					input = {
						["gold"] = 3000
					},
					output = {
						["resource:chemical_weapon"] = 1,
					},
					cost = 20000,
				},
			},
		},
		{
			id = "tank_factory",
			lvl = {
				[1] = {
					input = {
						["gold"] = 8000,
						["resource:weapons"] = 1200
					},
					output = {
						["resource:tank"] = 1,
					},
					cost = 50000,
				},
			},
		},
	},
	other = {
		{
			id = "port",
			lvl = {
				[1] = {
					cost = 5000
				}
			}
		},
		{
			id = "heavy_water_plant",
			lvl = {
				[1] = {
					input = {
						["gold"] = 2000
					},
					output = {
						["resource:heavy_water"] = 3,
					},
					cost = 30000
				},
			}
		},
		{ 
			id = "nuclear_reactor",
			lvl = {
				[1] = {
					input = {
						["resource:uranium"] = 1
					},
					output = {
						["gold"] = 100000,
					},
					cost = 50000,
				},
				[2] = {
					input = {
						["resource:uranium"] = 1
					},
					output = {
						["gold"] = 200000,
					},
					cost = 100000,
				},
			}
		},
		{ 
			id = "fusion_reactor",
			lvl = {
				[1] = {
					output = {
						["gold"] = 40000,
					},
					cost = 1000000
				}
			}
		},
	},
}
return t