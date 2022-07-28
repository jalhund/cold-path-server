local M = {}

local buildings_calc_functions = require "core.buildings_calc_functions"
local relations = require "core.relations"
local ideology = require "core.ideology"

local scenarios_modifiers = {
	consequences = require "scripts.scenarios_modifiers.consequences",
	lost = require "scripts.scenarios_modifiers.lost",
}

local technology_bonuses_functions = {
	money = function(land)
		local b = 1
		for k, v in pairs(game_data.lands[land].bonuses) do
			if v[1] == "money_per_turn" and v[3] == "technology" then
				b = b * v[2]
			end
		end
		return b
	end,
	science = function(land)
		local b = 1
		for k, v in pairs(game_data.lands[land].bonuses) do
			if v[1] == "science_per_turn" and v[3] == "technology" then
				b = b * v[2]
			end
		end
		return b
	end,
	population_increase = function(land)
		local b = 1
		for k, v in pairs(game_data.lands[land].bonuses) do
			if v[1] == "population_increase" and v[3] == "technology" then
				b = b * v[2]
			end
		end
		return b
	end
}

local skills_bonuses_functions = {
	money = function(land)
		local enemy_is_near_and_dangerous = false
		for i, val in ipairs(game_data.lands[land].enemies) do
			if game_data.lands[val].army > game_data.lands[land].army and is_neighbour(land, val) 
			and not enemy_is_near_and_dangerous
			and val ~= "Undeveloped_land" then
				enemy_is_near_and_dangerous = true
			end
		end
		local b = 1
		for k, v in pairs(game_data.lands[land].bonuses) do
			if v[1] == "money_per_turn" and v[3] == "skills" then
				b = b * v[2]
			elseif v[1] == "true_need" and enemy_is_near_and_dangerous then
				b = b * 2
			end
		end
		return b
	end,
	science = function(land)
		local b = 1
		for k, v in pairs(game_data.lands[land].bonuses) do
			if v[1] == "science_per_turn" and v[3] == "skills" then
				b = b * v[2]
			end
			if v[1] == "science_for_ally" and v[3] == "skills" then
				for key, val in pairs(game_data.lands[land].allies) do
					if not game_data.lands[val].defeated then
						b = b * v[2]
					end
				end
			end
		end
		return b
	end,
	population_increase = function(land)
		local b = 1
		for k, v in pairs(game_data.lands[land].bonuses) do
			if v[1] == "population_increase" and v[3] == "skills" then
				b = b * v[2]
			end
		end
		return b
	end
}

local function calc_recruit()
	for k, v in pairs(game_data.provinces) do
		if not v.water then
			if not v.a[v.o] then
				v.a[v.o] = 0
			end
			v.a[v.o] = v.a[v.o] + v.l_a
			v.l_a = 0
		end
	end
end

local function calc_move()
	for k, v in pairs(game_data.queue) do
		--print("Steps:",k)
		if v[2] == "move" then
			army_functions.move_army(v[3], v[4], v[5], v[1])
		elseif v[2] == "shell" then
			army_functions.shell(v[1], v[3], v[4], v[5])
		elseif v[2] == "air_attack" then
			army_functions.air_attack(v[1], v[3], v[4])
		elseif v[2] == "tank" then
			army_functions.tank(v[1], v[3], v[4])
		elseif v[2] == "chemical" then
			army_functions.chemical(v[1], v[3], v[4])
		elseif v[2] == "nuclear" then
			army_functions.nuclear(v[1], v[3])
		end
	end
	game_data.queue = {}
end

local function calc_population()
	for k, v in pairs(game_data.lands) do
		v.population = 0
	end
	for k, v in pairs(game_data.provinces) do
		if not v.water and v.o ~= "Undeveloped_land" then
			local p = v.p
			if p > game_values.max_population then
				p = game_values.max_population
			end
			local population_increase_factor = 1 - p/game_values.max_population
			local increase_value = v.p * skills_bonuses_functions.population_increase(v.o)
			 * technology_bonuses_functions.population_increase(v.o) * population_increase_factor * 0.002
			* ideology.population_increase_bonus(v.o)
			increase_value = increase_value * (-4*game_data.lands[v.o].tax + 1.8)
			if v.p + increase_value < 100 and increase_value < 0 then
				increase_value = 0
			end
			v.p = v.p + increase_value
			game_data.lands[v.o].population = game_data.lands[v.o].population + v.p
		end
	end
end

