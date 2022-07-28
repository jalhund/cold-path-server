local M = {}

local army_functions = require "core.army_functions"
local relations = require "core.relations"
local core = require "core.core"

function M.no_enemies(land)
	local l = true
	for k, v in pairs(game_data.lands[land].enemies) do
		if k ~= "Undeveloped_land" and M.available_for_attack(land, v) then
			l = false
		end
	end
	return l
end

function M.available_for_attack(from, to)
	local a = false
	for k, v in pairs(game_data.provinces) do
		if not v.water and v.o == from then
			if get_short_path_to_enemy(k, from, to) then
				a = true
			end
		end
	end
	return a
end

function M.buildings_percent(land)
	local l = 0
	local p = 0
	for k, v in pairs(game_data.provinces) do
		if not v.water and v.o == land then
			l = l + 1
			p = p + #v.b
		end
	end
	return p/l
end

function M.find_target(land)
	local t = {}

	local empty_table = true

	local max_points_land, max_points = get_max_points_land()

	log("Find target: ", land)
	if not no_enemies(max_points_land) and M.available_for_attack(land, max_points_land) then
		if lume.random() < 0.9 then
			log("attack great land", land, max_points_land)
			return max_points_land, true
		end
	end

	for k, v in pairs(game_data.lands) do
		if k ~= land and k ~= "Undeveloped_land" and not v.defeated and M.available_for_attack(land, k) then
			t[k] = get_land_points(k) / max_points * 100
			empty_table = false
		end
	end

	for k, v in pairs(t) do
		t[k] = 200 - t[k]
		if t[k] < 0 or t[k] ~= t[k] then
			t[k] = 0
		end
	end

	if empty_table then
		return nil
	else
		return lume.weightedchoice(t)
	end
end

function M.get_army_size(land)
	local s = 0
	for k, v in pairs(game_data.provinces) do
		for key, val in pairs(v.a) do
			if key == land then
				s = s + val
			end
		end
	end
	return s
end

function M.get_provinces_priority(land)
	local provinces_priority = {}
	for k, v in pairs(game_data.provinces) do
		if v.o == land then
			provinces_priority[k] = 1
		end
	end
	--[[print("After first balance")
	for k, v in pairs(provinces_priority) do
		print("priority:", k, v)
	end--]]
	for k, v in pairs(provinces_priority) do
		for key, val in pairs(game_data.lands[land].enemies) do
			if val ~= "Undeveloped_land" then
				if is_neighbour_province(k, val) then
					provinces_priority[k] = 3
				end
			end
		end
	end
	--[[print("After second balance")
	for k, v in pairs(provinces_priority) do
		print("priority:", k, v)
	end--]]
	for k, v in pairs(provinces_priority) do
		if v == 1 then
			for key, val in pairs(get_list_adjacency_map(k)) do
				--print("Without neighbor province:", k , without_neighbour_province(k))
				if provinces_priority[val] == 3 or not without_neighbour_province(k) then
					provinces_priority[k] = 2
				end
			end
		end
	end
	-- for k, v in pairs(provinces_priority) do
		-- if game_data.provinces[k].s < 100 then
			-- print("Province priority: 100: ", k)
			-- provinces_priority[k] = 3
		-- end
	-- end

	return provinces_priority
end

