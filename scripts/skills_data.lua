-- Bonuses:
-- money_per_turn - more money per turn
-- science_per_turn - more science per turn
-- science_for_ally
-- population_increase - more population increase per turn
-- hiring_an_army_less
-- more_movement_points
-- trade
-- capital_defense
-- pay_less_for_an_army_in_an_ally_lands
-- consequence
-- army_defense
-- army_attack
-- fortress_gives_defense_bonus
-- refund
-- firing_line
-- shell_immunity
-- cheaper_buildings
-- true_need
-- vassals_attack_bonus
-- vassality
-- vassals_income

local skills_data = {
	diplomacy_skills_left_1 = {
		cost = 2,
		bonuses = {{"more_movement_points", 2}}
	},
	diplomacy_skills_left_2 = {
		cost = 4,
		requirement = "diplomacy_skills_left_1",
		bonuses = {{"population_increase", 1.1}}
	},
	diplomacy_skills_left_3 = {
		cost = 6,
		requirement = "diplomacy_skills_left_2",
		bonuses = {{"population_increase", 1.4}}
	},
	diplomacy_skills_left_4 = {
		cost = 8,
		requirement = "diplomacy_skills_left_3",
		bonuses = {{"science_per_turn",2}, {"money_per_turn", 0.85}}
	},
	diplomacy_skills_center_1 = {
		cost = 2,
		bonuses = {{"money_per_turn", 1.05}}--{"trade"}}
	},
	diplomacy_skills_center_2 = {
		cost = 4,
		requirement = "diplomacy_skills_center_1",
		bonuses = {{"capital_defense", 1.25}}
	},
	diplomacy_skills_center_3 = {
		cost = 6,
		requirement = "diplomacy_skills_center_2",
		bonuses = {{"pay_less_for_an_army_in_an_ally_lands"}}
	},
	diplomacy_skills_center_4 = {
		cost = 8,
		requirement = "diplomacy_skills_center_3",
		bonuses = {{"consequence"}}
	},
	diplomacy_skills_right_1 = {
		cost = 2,
		bonuses = {{"vassality"}}
	},
	diplomacy_skills_right_2 = {
		cost = 4,
		requirement = "diplomacy_skills_right_1",
		bonuses = {{"vassals_income", 1.25}}
	},
	diplomacy_skills_right_3 = {
		cost = 6,
		requirement = "diplomacy_skills_right_2",
		bonuses = {{"vassals_income", 1.5}}
	},
	diplomacy_skills_right_4 = {
		cost = 8,
		requirement = "diplomacy_skills_right_3",
		bonuses = {{"vassals_attack_bonus", 1.5}}
	},
	army_skills_left_1 = {
		cost = 2,
		bonuses = {{"army_defense", 1.1}}
	},
	army_skills_left_2 = {
		cost = 4,
		requirement = "army_skills_left_1",
		bonuses = {{"fortress_gives_defense_bonus"}}
	},
	army_skills_left_3 = {
		cost = 6,
		requirement = "army_skills_left_2",
		bonuses = {{"refund"}}
	},
	army_skills_left_4 = {
		cost = 8,
		requirement = "army_skills_left_3",
		bonuses = {{"army_defense", 1.2}}
	},
	army_skills_center_1 = {
		cost = 2,
		bonuses = {{"army_attack", 1.05}}
	},
	army_skills_center_2 = {
		cost = 4,
		requirement = "army_skills_center_1",
		bonuses = {{"army_attack", 1.1}}
	},
	army_skills_center_3 = {
		cost = 6,
		requirement = "army_skills_center_2",
		bonuses = {{"army_attack", 1.15}}
	},
	army_skills_center_4 = {
		cost = 8,
		requirement = "army_skills_center_3",
		bonuses = {{"firing_line"}}
	},
	army_skills_right_1 = {
		cost = 2,
		bonuses = {{"hiring_an_army_less", 1.05}}
	},
	army_skills_right_2 = {
		cost = 4,
		requirement = "army_skills_right_1",
		bonuses = {{"hiring_an_army_less", 1.1}}
	},
	army_skills_right_3 = {
		cost = 6,
		requirement = "army_skills_right_2",
		bonuses = {{"shell_immunity"}}
	},
	army_skills_right_4 = {
		cost = 8,
		requirement = "army_skills_right_3",
		bonuses = {{"army_attack", 1.5}}
	},
	economy_skills_left_1 = {
		cost = 2,
		bonuses = {{"science_per_turn", 1.05}}
	},
	economy_skills_left_2 = {
		cost = 4,
		requirement = "economy_skills_left_1",
		bonuses = {{"science_per_turn", 1.1}}
	},
	economy_skills_left_3 = {
		cost = 6,
		requirement = "economy_skills_left_2",
		bonuses = {{"science_for_ally", 1.15}}
	},
	economy_skills_left_4 = {
		cost = 8,
		requirement = "economy_skills_left_3",
		bonuses = {{"science_for_ally", 1.3}}
	},
	economy_skills_center_1 = {
		cost = 2,
		bonuses = {{"cheaper_buildings", 1.05}}
	},
	economy_skills_center_2 = {
		cost = 4,
		requirement = "economy_skills_center_1",
		bonuses = {{"cheaper_buildings", 1.1}}
	},
	economy_skills_center_3 = {
		cost = 6,
		requirement = "economy_skills_center_2",
		bonuses = {{"money_per_turn", 1.1}}
	},
	economy_skills_center_4 = {
		cost = 8,
		requirement = "economy_skills_center_3",
		bonuses = {{"true_need"}}
	},
	economy_skills_right_1 = {
		cost = 2,
		bonuses = {{"money_per_turn", 1.05}}
	},
	economy_skills_right_2 = {
		cost = 4,
		requirement = "economy_skills_right_1",
		bonuses = {{"money_per_turn", 1.1}}
	},
	economy_skills_right_3 = {
		cost = 6,
		requirement = "economy_skills_right_2",
		bonuses = {{"money_per_turn", 1.15}}
	},
	economy_skills_right_4 = {
		cost = 8,
		requirement = "economy_skills_right_3",
		bonuses = {{"money_per_turn", 1.4}}
	},
}
return skills_data