local function get_min_technology_lvl(land)
    local min_lvl = 21
	for k, v in pairs(technology_data) do
		local lvl, n = k:match("t_(%d+)_(%d)")
		lvl = tonumber(lvl)
		if check_technology(k, land) == "available" then
			if lvl < min_lvl then
				min_lvl = lvl
			end
		end
	end
	return min_lvl
end

local function generate_new_land(land)
	print("NEW LAND: ", land)

	local new_land

	--
	local t = {
		lands = {},
		provinces = {},
		technology_lvl = get_min_technology_lvl(land)
	}

	local provinces

	for k, v in pairs(game_data.provinces) do
		if v.o == land then
			for key, val in pairs(game_data.lands) do
				if val.capital == k and val.defeated then
					new_land = key
					t.lands[new_land] = {
						name = val.name,
						capital = val.capital,
						color = deepcopy(val.color)
					}
					provinces = {
						k
					}
				end
			end
		end
	end

	local available_provinces = {}
	local capital_province

	pprint("Rebels: ", provinces, new_land)

	if not provinces then
		provinces = {}
		for k, v in pairs(game_data.provinces) do
			if v.o == land then
				local path = path_to_province(k, game_data.lands[land].capital or get_province_for_land(land))
				-- pprint("Path check", k, game_data.lands[land].capital or get_province_for_land(land))
				-- pprint(path)
				if path then
					available_provinces[k] = #path
				end
			end
		end
		if count_elements_in_table(available_provinces) == 0 then
			print("Error! Available 0 provinces! (generate_new_land - calc_functions.lua)")
			return
		end
		capital_province = lume.weightedchoice(available_provinces)
	else
		capital_province = provinces[1]
	end

	provinces = {
		capital_province
	}
	available_provinces = {}

	local max_distance = 0
	for k, v in pairs(game_data.provinces) do
		if v.o == land and k ~= capital_province then
			local path = path_to_province(k, capital_province)
			if path then
				available_provinces[k] = #path
				if #path > max_distance then
					max_distance = #path
				end
			end
		end
	end

	-- pprint("Available provinces 1:", available_provinces)

	for k, v in pairs(available_provinces) do
		available_provinces[k] = max_distance - v + 1
		-- Math pow to make neighboring provinces revolt more often than non-neighboring
		available_provinces[k] = math.pow(available_provinces[k], 10)/100
	end

	-- pprint("Available provinces 2:", available_provinces)

	local number_of_provinces_in_revolt = math.floor(lume.random(get_num_of_provinces(land) * 0.15, get_num_of_provinces(land) * 0.3))
	if number_of_provinces_in_revolt < 1 then
		number_of_provinces_in_revolt = 1
	end

	for i = 1, number_of_provinces_in_revolt do
		local p = lume.weightedchoice(available_provinces)
		table.insert(provinces, p)
		available_provinces[p] = nil
	end

	if not new_land then
		-- Don't create a new country if there are too many
		if count_elements_in_table(game_data.lands) >= 60 then
			return
		end
		local n = 0
		repeat
			new_land = land.."_"..n
			n = n + 1
		until not game_data.lands[new_land]

		local adjectives = {
			"north", "east", "west", "south", "true", "holy","socialist", "great", "revolutionary", "nationalist", "new",
			"", "", "", "", "", "", "", "", "", ""
		}

		local nouns = {
			"empire", "federation", "republic", "monarchy"
		}
		local adjective = lume.randomchoice(adjectives)
		local noun = lume.randomchoice(nouns)
		t.lands[new_land] = {
			name = adjective..(adjective ~= "" and " " or "")..noun.." "..land,
			capital = capital_province,
			color = {
				math.floor(lume.random()*255), math.floor(lume.random()*255), math.floor(lume.random()*255)
			},
			rebels = true,
			rebelled_against = land
		}
	end

	local validate_scenario = require "scripts.validate_scenario"

	pprint("t:", t)

	validate_scenario.validate(t, true) -- true is is_new_land parameter

	game_data.lands[new_land] = deepcopy(t.lands[new_land])
	for k, v in pairs(provinces) do
		game_data.provinces[v].o = new_land
		game_data.provinces[v].a[new_land] = game_data.provinces[v].a[land] or 0
		game_data.provinces[v].a[land] = nil
	end
	pprint("land:", game_data.lands[new_land])
	game_data.lands[new_land].money = math.floor(lume.random(1000, 15000))

	-- pprint("New land provinces:", land, provinces)


	table.insert(game_data.lands[land].actions_taken, {"separatism", game_data.step})
	return new_land
end