function M.balance_army(land, need_army_value, difficulty_data)
	local provinces_priority = M.get_provinces_priority(land)
	--[[print("After Third balance")
	for k, v in pairs(provinces_priority) do
		print("priority:", k, v)
	end--]]
	local proportions = {
		0.01, 0.29, 0.7
	}

	local t = {} --List army of province
	local factor = 0
	for k, v in pairs(provinces_priority) do
		factor = factor + proportions[v]
	end
	for k, v in pairs(provinces_priority) do
		-- print("set v by priority:", k, need_army_value, factor, proportions[v])
		t[k] = need_army_value/factor*proportions[v]*(lume.random(0.98, 1.02))
		--print("On province need army:", k, t[k], need_army_value, factor, proportions[v])
	end

	for k, v in pairs(t) do
		if army_functions.get_army(k, land) < v
		and game_data.lands[land].money > 0 then
			-- print("First checK: ",k, v)
			if v > army_functions.get_army(k, land) + game_data.provinces[k].p - game_values.min_population then
				if game_data.provinces[k].p >= game_values.min_population then
					v = army_functions.get_army(k, land) + game_data.provinces[k].p - game_values.min_population
				else
					v = army_functions.get_army(k, land)
				end
			end
			-- print("Second checK: ",k, v)
			if v > game_data.lands[land].money * army_functions.army_recruit_cost(land) then 
				v = math.floor(lume.random() * game_data.lands[land].money * army_functions.army_recruit_cost(land))
				* difficulty_data.recruit_cost_modifier
			end
			-- print("Third checK: ",k, v)
			game_data.lands[land].money = game_data.lands[land].money - (v - army_functions.get_army(k, land))
					/ army_functions.army_recruit_cost(land) * difficulty_data.recruit_cost_modifier
			-- print("Population, current_army and v: ",game_data.provinces[k].p , game_data.provinces[k].a , v)
			-- print("Before on a < v",k, game_data.provinces[k].p, army_functions.get_army(k, land), v)
			game_data.provinces[k].p = math.floor(game_data.provinces[k].p + army_functions.get_army(k, land) - v)
			if army_functions.get_army(k, land) < 0 then
				-- print("Error on a < v",k, game_data.provinces[k].p, army_functions.get_army(k, land), v)
			end
			army_functions.set_army(k,math.floor(v), land)
		elseif army_functions.get_army(k, land) > v then
			-- print("v < cur army:",k, army_functions.get_army(k, land), v, game_data.provinces[k].p)
			if game_data.provinces[k].o == land then
				game_data.provinces[k].p = math.floor(game_data.provinces[k].p + army_functions.get_army(k, land) - v)
			end
			--game_data.lands[land].money = game_data.lands[land].money + math.floor(game_data.provinces[k].p + game_data.provinces[k].a - v)
			if army_functions.get_army(k, land) < 0 then
				-- print("error: a< 0", k< army_functions.get_army(k, land), v)
			end
			army_functions.set_army(k,math.floor(v), land)
		end
	end
end

