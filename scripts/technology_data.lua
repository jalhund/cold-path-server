-- Bonuses:
-- building_<building_id>_<lvl> - player can build building with <building_id> id
-- money_per_turn - more money per turn
-- science_per_turn - more science per turn
-- population_increase - more population increase per turn
-- metallurgy_<x> - show hidden gold resources with lvl <x>
-- army_defense - army defense bonus
-- army_attack - army attack bonus
-- shell - shell is available
-- pact - allow sign pacts
-- alliance - allow sign alliance
-- building_efficiency - buildings more efficiency
-- nuclear_weapon

local t = {
	t_1_2 = {
		cost = 2.7,
		requirements = nil,
		bonuses = {{"population_increase", 1.05}}
	},
	t_1_3 = {
		cost = 2.7,
		requirements = nil,
		bonuses = {{"building_fortress_1"}}
	},
	t_2_1 = {
		cost = 3.7,
		requirements = {"t_1_2"},
		bonuses = {{"money_per_turn", 1.02}}
	},
	t_2_2 = {
		cost = 3.7,
		requirements = {"t_1_2"},
		bonuses = {{"building_mine_1"}}
	},
	t_2_3 = {
		cost = 3.7,
		requirements = {"t_1_3"},
		bonuses = {{"pact"}}
	},
	t_3_1 = {
		cost = 5.1,
		requirements = {"t_2_1"},
		bonuses = {{"building_university"}}
	},
	t_3_2 = {
		cost = 5.1,
		requirements = {"t_2_2"},
		bonuses = {{"building_port"}}
	},
	t_3_3 = {
		cost = 5.1,
		requirements = {"t_2_3"},
		bonuses = {{"building_tower"}}
	},
	t_4_1 = {
		cost = 7,
		requirements = {"t_3_1"},
		bonuses = {
			{"metallurgy_1"}
		}
	},
	t_4_2 = {
		cost = 7,
		requirements = {"t_3_2"},
		bonuses = {{"building_mint_1"}}
	},
	t_5_1 = {
		cost = 9.6,
		requirements = {"t_4_1"},
		bonuses = {{"building_hospital"}}
	},
	t_5_2 = {
		cost = 9.6,
		requirements = {"t_4_2"},
		bonuses = {{"building_mine_2"}}
	},
	t_5_3 = {
		cost = 9.6,
		requirements = {"t_4_2", "t_3_3"},
		bonuses = {{"building_fortress_2"}}
	},
	t_5_4 = {
		cost = 9.6,
		requirements = {"t_5_3"},
		bonuses = {{"alliance"}}
	},
	t_6_2 = {
		cost = 13.1,
		requirements = {"t_5_2"},
		bonuses = {{"money_per_turn", 1.05}}
	},
	t_6_3 = {
		cost = 13.1,
		requirements = {"t_5_3"},
		bonuses = {{"building_beacon"}}
	},
	t_7_1 = {
		cost = 17.9,
		requirements = {"t_5_1"},
		bonuses = {{"metallurgy_2"}}
	},
	t_7_2 = {
		cost = 17.9,
		requirements = {"t_6_2"},
		bonuses = {{"building_mint_2"}}
	},
	t_7_3 = {
		cost = 17.9,
		requirements = {"t_6_3"},
		bonuses = {{"shell"}}
	},
	t_7_4 = {
		cost = 17.9,
		requirements = {"t_7_3"},
		bonuses = {{"building_weapon_factory_1"}},
	},
	t_8_1 = {
		cost = 24.5,
		requirements = {"t_7_1","t_7_2"},
		bonuses = {{"building_bank_1"}}
	},
	t_8_2 = {
		cost = 24.5,
		requirements = {"t_7_2"},
		bonuses = {{"money_per_turn", 1.05}}
	},
	t_8_3 = {
		cost = 24.5,
		requirements = {"t_7_3"},
		bonuses = {{"building_weapon_factory_2"}}
	},
	t_9_2 = {
		cost = 33.6,
		requirements = {"t_8_1","t_8_2"},
		bonuses = {{"building_bridgehead"}}
	},
	t_9_3 = {
		cost = 33.6,
		requirements = {"t_8_3"},
		bonuses = {{"building_weapon_factory_3"}}
	},
	t_10_1 = {
		cost = 45.9,
		requirements = {"t_9_2"},
		bonuses = {{"building_mine_3"}}
	},
	t_10_2 = {
		cost = 45.9,
		requirements = {"t_9_2"},
		bonuses = {{"science_per_turn", 1.2}}
	},
	t_11_1 = {
		cost = 62.8,
		requirements = {"t_10_1"},
		bonuses = {{"building_bank_2"}}
	},
	t_11_2 = {
		cost = 62.8,
		requirements = {"t_10_2"},
		bonuses = {{"building_air_defense_1"}}
	},
	t_11_3 = {
		cost = 62.8,
		requirements = {"t_9_3", "t_10_2"},
		bonuses = {{"building_fortress_3"}}
	},
	t_12_2 = {
		cost = 85.9,
		requirements = {"t_11_1","t_11_2"},
		bonuses = {{"building_mint_3"}}
	},
	t_12_3 = {
		cost = 85.9,
		requirements = {"t_11_3"},
		bonuses = {{"building_weapon_factory_4"}}
	},
	t_13_2 = {
		cost = 117.5,
		requirements = {"t_12_2"},
		bonuses = {{"building_mine_4"}}
	},
	t_13_3 = {
		cost = 117.5,
		requirements = {"t_12_3"},
		bonuses = {{"building_tank_factory"}}
	},
	t_14_1 = {
		cost = 160.8,
		requirements = {"t_13_2"},
		bonuses = {{"building_science_center_1"}}
	},
	t_14_2 = {
		cost = 160.8,
		requirements = {"t_13_2"},
		bonuses = {{"building_air_defense_2"}}
	},
	t_14_3 = {
		cost = 160.8,
		requirements = {"t_13_3"},
		bonuses = {{"building_fortress_4"}}
	},
	t_15_1 = {
		cost = 219.9,
		requirements = {"t_14_1"},
		bonuses = {{"population_increase", 1.4}}
	},
	t_15_2 = {
		cost = 219.9,
		requirements = {"t_14_2"},
		bonuses = {{"building_mine_5"}}
	},
	t_15_3 = {
		cost = 219.9,
		requirements = {"t_14_3"},
		bonuses = {{"building_aerodrome_1"}}
	},
	t_15_4 = {
		cost = 219.9,
		requirements = {"t_14_3"},
		bonuses = {{"building_chemical_factory"}}
	},
	t_15_5 = {
		cost = 219.9,
		requirements = {"t_14_1"},
		bonuses = {{"building_science_center_2"}}
	},
	t_16_1 = {
		cost = 300.9,
		requirements = {"t_15_1"},
		bonuses = {{"building_bank_3"}}
	},
	t_16_2 = {
		cost = 300.9,
		requirements = {"t_15_2"},
		bonuses = {{"building_air_defense_3"}}	},
	t_16_3 = {
		cost = 300.9,
		requirements = {"t_15_3"},
		bonuses = {{"building_fortress_5"}}
	},
	t_17_1 = {
		cost = 411.6,
		requirements = {"t_16_1"},
		bonuses = { {"uranium"}, {"building_heavy_water_plant"}}
	},
	t_17_2 = {
		cost = 411.6,
		requirements = {"t_16_2"},
		bonuses = {{"metallurgy_3"}}
	},
	t_17_3 = {
		cost = 411.6,
		requirements = {"t_16_3", "t_16_2"},
		bonuses = {{"building_aerodrome_2"}}
	},
	t_18_1 = {
		cost = 563.1,
		requirements = {"t_17_1"},
		bonuses = {{"building_nuclear_reactor_1"}}
	},
	t_18_2 = {
		cost = 563.1,
		requirements = {"t_17_1"},
		bonuses = {{"nuclear_weapon"}}
	},
	t_18_3 = {
		cost = 563.1,
		requirements = {"t_17_3"},
		bonuses = {{"building_aerodrome_3"}}
	},
	t_19_1 = {
		cost = 770.3,
		requirements = {"t_18_1","t_18_2"},
		bonuses = {{"building_nuclear_reactor_2"}}
	},
	t_19_2 = {
		cost = 770.3,
		requirements = {"t_18_2", "t_18_3"},
		bonuses = {{"building_air_defense_4"}}
	},
	t_19_3 = {
		cost = 770.3,
		requirements = {"t_18_3"},
		bonuses = {{"building_aerodrome_4"}}
	},
	t_20_1 = {
		cost = 1053.8,
		requirements = {"t_19_1"},
		bonuses = {{"building_fusion_reactor"}}
	},
	t_20_2 = {
		cost = 1053.8,
		requirements = {"t_19_2"},
		bonuses = {{"building_air_defense_5"}}
	},
	t_20_3 = {
		cost = 1053.8,
		requirements = {"t_19_3"},
		bonuses = {{"building_aerodrome_5"}}
	},
	t_20_4 = {
		cost = 1053,-- 1441.6,
		requirements = {"t_19_2"},
		bonuses = {{"building_missile_defense"}}
	},
}
return t