local function calc_war_weariness()
	for k, v in pairs(game_data.lands) do
		if k ~= "Undeveloped_land" and not v.defeated then
		    local l = ideology.get_war_weariness_bonus(k)
			if no_enemies(k) then
				v.war_weariness = v.war_weariness + 1
			else
				v.war_weariness = v.war_weariness - l
			end
			if v.war_weariness < game_values.min_war_weariness then
				v.war_weariness = game_values.min_war_weariness
			elseif v.war_weariness > game_values.max_war_weariness then
				v.war_weariness = game_values.max_war_weariness
			end
		end
	end
end

local function calc_stability(difficulty_list)
	for k, v in pairs(game_data.lands) do
		for i = #v.rebellion_support, 1, -1 do
			if game_data.step - v.rebellion_support[i][3] > game_values.rebellion_action_duration then
				table.remove(v.rebellion_support, i)
			end
		end

		for i = #v.actions_taken, 1, -1 do
			if game_data.step - v.actions_taken[i][2] > game_values.rebellion_action_duration then
				table.remove(v.actions_taken, i)
			end
		end

		if k ~= "Undeveloped_land" and not v.defeated and get_num_of_provinces(k) > 10 and ideology.available_revolt(k) then

			local s = get_stability(k)
			if s > difficulty_list[game_data.difficulty].discontent_independence then

				local new_land = generate_new_land(k)

				if new_land then
					table.insert(game_data.old_offers, {
						#game_data.old_offers + 1, "discontent_independence", new_land, k
					})
				end
			elseif s > difficulty_list[game_data.difficulty].discontent_disperse and not lume.match(game_data.lands[k].actions_taken, function(x) return x[1] == "disperse" end) then
				local income = game_data.lands[k].economy.income_total
				local min, max = income * 0.6, income * 1.9

				table.insert(game_data.old_offers, {
					#game_data.old_offers + 1, "discontent_disperse", "system", k, math.floor(lume.random(min, max))
				})
			elseif s > difficulty_list[game_data.difficulty].discontent_pay_off and not lume.match(game_data.lands[k].actions_taken, function(x) return x[1] == "pay_off" end) then
				local income = game_data.lands[k].economy.income_total
				local min, max = income * 0.6, income * 1.3

				if income > 0 then
					table.insert(game_data.old_offers, {
						#game_data.old_offers + 1, "discontent_pay_off", "system", k, math.floor(lume.random(min, max))
					})
				end
			end
		end
	end
end

local function stabilize_population()
	for k, v in pairs(adjacency_map) do
		for key, val in pairs(v) do
			if not game_data.provinces[k].water and not game_data.provinces[val].water then
				if game_data.provinces[k].p > game_data.provinces[val].p and 
				game_data.provinces[val].o ~= "Undeveloped_land" then
					local population_count = (game_data.provinces[k].p - game_data.provinces[val].p)
					if game_data.provinces[k].o == game_data.provinces[val].o then
						population_count = population_count * game_values.stabilize_province_speed_land
					else
						population_count = population_count * game_values.stabilize_province_speed_common
					end
					population_count = math.floor(population_count)
					game_data.provinces[k].p = game_data.provinces[k].p - population_count
					game_data.provinces[val].p = game_data.provinces[val].p + population_count
				end
			end
		end
	end
end

local function calc_scenarios_modifiers(game_end_callback)
	if scenarios_modifiers[game_data.id] then
		scenarios_modifiers[game_data.id].calc(game_end_callback)
	end
end

