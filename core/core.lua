local M = {}

local calc_functions = require "core.calc_functions"
local relations = require "core.relations"
local offers = require "core.offers"
local event_system = require "core.event_system"
local scenarios_modifiers = {
	consequences = require "scripts.scenarios_modifiers.consequences"
}

local is_player
local difficulty_list
local game_end_callback
local update_land_data
local accept_offer_callback

function M.set_difficulty_list(list)
	difficulty_list = list
end

function M.set_is_player_function(callback)
	is_player = callback
end

function M.set_game_end_callback(callback)
	game_end_callback = callback
end

function M.set_update_land_data_callback(callback)
	update_land_data = callback
end

function M.set_accept_offer_callback(callback)
	accept_offer_callback = callback
end

function M.get_accept_offer_callback()
	return accept_offer_callback
end

local function year_increase()
	if game_data.year < 1400 then
		return 3
	elseif game_data.year < 1600 then
		return 2
	elseif game_data.year < 1800 then
		return 1/2
	elseif game_data.year < 2000 then
		return 1/4
	elseif game_data.year < 2100 then
		return 1/6
	elseif game_data.year < 2200 then
		return 1/12
	else
		return 1/64
	end
end

function M.next()
	-- game_data.previous_moves = deepcopy(game_data.current_moves)
	game_data.current_moves = {}
	game_data.previous_shell = deepcopy(game_data.current_shell)
	game_data.current_shell = {}
	game_data.previous_tank = deepcopy(game_data.current_tank)
	game_data.current_tank = {}
	game_data.previous_chemical = deepcopy(game_data.current_chemical)
	game_data.current_chemical = {}
	game_data.previous_explosions = deepcopy(game_data.current_explosions)
	game_data.current_explosions = {}
	game_data.previous_planes = deepcopy(game_data.current_planes)
	game_data.current_planes = {}
	game_data.used_shell = {}
	game_data.used_tank = {}
	game_data.used_chemical = {}
	game_data.used_explosions = {}
	game_data.used_planes = {}

	army_functions.validate_army()

	offers.handle()
	calc_functions.calc_lands(game_end_callback, is_player, difficulty_list)

	army_functions.validate_army()
	
	game_data.year = game_data.year + year_increase()
	game_data.step = game_data.step + 1

	for k, v in pairs(game_data.consequence_data) do
		game_data.consequence_data[k] = game_data.consequence_data[k] - 1
		if game_data.consequence_data[k] <= 0 then
			game_data.consequence_data[k] = nil
		end
	end

	for k, v in pairs(game_data.lands) do
		if k ~= "Undeveloped_land" and v.num_of_provinces == 0 and not v.defeated then
			event_system.dispatch("ruined_civilization", k, v.last_attacked)
			if game_data.lands[k].money > 0 then
				game_data.lands[v.last_attacked].money = game_data.lands[v.last_attacked].money + game_data.lands[k].money
			end
			for key, val in pairs(game_data.lands[k].resources) do
				if val > 0 then
					game_data.lands[v.last_attacked].resources[key] = game_data.lands[v.last_attacked].resources[key] + val
				end
			end
			clear_data_about(k)
			v.defeated = true
			game_end_callback(k)
		end
	end

	-- local winners = {}
	for k, v in pairs(game_data.lands) do
		if k ~= "Undeveloped_land" and not v.defeated then
			local win = true
			for key, val in pairs(game_data.lands) do
				if key ~= k and key ~= "Undeveloped_land" and not val.defeated then
					if not relations.check_alliance(k, key)
					and not relations.check_vassal(k, key)
					and not relations.check_vassal(key, k) then
						win = false
					end
				end
			end
			if win then
				game_end_callback(k, true)
				break
				-- table.insert(winners, k)
			end
		end
	end

	-- calc_functions.write_history()
end

function M.recruit(land,province, count)
	game_data.provinces[province].l_a = game_data.provinces[province].l_a + count
	game_data.provinces[province].p = game_data.provinces[province].p - count
	game_data.lands[land].money = game_data.lands[land].money - count/army_functions.army_recruit_cost(land)
	game_data.lands[land].movement_points = game_data.lands[land].movement_points - 1
end

function M.move(land,from,to,amount)
	--print("move",from,to,amount)
	table.insert(game_data.queue, { land, "move", from,to,amount})
	army_functions.set_army(from, army_functions.get_army(from, land) - amount, land)
	game_data.lands[land].movement_points = game_data.lands[land].movement_points - 1
end

