local M = {}

local ai_utils = require "core.ai.ai_utils"
local ai_data = require "core.ai.ai_data"
local relations = require "core.relations"
local event_system = require "core.event_system"
local core = require "core.core"
local offers = require "core.offers"
local balance_of_power = require "core.ai.balance_of_power"
local buildings = require "core.ai.buildings"
local difficulty

local scenarios_modifiers = {
	lost = require "scripts.scenarios_modifiers.lost"
}

-- Local table with previous offers data. To prevent the bot from spamming offers
local sent_offers = {
	peace = {},
	pact = {},
	alliance = {},
	vassal = {},
}

local sent_offers_duration = 5

M.difficulty_list = {
	easy = require "core.ai.difficulty.easy",
	standard = require "core.ai.difficulty.standard",
	hard = require "core.ai.difficulty.hard",
	impossible = require "core.ai.difficulty.impossible",
}

local is_player_function

local function accept_offer(offer_id)
	core.accept_offer(offer_id, core.get_accept_offer_callback())
end

local function offer_vassalage(land)
	for k, v in pairs(game_data.lands[land].enemies) do
		if v ~= "Undeveloped_land" and game_data.lands[v].num_of_provinces <= 3 and game_data.lands[v].army * 3 < game_data.lands[land].army then
			if lume.random() < ai_data.chance_send_vassal
			or is_player_function(v) and lume.random() < ai_data.chance_send_vassal_to_player then
				-- print("offer vassalage:", land, v)
				core.vassal(land, v)
			end
		end
	end
end

local function braking()
	return lume.random() < ai_data.send_offer_chance
end

local function urge_allies(land)
	for k, v in pairs(game_data.lands[land].enemies) do
		core.urge_allies(land, v)
	end
end

