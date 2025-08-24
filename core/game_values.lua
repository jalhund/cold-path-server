local t = {
	stabilize_province_speed_common = 0,
	stabilize_province_speed_land = 0.001,
	-- rapid_population_growth_limit = 10000,

	-- province_stability_change = 17,
	min_population = 1000,
	max_population = 1000000,

	degree_of_dependence_of_income_on_population  = 0.75,

	skills_per_turn = 0.25,
	army_recruit_cost = 0.25,
	army_cost = 1,
	water_army_cost = 2,
	pact_duration = 15,
	base_science_per_turn = 0.6,
	buildings_limit = 4,
	buildings_limit_capital = 6,
	destroy_building_refund = 0.5,

	trade_gold_per_turn_duration = 15,

	start_inflation = 5,
	finish_inflation = 30,
	max_inflation = 0.95,

	attack_bonus_without_capital_less = 0.3, -- 1 - 0.3 = 0.7 = 70%

	max_skills = 60,

	shell_cost = 1, --one shell for 1 weapons, 0.5 - one shell for 2 weapons
	shell_damage = 1,

	tank_damage = 5000,

	pay_less_for_an_army_in_an_ally_lands = 0.5,

	consequence_effect = 0.5,
	consequence_time = 5,

	chemical_weapon_damage = 0.3,

	nuclear_weapon_damage = 0.9,
	nuclear_weapon_damage_radius = 0.75,
	nuclear_weapon_destroy_buildings_chance = 0.5,
	nuclear_weapon_cost_uranium = 3,

	fortress_gives_defense_bonus = 1.1,
	refund_value = 0.75,
	firing_line_attack_bonus = 2,
	shell_immunity_value = 0.9,

	vassal_tax_standard = 0.25,

	science_building_factor = 0.8,

	heavy_water_for_reactor_cooling = 6,
	max_heavy_water_in_reactor = 16,

	limit_num_draw_line_of_movement = 50,

	megarefrigerator_effect = 10,
	hospital_saving = 0.75,

	min_war_weariness = -50,
	max_war_weariness = 50,

	rebellion_action_duration = 10,

	missile_defense_chance = 0.9,

	ideology_cooldown = 30,
	ideology = {
		trade_republic_gold_per_turn_bonus = 2,
		trade_republic_maintenance_bonus = 3,

		democracy_population_increase_bonus = 2,
		democracy_science_increase_bonus = 1.5,
		democracy_attack_bonus = 0.75,

		monarchy_defense_bonus_if_enemy_has_more_army = 1.5,
		monarchy_science_increase_bonus = 0.5,

		theocracy_recruit_cost_bonus = 2,
		theocracy_science_increase_bonus = 0.5,

		communism_damage_to_province = 0.2,
		communism_damage_to_all_provinces = 0.8,
		communism_damage_to_ignore = 0.2,
		communism_gold_per_turn_bonus = 0.6,

		fascism_attack_bonus_after_declaring_war = 1.8,
		fascism_attack_debuff = 0.75,
		fascism_attack_bonus_duration = 5,
		
		anarchism_attack_bonus = 1.07,
		anarchism_war_weariness_mod = 2,
		anarchism_inflation_mod = 5
	},
}
return t