function M.return_army(land)
	if no_enemies(land) then
		for k, v in pairs(game_data.provinces) do
			if v.water or v.o ~= land then
				if v.a[land] and v.a[land] > 0 then
					local path = get_path_to_specific_enemy_province(k, land, land, function(list)
						return lume.randomchoice(list)
					end)
					if path then
						core.move(land, k, path[#path-1], v.a[land])
					end
				end
			end
		end
	end
end

local function get_near_enemy_army_provinces(land)
	local t = {}
	for k, v in pairs(game_data.provinces) do
		if v.o == land then
			for key, val in pairs(get_adjacency(k)) do
				for key_, val_ in pairs(game_data.provinces[val].a) do
					if val_ and val_ > 0 and key_ ~= "Undeveloped_land" and find_in_table(key_, game_data.lands[land].enemies) then
						t[k] = val
					end
				end
			end
		end
	end
	return t
end

function M.shell(land)
	local r = game_data.lands[land].resources.weapons / game_values.shell_cost
	local t = get_near_enemy_army_provinces(land)
	if r > 0 then
		for k, v in pairs(t) do
			local count = army_functions.get_army(v)
			if count > r then
				count = r
			end
			if count > army_functions.get_army(k, land) then
				count = army_functions.get_army(k, land)
			end
			if count > 0 and not lume.match(game_data.used_shell, function(x) return x[1] == land and x[2] == k
		and x[3] == v end) then
				core.shell(land, k, v, count)
				r = r - count
			end
		end
	end
end

local function use_plane(land, from, to)
	if not lume.match(game_data.used_planes, function(x) return x[1] == land and x[2] == from end)
	and army_functions.get_army(to) > 0 then
		core.air_attack(land, from, to)
	end
end

function M.planes(land)
	local aero_provinces = {}
	for k, v in pairs(game_data.provinces) do
		if v.o == land and v.b.aerodrome then
			table.insert(aero_provinces, k)
		end
	end
	for k, v in pairs(aero_provinces) do
		for key, val in pairs(get_adjacency(v)) do
			if not game_data.provinces[val].water and find_in_table(game_data.provinces[val].o, game_data.lands[land].enemies) then
				use_plane(land, v, val)
			end
			for key_, val_ in pairs(get_adjacency(val)) do
				if not game_data.provinces[val_].water and find_in_table(game_data.provinces[val_].o, game_data.lands[land].enemies) then
					use_plane(land, v, val_)
				end
			end
		end
	end
end

function M.chemical(land)
	local r = game_data.lands[land].resources.chemical_weapon
	local t = get_near_enemy_army_provinces(land)
	for k, v in pairs(t) do
		if r > 0 and not game_data.provinces[v].water then
			core.chemical_weapon(land, k, v)
			r = r - 1
		end
	end

end

function M.tank(land)
	local r = game_data.lands[land].resources.tank
	local t = get_near_enemy_army_provinces(land)
	for k, v in pairs(t) do
		if r > 0 and not game_data.provinces[v].water then
			core.tank(land, k, v)
			r = r - 1
		end
	end
end

local function get_province_points(province)
	local p = 0
	p = p + count_elements_in_table(game_data.provinces[province].b) * 10
	p = p + game_data.provinces[province].p / 1000
	for key, val in pairs(game_data.provinces[province].a) do
		p = p + val/100
	end
	return p
end

function M.nuclear(land)
	local best_provinces = {}
	for k, v in pairs(game_data.provinces) do
		if not v.water and v.o ~= "Undeveloped_land" and find_in_table(v.o, game_data.lands[land].enemies) then
			table.insert(best_provinces, k)
		end
	end

	best_provinces = lume.sort(best_provinces, function(a,b)
		return get_province_points(a) > get_province_points(b)
	end)

	local province = best_provinces[1]

	if province and game_data.lands[land].resources.uranium >= game_values.nuclear_weapon_cost_uranium and
	not lume.match(game_data.used_explosions, function(x) return x[1] == land and x[2] == province end) then
		core.nuclear_weapon(land, province)
	end
end

function M.get_wanted_provinces(land1, land2)
	local t = {}
	for k, v in pairs(game_data.provinces) do
		if not v.water and v.o == land2 and is_neighbour_province(k,land1) then
			table.insert(t, k)
		end
	end
	return t
end

function M.difficult_situation(land)
	local enemy_points = 0
	local ally_points = get_land_points(land)
	for k, v in pairs(game_data.lands) do
		if k ~= "Undeveloped_land" and not v.defeated then
			if relations.check_alliance(land, k) then
				ally_points = ally_points + get_land_points(k)
			elseif relations.check_war(land, k) then
				enemy_points = enemy_points + get_land_points(k)
			end
		end
	end
	return enemy_points > ally_points * 1.5
end

function M.common_enemy(land1, land2)
	for k, v in pairs(game_data.lands[land1].enemies) do
		if v ~= "Undeveloped_land" and find_in_table(v, game_data.lands[land2].enemies) then
			return true
		end
	end
	return false
end

function M.help_ally(land)
	if lume.random() < 0.1 then
		for k, v in pairs(game_data.lands[land].allies) do
			local money = game_data.lands[land].money
			if money > 1000 and not M.no_enemies(v) and (game_data.lands[v].money < 0
			or game_data.lands[v].money * 5 < money) then
				core.trade(land, v, {
					{
						item = "player_header",
						value = "",
					},
					{
						item = "gold",
						value = math.floor(money/3),
					}
				}, {
					{
						item = "civilization_header",
						value = "",
					},
				})
			end
		end
	end
end

function M.accept_pact(land, from)
	local l_p = get_land_points(land)
	local v_p = get_land_points(from)
	if (not M.no_enemies(land) or v_p > l_p and lume.random(0, 3) < v_p/l_p)
	and from ~= game_data.lands[land].ai.strategy.target or
	game_data.lands[land].war_weariness < -45 then
		return true
	end
end

function M.accept_alliance(land, from)
	if M.common_enemy(land, from) or M.difficult_situation(land)
	or get_land_points(from) > get_land_points(land) * 3 then
		return true
	end
end

local function get_province_cost(province, land, player_province)
	local cost = 10000
	cost = cost + game_data.provinces[province].p
	for k, v in pairs(game_data.provinces[province].b) do
		cost = cost + get_building_cost(land, k, v) * game_values.destroy_building_refund
	end

	local t = {
		gold = 10,
		uranium = 100000
	}
	for k, v in pairs(game_data.provinces[province].r) do
		if available_resource(land, v) then
			cost = cost + t[k] * v.count
		end
	end

	if not player_province and (get_num_of_provinces(land) <= 3 or
		game_data.lands[land].ideology == "theocracy" and game_data.lands[land].capital and
		game_data.lands[land].capital == province) then
		cost = cost + 10000000
	end

	return cost
end

function M.parse_trade(offer)
	local from = offer[3]
	local land = offer[4]

	local land_cost = 0
	local player_cost = 0

	for i = 2, #offer[5].player_trade_list do
		local v = offer[5].player_trade_list[i]
		if v.item == "peace" then
			land_cost = land_cost + game_data.lands[land].army * 1.5 - game_data.lands[from].army
		elseif v.item == "pact" then
			if not M.accept_pact(land, from) then
				land_cost = land_cost + 1000000
			end
		elseif v.item == "alliance" then
			if not M.accept_alliance(land, from) then
				land_cost = land_cost + 1000000
			end
		elseif v.item == "declare_war" then
			if relations.is_vassal(v.value) then
				v.value = relations.is_vassal(v.value)
			end
			if find_in_table(v.value, game_data.lands[land].enemies) then
				player_cost = player_cost + get_land_points(from) * 25
			end
		elseif v.item == "gold" and game_data.lands[from].money > 0   then
			player_cost = player_cost + v.value
		elseif v.item == "per_turn" then
			player_cost = player_cost + v.value * game_values.trade_gold_per_turn_duration * 1.1
		elseif v.item == "resource" then
			local resource = string.gsub(v.value, "%d", "")
			resource = string.gsub(resource, ":", "")
			local count = v.value:gsub("%D+", "")
			count = tonumber(count)

			if resource == "gold" then
				player_cost = player_cost + count * 30
			elseif resource == "uranium" then
				player_cost = player_cost + count * 50000
			elseif resource == "weapons" then
				player_cost = player_cost + count * 4
			elseif resource == "chemical_weapon" then
				player_cost = player_cost + count * 1000
			elseif resource == "tank" then
				player_cost = player_cost + count * 25000
			end
		elseif v.item == "province" and game_data.provinces[v.value].o == from then
			player_cost = player_cost + get_province_cost(v.value, from, true)
		end
	end

	for i = 2, #offer[5].civilization_trade_list do
		local v = offer[5].civilization_trade_list[i]
		if v.item == "declare_war" then
			if relations.is_vassal(v.value) then
				v.value = relations.is_vassal(v.value)
			end
			if get_land_points(land) * 1.2 > get_land_points(v.value) then
				land_cost = land_cost + get_land_points(v.value) * 75
			else
				land_cost = land_cost + 1000000
			end
		elseif v.item == "gold" and game_data.lands[land].money > 0  then
			land_cost = land_cost + v.value
		elseif v.item == "per_turn" then
			land_cost = land_cost + v.value * game_values.trade_gold_per_turn_duration * 1.1
		elseif v.item == "resource" then
			local resource = string.gsub(v.value, "%d", "")
			resource = string.gsub(resource, ":", "")
			local count = v.value:gsub("%D+", "")
			count = tonumber(count)

			if resource == "gold" then
				land_cost = land_cost + count * 30
			elseif resource == "uranium" then
				land_cost = land_cost + count * 50000
			elseif resource == "weapons" then
				land_cost = land_cost + count * 4
			elseif resource == "chemical_weapon" then
				land_cost = land_cost + count * 1000
			elseif resource == "tank" then
				land_cost = land_cost + count * 25000
			end
		elseif v.item == "province" and game_data.provinces[v.value].o == land  then
			land_cost = land_cost + get_province_cost(v.value, land)
		end
	end

	if relations.check_vassal(from, land) then
		land_cost = 0
		player_cost = 1
	end

	return player_cost >= land_cost, player_cost, land_cost
end

return M