function M.dissolve(land, province, percent)
	local count = math.floor(army_functions.get_army(province, land) * percent)
	game_data.provinces[province].p = (game_data.provinces[province].p + count)
	if lume.match(game_data.lands[land].bonuses, function(x) return x[1] == "refund" end) then
		game_data.dissolved_army_for_gold[land] = game_data.dissolved_army_for_gold[land] or 0 + count * game_values.refund_value
	end
	army_functions.set_army(province,math.floor(army_functions.get_army(province, land) - count), land)
	game_data.lands[land].movement_points = game_data.lands[land].movement_points - 1
end

function M.shell(land, from, to, count)
	game_data.lands[land].resources.weapons = math.floor(game_data.lands[land].resources.weapons - count/game_values.shell_cost)
	table.insert(game_data.used_shell, {land, from, to})
	table.insert(game_data.queue, { land, "shell", from,to,count})
	game_data.lands[land].movement_points = game_data.lands[land].movement_points - 1
end

function M.open_skill(land, skill)
	game_data.lands[land].skills = game_data.lands[land].skills - skills_data[skill].cost
	table.insert(game_data.lands[land].opened_skills, skill)
	for k, v in pairs(skills_data[skill].bonuses) do
		if not v[2] then
			v[2] = 0
		end
		v[3] = "skills"
		table.insert(game_data.lands[land].bonuses, v)
	end
end

function M.set_tax(land, tax)
	game_data.lands[land].tax = tax
end

function M.set_ideology(land, ideology)
	game_data.lands[land].ideology = ideology
	game_data.lands[land].changed_ideology = game_data.step
end

function M.build(land, province, building_id)

	game_data.lands[land].money = game_data.lands[land].money - get_building_cost(land, building_id, game_data.provinces[province].b[building_id])
	game_data.provinces[province].b[building_id] = game_data.provinces[province].b[building_id] and 
	game_data.provinces[province].b[building_id] + 1 or 1

	local lvl = game_data.provinces[province].b[building_id]
	local resource_cost = get_building_data(building_id).lvl[lvl].resource_cost

	if resource_cost then
		for k, v in pairs(resource_cost) do
			game_data.lands[land].resources[k] = game_data.lands[land].resources[k] - v
		end
	end

	if scenarios_modifiers[game_data.id] then
		scenarios_modifiers[game_data.id].build(land, province, building_id)
	end
end

function M.destroy(land, province, building_id)
	game_data.lands[land].money = game_data.lands[land].money +
	math.floor(get_building_cost(land, building_id, game_data.provinces[province].b[building_id] - 1)
		* game_values.destroy_building_refund)

	local lvl = game_data.provinces[province].b[building_id]
	local resource_cost = get_building_data(building_id).lvl[lvl].resource_cost

	if resource_cost then
		for k, v in pairs(resource_cost) do
			game_data.lands[land].resources[k] = game_data.lands[land].resources[k] + math.floor(v * game_values.destroy_building_refund)
		end
	end

	game_data.provinces[province].b[building_id] = nil


	if scenarios_modifiers[game_data.id] then
		scenarios_modifiers[game_data.id].destroy(land, province, building_id)
	end


end

function M.peace(from, to, reason)
	if relations.is_vassal(to) then
		to = game_data.lands[to].vassal
	end
	if not relations.is_vassal(from) then
		offers.register("peace", from, to, reason)
	end
end

function M.pact(from, to, reason)
	if relations.is_vassal(to) then
		to = game_data.lands[to].vassal
	end
	if not relations.is_vassal(from) then
		print("Register pact offer:", from, to)
		offers.register("pact", from, to, reason)
	end
end

function M.war(from, to, reason)
	if relations.is_vassal(to) then
		to = game_data.lands[to].vassal
	end
	if not relations.is_vassal(from) then
		log(from.." declared war on "..to)
		offers.register("war", from, to, reason)
	end
end

function M.alliance(from, to, reason)
	if relations.is_vassal(to) then
		to = game_data.lands[to].vassal
	end
	if not relations.is_vassal(from) then
		offers.register("alliance", from, to, reason)
	end
end

function M.break_alliance(from, to, reason)
	if relations.is_vassal(to) then
		to = game_data.lands[to].vassal
	end
	if not relations.is_vassal(from) then
		log(from.." declared break_alliance on "..to)
		offers.register("break_alliance", from, to, reason)
	end
end

function M.air_attack(land, from, to)
	table.insert(game_data.used_planes, {land, from})
	table.insert(game_data.queue, { land, "air_attack", from, to, game_data.provinces[from].b.aerodrome})
	game_data.lands[land].movement_points = game_data.lands[land].movement_points - 1
end

function M.tank(land, from, to)
	game_data.lands[land].resources.tank = game_data.lands[land].resources.tank - 1
	table.insert(game_data.used_tank, {land, to})
	table.insert(game_data.queue, { land, "tank", from, to})
	game_data.lands[land].movement_points = game_data.lands[land].movement_points - 1
