local M = {
	chance_random_war = 0.01,
	chance_send_vassal = 0.1,
	chance_send_vassal_to_player = 0.8,
	chance_conquer_undeveloped_land = 0.05,
	min_move_army_percent = 0.4,
	max_move_army_percent = 1,

	min_for_attack_turns = 3,
	max_for_attack_turns = 14,
	min_planned_expansion_duration = 2,
	max_planned_expansion_duration = 7,

	rebellion_heavy_war_chance = 0.02,
	rebellion_ordinary_war_chance = 0.002,

	send_offer_chance = 0.2,

	strategy = {
		heavy_war = {
			budget = {
				army = 0.4,
				economy_buildings = 0,
				science_buildings = 0,
				defense_buildings = 0.5,
				other_buildings = 0.1,
				trade = 0
			},
			tax = 0.6
		},
		ordinary_war = {
			budget = {
				army = 0.5,
				economy_buildings = 0.1,
				science_buildings = 0.1,
				defense_buildings = 0.2,
				other_buildings = 0.1,
				trade = 0
			},
			tax = 0.4
		},
		easy_war = {
			budget = {
				army = 0.4,
				economy_buildings = 0.1,
				science_buildings = 0.15,
				defense_buildings = 0.15,
				other_buildings = 0.2,
				trade = 0
			},
			tax = 0.3
		},
		development  = {
			budget = {
				army = 0.01,
				economy_buildings = 0.34,
				science_buildings = 0.2,
				defense_buildings = 0.2,
				other_buildings = 0.25,
				trade = 0
			},
			tax = 0.2
		},
		preparation = {
			budget = {
				army = 0.1,
				economy_buildings = 0.1,
				science_buildings = 0.1,
				defense_buildings = 0.5,
				other_buildings = 0.2,
				trade = 0
			},
			tax = 0.3
		},
	},
}

return M