local function calc_economy(is_player, difficulty_list)
	for k, v in pairs(game_data.lands) do
		v.economy = {
			income = {
				population = 0,
				technology = 0,
				skills = 0,
				buildings = 0,
				trade = 0,
				vassality = 0
			},
			expense = {
				army = 0,
				buildings = 0,
				trade = 0,
				vassality = 0
			},
			inflation = 0,
			income_total = 0,
			expense_total = 0,
			balance = 0,
		}
	end
	--Income
	for k, v in pairs(game_data.lands) do
		v.economy.income.population = math.pow(v.population, game_values.degree_of_dependence_of_income_on_population)
				* math.pow(v.tax, 0.25) * 0.5 * ideology.gold_per_turn_bonus(k)
	end

	for k, v in pairs(game_data.lands) do
		v.economy.income.technology = v.economy.income.population *
		(technology_bonuses_functions["money"](k) - 1)
	end

	for k, v in pairs(game_data.lands) do
		v.economy.income.skills = v.economy.income.population *
		(skills_bonuses_functions["money"](k) - 1)
		if game_data.dissolved_army_for_gold[k] then
			v.economy.income.skills = v.economy.income.skills + game_data.dissolved_army_for_gold[k]
			game_data.dissolved_army_for_gold[k] = nil
		end
	end

	for k, v in pairs(game_data.lands) do
		if v.vassal then
			local b = 1
			for key, val in pairs(game_data.lands[v.vassal].bonuses) do
				if val[1] == "vassals_income" then
					b = b * val[2]
				end
			end
			v.economy.income.vassality = v.economy.income.population * (b - 1)
			local tax = game_values.vassal_tax_standard
			game_data.lands[v.vassal].economy.income.vassality = game_data.lands[v.vassal].economy.income.vassality + 
			v.economy.income.population * tax
			v.economy.expense.vassality = v.economy.expense.vassality + 
			v.economy.income.population * tax
		end
	end

	--Expense
	for k, v in pairs(game_data.provinces) do
		for key, val in pairs(v.a) do
			local b = 1
			if v.water then
				b = game_values.water_army_cost
			end
			if not v.water and relations.check_alliance(key, v.o)
			and lume.match(game_data.lands[key].bonuses, function(x) return x[1] == "pay_less_for_an_army_in_an_ally_lands" end) then
				b = game_values.pay_less_for_an_army_in_an_ally_lands
			end
			if not is_player(key) then
				b = b * difficulty_list[game_data.difficulty].maintenance_cost_modifier
			end

			b = b * ideology.maintenance_bonus(key)

			game_data.lands[key].economy.expense.army = game_data.lands[key].economy.expense.army + val / game_values.army_cost * b
		end
	end
end

local function calc_trade()
	for i = #game_data.trade, 1, -1 do
		local v = game_data.trade[i]
		pprint("Trade:", i, v)
		if v[1] == "per_turn" then
			if not game_data.lands[v[2]].defeated and not game_data.lands[v[3]].defeated and
			not relations.check_war(v[2], v[3]) and game_data.lands[v[2]].money > 0 then
				game_data.lands[v[2]].economy.expense.trade = game_data.lands[v[2]].economy.expense.trade + v[4]
				game_data.lands[v[3]].economy.income.trade = game_data.lands[v[3]].economy.income.trade + v[4]
			end
			if v[5] == 0 then
				table.remove(game_data.trade, i)
			end
			v[5] = v[5] - 1
		end
	end
end

local function calc_inflation(land)
	local i = 0
	local k = (game_data.lands[land].money + game_data.lands[land].economy.income_total) / game_data.lands[land].economy.income_total
	-- print("Calc k : ", game_data.lands[land].money, game_data.lands[land].economy.income_total, k)
	local finish_inflation = game_values.finish_inflation / ideology.get_inflation_bonus(land)
	if k > game_values.start_inflation then
		if k > finish_inflation then
			k = finish_inflation
		end
		i = k / finish_inflation * game_values.max_inflation
	end
	return i
end

local function calc_balance()
	for k, v in pairs(game_data.lands) do
		v.economy.income_total = v.economy.income.population + v.economy.income.technology + v.economy.income.skills +
		v.economy.income.buildings  + v.economy.income.trade
		v.economy.expense_total = v.economy.expense.army + v.economy.expense.buildings + v.economy.expense.trade
		v.economy.inflation = calc_inflation(k)
		-- print("Inflation is: ", v.economy.inflation)
		-- print("Inflation: Without and with: ", v.economy.income_total, game_data.lands[k].money,
			-- v.economy.income_total * (1 - v.economy.inflation))
		v.economy.balance = v.economy.income_total * (1 - v.economy.inflation) - v.economy.expense_total
		v.money = v.money + v.economy.balance
	end
end

local function calc_num_of_provinces()
	for k, v in pairs(game_data.lands) do
		v.num_of_provinces = 0
	end
	for k, v in pairs(game_data.provinces) do
		if not v.water then
			game_data.lands[v.o].num_of_provinces = game_data.lands[v.o].num_of_provinces + 1
		end
	end
end

local function calc_science()
	for k, v in pairs(game_data.lands) do
		v.total_science_per_turn = 0
		v.science_per_turn = {
			base = 0,
			buildings = 0,
			technology = 0,
			skills = 0
		}
	end
	-- for k, v in pairs(game_data.provinces) do
	-- 	if not v.water then
	-- 		game_data.lands[v.o].science_per_turn.provinces = game_data.lands[v.o].science_per_turn.provinces + 0.1
	-- 	end
	-- end
	for k, v in pairs(game_data.lands) do
		v.science_per_turn.base = game_values.base_science_per_turn
	end