local strategy_tree = {
	heavy_war = function(land)
		if not sent_offers.alliance[land] then
			for k, v in rpairs(game_data.lands[land].enemies) do
				if v ~= "Undeveloped_land" then
					for key, val in pairs(game_data.lands[v].enemies) do
						if val ~= "Undeveloped_land" and relations.available_alliance(land, val) and val ~= land
						and braking() then
							sent_offers.alliance[land] = sent_offers_duration
							core.alliance(land, val,{
								id = "common_enemy",
								land = v
							})
							break
						end
					end
				end
			end
		end
		local conquered = 0
		for k, v in pairs(game_data.lands[land].ai.strategy.wish) do
			if not game_data.provinces[v].water and game_data.provinces[v].o == land then
				conquered = conquered + 1
			end
		end
		if not sent_offers.peace[land] then
			if lume.random() < conquered / (#game_data.lands[land].ai.strategy.wish
			* #game_data.lands[land].ai.strategy.wish) or
			game_data.lands[land].ai.strategy.turns < 0 and lume.random() < game_data.lands[land].ai.strategy.turns / -20 then
				core.peace(land, game_data.lands[land].ai.strategy.target)
				sent_offers.peace[land] = sent_offers_duration
			end
		end
		offer_vassalage(land)
		urge_allies(land)
	end,
	ordinary_war = function(land)
		if not sent_offers.alliance[land] then
			for k, v in rpairs(game_data.lands[land].enemies) do
				if v ~= "Undeveloped_land" then
					for key, val in pairs(game_data.lands[v].enemies) do
						if val ~= "Undeveloped_land" and relations.available_alliance(land, val) and val ~= land
						and braking() then
							sent_offers.alliance[land] = sent_offers_duration
							core.alliance(land, val,{
								id = "common_enemy",
								land = v
							})
							break
						end
					end
				end
			end
		end
		local conquered = 0
		for k, v in pairs(game_data.lands[land].ai.strategy.wish) do
			if not game_data.provinces[v].water and game_data.provinces[v].o == land then
				conquered = conquered + 1
			end
		end
		if not sent_offers.peace[land] then
			if lume.random() < conquered / (#game_data.lands[land].ai.strategy.wish
			* #game_data.lands[land].ai.strategy.wish) or
			game_data.lands[land].ai.strategy.turns < 0 and lume.random() < game_data.lands[land].ai.strategy.turns / -20 then
				core.peace(land, game_data.lands[land].ai.strategy.target)
				sent_offers.peace[land] = sent_offers_duration
			end
		end
		offer_vassalage(land)
		urge_allies(land)
	end,
	easy_war = function(land)
		local conquered = 0
		for k, v in pairs(game_data.lands[land].ai.strategy.wish) do
			if not game_data.provinces[v].water and game_data.provinces[v].o == land then
				conquered = conquered + 1
			end
		end
		if not sent_offers.peace[land] then
			if lume.random() < conquered / (#game_data.lands[land].ai.strategy.wish
			* #game_data.lands[land].ai.strategy.wish) or
			game_data.lands[land].ai.strategy.turns < 0 and lume.random() < game_data.lands[land].ai.strategy.turns / -20 then
				core.peace(land, game_data.lands[land].ai.strategy.target)
				sent_offers.peace[land] = sent_offers_duration
			end
		end
		offer_vassalage(land)
	end,
	development = function(land)
		if ai_utils.buildings_percent(land) > 2
		or lume.random() < ai_data.chance_random_war then
			local target, fast_attack = ai_utils.find_target(land)
			if target then
				game_data.lands[land].ai.strategy.strategy_type = "preparation"
				game_data.lands[land].ai.strategy.target = target
				game_data.lands[land].ai.strategy.turns = math.floor(lume.random(ai_data.min_for_attack_turns, ai_data.max_for_attack_turns))
				if fast_attack then
					game_data.lands[land].ai.strategy.turns = 2
				end

				balance_of_power.prepare_pact(land, target, is_player_function)
			end
		end
	end,
	preparation = function(land)
		if game_data.lands[land].ai.strategy.turns < 4 and game_data.lands[land].ai.strategy.target then
			if not sent_offers.alliance[land] then
				for k, v in rpairs(game_data.lands[game_data.lands[land].ai.strategy.target].enemies) do
					if v ~= "Undeveloped_land" and v ~= land and braking() then
						sent_offers.alliance[land] = sent_offers_duration
						core.alliance(land, v,  {
							id = "common_enemy",
							land = game_data.lands[land].ai.strategy.target
						})
						break
					end
				end
			end
		end
		 if game_data.lands[land].ai.strategy.turns == 0 and game_data.lands[land].ai.strategy.target then
			if relations.available_war(land, game_data.lands[land].ai.strategy.target) and not relations.is_vassal(land) then
				game_data.lands[land].ai.strategy.strategy_type = "preparation"
				game_data.lands[land].ai.strategy.wish = ai_utils.get_wanted_provinces(land, game_data.lands[land].ai.strategy.target)
				game_data.lands[land].ai.strategy.turns = math.floor(
				lume.random(ai_data.min_planned_expansion_duration, ai_data.max_planned_expansion_duration)) -- Planned duration of the war
				-- relations.register_war(land, game_data.lands[land].ai.strategy.target, {
					-- id = "expansion"
				-- })
				if not game_data.lands[game_data.lands[land].ai.strategy.target].defeated then
					offers.register("war", land, game_data.lands[land].ai.strategy.target)
				end
			end
		 end
	end
}

local function universal_ai_actions(land)
	if game_data.lands[land].vassal then
		local c = 0
		if game_data.lands[game_data.lands[land].vassal].ai.strategy.strategy_type == "heavy_war" then
			c = ai_data.rebellion_heavy_war_chance
		elseif game_data.lands[game_data.lands[land].vassal].ai.strategy.strategy_type == "ordinary_war" then
			c = ai_data.rebellion_ordinary_war_chance
		end
		if lume.random() < c then
			core.revolt(game_data.lands[land].vassal, land)
		end
	end
end

local function get_advantage(land)
	local land_points = get_land_points(land)
	local enemy_points = 0
	for k, v in pairs(game_data.lands[land].enemies) do
		if v ~= "Undeveloped_land" then
			-- print("Get land points:", land, v)
			enemy_points = enemy_points + get_land_points(v)
		end
	end
	return land_points/enemy_points
end

local function get_strategy(land)
	local s
	if lume.count(game_data.lands[land].enemies, function(x) return x ~= "Undeveloped_land" end) > 0 then
		if ai_utils.difficult_situation(land) then
			s = "heavy_war"
		elseif get_advantage(land) > 1.5 then
			s = "easy_war"
		else
			s = "ordinary_war"
		end
	else
		if game_data.lands[land].ai.strategy.target then
			s = "preparation"
		else
			s = "development"
		end
	end
	if s ~= "preparation" then
		game_data.lands[land].ai.strategy.target = nil
		game_data.lands[land].ai.strategy.wish = {}
		game_data.lands[land].ai.strategy.turns = 0
	end
	return s
end

local function calc_strategy(land)
	game_data.lands[land].ai.strategy.strategy_type = get_strategy(land)
	game_data.lands[land].tax = ai_data.strategy[game_data.lands[land].ai.strategy.strategy_type].tax

	local t = {
		"republic", "trade_republic", "democracy", "monarchy", "theocracy", "communism", "fascism", "anarchism"
	}

	if game_data.step - game_data.lands[land].changed_ideology >= game_values.ideology_cooldown + math.floor(lume.random(10, 100)) then
		core.set_ideology(land, lume.randomchoice(t))
	end

	strategy_tree[game_data.lands[land].ai.strategy.strategy_type](land)
	universal_ai_actions(land)
end

local function calc_diplomacy(land)
	if scenarios_modifiers[game_data.id] and scenarios_modifiers[game_data.id].blocked_diplomacy then
		return
	end
	local offers_list = offers.get_offers(land)
	for k, v in pairs(offers_list) do
		-- print("Offer for land:", land, k, v)
		if v[2] == "peace" then
			-- perfomance.continue_state("peace")
			if ai_utils.difficult_situation(land) then
				accept_offer(v[1])
			end
			-- perfomance.finish_state("peace")
		elseif v[2] == "pact" then
			-- perfomance.continue_state("pact")
			if ai_utils.accept_pact(land, v[3]) then
				accept_offer(v[1])
			end
			-- perfomance.finish_state("pact")
		elseif v[2] == "alliance" then
			-- perfomance.continue_state("alliance")
			if ai_utils.accept_alliance(land, v[3]) then
				accept_offer(v[1])
			end
			-- perfomance.finish_state("alliance")
		elseif v[2] == "vassal" then
			-- perfomance.continue_state("vassal")
			-- print("Check vassal offer: ", v[1], v[3], land)
			if game_data.lands[land].num_of_provinces <= 3 and game_data.lands[land].army * 3 < game_data.lands[v[3]].army then
				accept_offer(v[1])
			end
			-- perfomance.finish_state("vassal")
		elseif v[2] == "trade" then
			-- perfomance.continue_state("trade")
			-- pprint("Parse trade format: ", v)
			if ai_utils.parse_trade(v) then
				accept_offer(v[1])
			end
			-- perfomance.finish_state("trade")
		end
	end
end

local function calc_expenses(land)
	-- print(game_data.lands[land].ai.strategy.strategy_type)
	if game_data.step == 0 then
		return
	end
	local budget = ai_data.strategy[game_data.lands[land].ai.strategy.strategy_type].budget
	local army_budget = math.floor((game_data.lands[land].economy.balance * 2 +
	game_data.lands[land].money > 0 and game_data.lands[land].money / 2 or 0) * budget.army)

	if army_budget < 0 then
		army_budget = 0
	end

	ai_utils.balance_army(land, army_budget * game_values.army_cost, difficulty)

	buildings.build(land, budget)

	-- no_enemies means that there is no enemies or civilization can't attack enemy
	if ai_utils.no_enemies(land) and #game_data.lands[land].enemies > 1 then
		ai_utils.help_ally(land)
	end

end

local function calc_technology(land)
	local available_technology = {}
	for k, v in pairs(technology_data) do
		if check_technology(k, land) == "available" then
			table.insert(available_technology, k)
		end
	end
	if #available_technology > 0 then
		game_data.lands[land].selected_technology = lume.randomchoice(available_technology)
	end
end

local function calc_skills(land)
	local available_skills = {}
	for k, v in pairs(skills_data) do
		if check_skill(k, land) == "available" then
			available_skills[k] = v.cost * v.cost * v.cost -- to learn skills not only the first
		end
	end
	if next(available_skills) then
		local skill = lume.weightedchoice(available_skills)
		if skill and game_data.lands[land].skills >= skills_data[skill].cost then
			core.open_skill(land, skill)
		end
	end
end

-- For debug
function check_bad_army()
	for k, v in pairs(game_data.provinces) do
		for key, val in pairs(v.a) do
			-- assert(val >= 0, "Error:"..k..key..val)
		end
	end
end

local function calc_army(land)
	-- pprint("AI path: "..land, game_data.lands[land].ai.path)
	if game_data.step == 0 then
		return
	end
	if not scenarios_modifiers[game_data.id] or not scenarios_modifiers[game_data.id].only_move then
		ai_utils.shell(land)
		ai_utils.planes(land)
		ai_utils.chemical(land)
		ai_utils.tank(land)
		ai_utils.nuclear(land)
	end
	difficulty.move_army(land)
	ai_utils.return_army(land)
	-- print("after:")
	-- check_bad_army()
end

function M.init(_is_player_function)
	is_player_function = _is_player_function

	local events_functions = {
		registered_peace = function(land1, land2)
			balance_of_power.update_balance(is_player_function)
		end,
		registered_pact = function(land1, land2)
			balance_of_power.update_balance(is_player_function)
		end,
		registered_war = function(land1, land2)
			balance_of_power.registered_war(land1, land2, is_player_function)
			balance_of_power.update_balance(is_player_function)
		end,
		registered_alliance = function(land1, land2)
			balance_of_power.update_balance(is_player_function)
		end,
		broken_alliance = function(land1, land2)
			balance_of_power.update_balance(is_player_function)
		end,
		registered_vassal = function(owner, vassal)
			balance_of_power.update_balance(is_player_function)
		end,
		independence = function(owner, vassal)
			balance_of_power.update_balance(is_player_function)
		end,
		revolt = function(owner, vassal)
			balance_of_power.update_balance(is_player_function)
		end,
		ruined_civilization = function(land, destroyer)
			balance_of_power.update_balance(is_player_function)
		end,
	}
	for k, v in pairs(events_functions) do
		event_system.on(k, v)
	end
end

function M.handle()
	if tutorial_mode then
		return
	end

	-- Update the difficulty data so that we can change the difficulty during the game
	difficulty = M.difficulty_list[game_data.difficulty]

	-- local profiler = require "scripts.utils.profiler"
	-- profiler.start()

	-- local ok, err = pcall(function()
		for k, v in pairs(sent_offers) do
			for key, val in pairs(v) do
				if val <= 0 then
					sent_offers[k][key] = nil
				end
			end
		end

		-- perfomance.register_state("strategy")
		-- perfomance.register_state("expenses")
		-- perfomance.register_state("technology")
		-- perfomance.register_state("skills")
		-- perfomance.register_state("army")

		for k, v in pairs(game_data.lands) do
			if k ~= "Undeveloped_land" and not is_player_function(k)
			and not v.defeated then
				if scenarios_modifiers[game_data.id] and scenarios_modifiers[game_data.id].blocked_diplomacy then
					calc_army(k)
				else
					calc_strategy(k)
					calc_army(k)
					calc_technology(k)
					calc_skills(k)
				end
			end
		end
		for k, v in pairs(game_data.lands) do
			if k ~= "Undeveloped_land" and not is_player_function(k) and not v.defeated then
				v.ai.strategy.turns = v.ai.strategy.turns - 1
			end
		end
	-- end)
	-- if not ok then
		-- print("Error!!! Data: ", err)
	-- end
	-- profiler.stop()
	-- profiler.report("profiler.log")
end

function M.late_handle()
	if tutorial_mode then
		return
	end
	-- perfomance.register_state("peace")
	-- perfomance.register_state("pact")
	-- perfomance.register_state("alliance")
	-- perfomance.register_state("vassal")
	-- perfomance.register_state("trade")
	for k, v in pairs(game_data.lands) do
		if k ~= "Undeveloped_land" and not is_player_function(k)
		and not v.defeated then
			calc_diplomacy(k)
			calc_expenses(k)
		end
	end
	-- perfomance.state_results("peace")
	-- perfomance.state_results("pact")
	-- perfomance.state_results("alliance")
	-- perfomance.state_results("vassal")
	-- perfomance.state_results("trade")
end

return M