end

function M.chemical_weapon(land, from, to)
	local from_province = from
	local province = to

	game_data.lands[land].resources.chemical_weapon = game_data.lands[land].resources.chemical_weapon - 1
	table.insert(game_data.used_chemical, {land, province})
	table.insert(game_data.queue, { land, "chemical", from_province, province})
	game_data.lands[land].movement_points = game_data.lands[land].movement_points - 1
end

function M.nuclear_weapon(land, province)
	-- Выбираем случайную провинцию атакующей страны для запуска ракеты
	local attacking_provinces = {}
	for k, v in pairs(game_data.provinces) do
		if v.o == land and not v.water then
			table.insert(attacking_provinces, k)
		end
	end
	
	local from_province = attacking_provinces[math.random(#attacking_provinces)]
	
	game_data.lands[land].resources.uranium = game_data.lands[land].resources.uranium - game_values.nuclear_weapon_cost_uranium
	table.insert(game_data.used_explosions, {land, province, from_province})
	table.insert(game_data.queue, { land, "nuclear", province, from_province})
	game_data.lands[land].movement_points = game_data.lands[land].movement_points - 1
	-- pprint("Nuclear queue:", game_data.queue)
end

function M.vassal(land1, land2, reason)
	if not relations.is_vassal(land1) and not relations.is_vassal(land2) then
		log(land1.." send vassal offer to "..land2)
		offers.register("vassal", land1, land2, reason)
	end
end

function M.revolt(owner, vassal, reason)
	offers.register("revolt", vassal, owner, reason)
end

function M.independence(owner, vassal)
	relations.independence(vassal)
end

function M.trade(from, to, from_list, to_list)
	offers.register("trade", from, to, {
		player_trade_list = from_list,
		civilization_trade_list = to_list,
	})
end

function M.urge_allies(land, enemy)
	if relations.is_vassal(enemy) then
		enemy = relations.is_vassal(enemy)
	end
	for k, v in pairs(game_data.lands[land].allies) do
		if not game_data.lands[v].defeated then
			if relations.available_war(v, enemy) then
				offers.register("war", v, enemy)
			end
		end
	end
end

function M.support_revolt(from, to, value)
	game_data.lands[from].money = game_data.lands[from].money - value
	table.insert(game_data.lands[to].rebellion_support, {
		from, value, game_data.step
	})
end

function M.accept_offer(offer_id)
	local offer = offers.get_offer_by_id(offer_id)
	if not offer then
		print("Error! No offer!")
		return
	end
	-- log("Accepted offer:", offer[1], offer[2], offer[3], offer[4])
	if (offer[3] ~= "system" and game_data.lands[offer[3]].defeated) or game_data.lands[offer[4]].defeated then
		-- log("One civilization does not exists. Return")
		return
	end
	if offer[2] == "peace" then
		if relations.available_peace(offer[3], offer[4]) then
			relations.register_peace(offer[3], offer[4])
			accept_offer_callback(offer)
			-- log("Register peace")
		else
			-- log("Peace unavailable. Ignore")
		end
	elseif offer[2] == "pact" then
		if relations.available_pact(offer[3], offer[4]) then
			relations.register_pact(offer[3], offer[4])
			accept_offer_callback(offer)
			-- log("Register pact")
		else
			-- log("Pact unavailable. Ignore")
		end
	elseif offer[2] == "alliance" then
		if relations.available_alliance(offer[3], offer[4]) then
			relations.register_alliance(offer[3], offer[4])
			accept_offer_callback(offer)
			-- log("Register alliance")
		else
			-- log("Alliance unavailable. Ignore")
		end
	elseif offer[2] == "trade" then
		if relations.available_trade(offer[3], offer[4]) then
			-- pprint("Confirmed trade. Trade data is:", offer[5].player_trade_list)
			for i = 2, #offer[5].player_trade_list do
				-- ??? I think there is a mistake here. I will have to check when I add trading to the game
				local it = offer[5].player_trade_list[i].item
				local val = offer[5].player_trade_list[i].value
				if it == "peace" and relations.available_peace(offer[3], offer[4]) then
					relations.register_peace(offer[3], offer[4])
					accept_offer_callback({
						offer[1], "peace", offer[3], offer[4]
					})
				elseif it == "pact" and relations.available_pact(offer[3], offer[4]) then
					relations.register_pact(offer[3], offer[4])
					accept_offer_callback({
						offer[1], "pact", offer[3], offer[4]
					})
				elseif it == "alliance" and relations.available_alliance(offer[3], offer[4]) then
					relations.register_alliance(offer[3], offer[4])
					accept_offer_callback({
						offer[1], "alliance", offer[3], offer[4]
					})
				elseif it == "declare_war" and relations.available_war(offer[3], val) and not game_data.lands[offer[3]].vassal then
					if relations.is_vassal(val) then
						val = game_data.lands[val].vassal
					end
					offers.register("war", offer[3], val)
				elseif it == "gold" and game_data.lands[offer[3]].money >= val then
					game_data.lands[offer[3]].money = game_data.lands[offer[3]].money - val
					game_data.lands[offer[4]].money = game_data.lands[offer[4]].money + val
				elseif it == "per_turn" and game_data.lands[offer[3]].economy.balance >= val then
					table.insert(game_data.trade, {
						"per_turn", offer[3], offer[4], val, game_values.trade_gold_per_turn_duration
					})
				elseif it == "resource" then
					local resource = string.gsub(val, "%d", "")
					resource = string.gsub(resource, ":", "")
					local count = val:gsub("%D+", "")
					count = tonumber(count)
					if game_data.lands[offer[3]].resources[resource] >= count then
						game_data.lands[offer[3]].resources[resource] = game_data.lands[offer[3]].resources[resource] - count
						game_data.lands[offer[4]].resources[resource] = game_data.lands[offer[4]].resources[resource] + count
					end
				elseif it == "province" and game_data.provinces[val].o == offer[3] then
					local r_a = game_data.provinces[val].a[offer[3]] or 0
					game_data.provinces[val].o = offer[4]
					game_data.provinces[val].a = {}
					game_data.provinces[val].a[offer[4]] = r_a
				end
			end

			for i = 2, #offer[5].civilization_trade_list do
				local it = offer[5].civilization_trade_list[i].item
				local val = offer[5].civilization_trade_list[i].value
				if it == "declare_war" and relations.available_war(offer[4], val) and not game_data.lands[offer[4]].vassal then
					if relations.is_vassal(val) then
						val = game_data.lands[val].vassal
					end
					offers.register("war", offer[4], val)
				elseif it == "gold" and game_data.lands[offer[4]].money >= val and val >= 0 then
					game_data.lands[offer[4]].money = game_data.lands[offer[4]].money - val
					game_data.lands[offer[3]].money = game_data.lands[offer[3]].money + val
				elseif it == "per_turn" and game_data.lands[offer[4]].economy.balance >= val and val >= 0 then
					table.insert(game_data.trade, {
						"per_turn", offer[4], offer[3], val, game_values.trade_gold_per_turn_duration
					})
				elseif it == "resource" then
					local resource = string.gsub(val, "%d", "")
					resource = string.gsub(resource, ":", "")
					local count = val:gsub("%D+", "")
					count = tonumber(count)
					if game_data.lands[offer[4]].resources[resource] >= count and count >= 0 then
						game_data.lands[offer[4]].resources[resource] = game_data.lands[offer[4]].resources[resource] - count
						game_data.lands[offer[3]].resources[resource] = game_data.lands[offer[3]].resources[resource] + count
					end
				elseif it == "province" and game_data.provinces[val].o == offer[4] then
					local r_a = game_data.provinces[val].a[offer[4]] or 0
					game_data.provinces[val].o = offer[3]
					game_data.provinces[val].a = {}
					game_data.provinces[val].a[offer[3]] = r_a
				end
			end

			update_land_data(offer[3])
			update_land_data(offer[4])
			log("Trade finished")
		else
			log("Trade unavailable. Ignore")
		end
	elseif offer[2] == "vassal" then
		if relations.available_vassal(offer[3], offer[4]) then
			relations.register_vassal(offer[3], offer[4])
			accept_offer_callback(offer)
			log("Register vassalage")
		else
			log("vassalage unavailable. Ignore")
		end
	elseif offer[2] == "discontent_pay_off" then
		-- print("Pay off: ", offer[5])
		game_data.lands[offer[4]].money = game_data.lands[offer[4]].money - offer[5]
		table.insert(game_data.lands[offer[4]].actions_taken, {"pay_off", game_data.step})
		update_land_data(offer[4])
	elseif offer[2] == "discontent_disperse" then
		for k, v in pairs(game_data.provinces) do
			if v.o == offer[4] then
				v.p = v.p * 0.88
			end
		end
		game_data.lands[offer[4]].money = game_data.lands[offer[4]].money - offer[5]
		table.insert(game_data.lands[offer[4]].actions_taken, {"disperse", game_data.step})
		update_land_data(offer[4])
	elseif offer[2] == "discontent_independence" then
		offers.register("war", offer[4], offer[3])
	end
end

return M