end

local function calc_technology()
	for k, v in pairs(game_data.lands) do
		v.total_science_per_turn = v.science_per_turn.base + v.science_per_turn.buildings
		v.total_science_per_turn = v.total_science_per_turn * ideology.science_per_turn_bonus(k)
		v.science_per_turn.technology = v.science_per_turn.technology
		 + v.total_science_per_turn * technology_bonuses_functions.science(k)
		 v.science_per_turn.skills = v.science_per_turn.skills
		 + v.total_science_per_turn * skills_bonuses_functions.science(k)
		v.total_science_per_turn = v.science_per_turn.base + v.science_per_turn.buildings + v.science_per_turn.technology +
		v.science_per_turn.skills
	end
	for k, v in pairs(game_data.lands) do
		v.science = v.science + v.total_science_per_turn
	end
	for k, v in pairs(game_data.lands) do
		if v.selected_technology and technology_data[v.selected_technology].cost <= v.science then
			v.science = v.science - technology_data[v.selected_technology].cost
			table.insert(v.opened_technology, v.selected_technology)
			for key, val in pairs(technology_data[v.selected_technology].bonuses) do
				if not val[2] then
					val[2] = 0
				end
				val[3] = "technology"
				table.insert(v.bonuses, val)
				-- pprint("Added bonus:", v.bonuses)
			end
			v.selected_technology = nil
		end
	end
end


local function calc_skills()
	for k, v in pairs(game_data.lands) do
		if game_data.step < game_values.max_skills / game_values.skills_per_turn then
			v.skills = v.skills + game_values.skills_per_turn
		end
	end
end

local function calc_movement_points()
	for k, v in pairs(game_data.lands) do
		v.movement_points = 1
	end
	for k, v in pairs(game_data.provinces) do
		if not v.water then
			game_data.lands[v.o].movement_points = game_data.lands[v.o].movement_points + 1
		end
	end

	for k, v in pairs(game_data.lands) do
		for key, val in pairs(v.bonuses) do
			if val[1] == "more_movement_points" then
				v.movement_points = v.movement_points + val[2]
			end
		end
	end
end

function M.write_history()
	for k, v in pairs(game_data.lands) do
		v.history.money[game_data.step] = v.money
		v.history.income[game_data.step] = v.economy.income_total
		v.history.expense[game_data.step] = v.economy.expense_total
		v.history.total_science_per_turn[game_data.step] = v.total_science_per_turn
		v.history.army[game_data.step] = v.army
		v.history.money[game_data.step] = v.money
	end
end

local function set_lands_values()
	for k, v in pairs(game_data.lands) do
		v.army = 0
		v.population = 0
		v.num_of_provinces = 0
	end
	for k, v in pairs(game_data.provinces) do
		for key, val in pairs(v.a) do
		 	game_data.lands[key].army = game_data.lands[key].army + val
		end
		if not v.water then
			game_data.lands[v.o].population = game_data.lands[v.o].population + v.p
			game_data.lands[v.o].num_of_provinces = game_data.lands[v.o].num_of_provinces + 1
		end
	end
end

local function calc_pacts()
	for i = #game_data.pacts_data, 1, -1 do
		--pprint(game_data.pacts_data[i])
		game_data.pacts_data[i][3] = game_data.pacts_data[i][3] - 1
		if game_data.pacts_data[i][3] == 0 then
			remove_from_table(game_data.pacts_data[i][1], game_data.lands[game_data.pacts_data[i][2]].pacts)
			remove_from_table(game_data.pacts_data[i][2], game_data.lands[game_data.pacts_data[i][1]].pacts)
			table.remove(game_data.pacts_data, i)
		end
	end
end

function M.calc_lands(game_end_callback, is_player, difficulty_list)
	-- game_data.previous_moves = {}
	calc_recruit()
	check_bad_army()
	calc_move()
	calc_population()
	calc_economy(is_player, difficulty_list)
	calc_trade()
	calc_war_weariness()
	stabilize_population()
	calc_scenarios_modifiers(game_end_callback)
	ideology.handle_defeat(game_end_callback)
	calc_num_of_provinces()
	calc_science()
	calc_skills()
	calc_movement_points()
	buildings_calc_functions.calc_buildings()
	calc_balance()
	calc_stability(difficulty_list)
	calc_technology()
	set_lands_values()
	calc_pacts()
end

return M