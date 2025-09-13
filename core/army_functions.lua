local M = {}

local event_system = require "core.event_system"
local relations = require "core.relations"
local ideology = require "core.ideology"

function M.get_army(province, land)
	local n = 0
	for k,v in pairs(game_data.provinces[province].a) do
		if land and k == land then
			n = n + v
		elseif not land then
			n = n + v
		end
	end
	return n
end

function M.move_army(from, to, _amount, land)
	local amount = _amount
	if game_data.provinces[to].water then
		amount = amount + M.get_army(to, land)
		-- if not next(game_data.provinces[to].a) then -- If no army in water province
		-- 	print("set army to 0: ", to, land)
		-- 	game_data.provinces[to].a[land] = 0
		-- end
		local start_amount = amount
		for k, v in pairs(game_data.provinces[to].a) do
			if k == land then
				amount = amount + v
			end
			if find_in_table(k, game_data.lands[land].enemies) then
				local damage = amount
				local damage_bonus = 1/M.calc_provincial_defense(to)
				damage_bonus = damage_bonus*M.calc_army_attack_bonus(land, from, k)
				damage_bonus = damage_bonus/M.calc_army_defense_bonus(k)
				game_data.lands[k].last_attacked = land
				if damage * damage_bonus > v then
					damage = math.floor(v/damage_bonus)
				end
				amount = math.floor(amount - damage)
				M.set_army(to, math.floor(v - damage * damage_bonus), k)
				if amount < 0 then
					print("Set amount = 0", from, to, _amount, land)
					amount = 0
				end
			end
		end
		if amount > 0 then
			if amount > start_amount then
				amount = start_amount
			end
			M.set_army(to, amount, land)
		end
		table.insert(game_data.current_moves, {from,to, _amount, land})
	else
		if land == game_data.provinces[to].o or find_in_table(game_data.provinces[to].o,
		game_data.lands[land].allies) or relations.check_vassal(game_data.provinces[to].o, land)
		or relations.check_vassal(land, game_data.provinces[to].o) then
			-- print("Set army because is our province", from, to, _amount, land)
			M.set_army(to, M.get_army(to,land) + amount, land)
			table.insert(game_data.current_moves, {from,to, _amount, land})
		elseif not find_in_table(game_data.provinces[to].o, game_data.lands[land].enemies) then
			print("We are late, the owner of this province is not our enemy")
			if game_data.provinces[from].o == land then
				M.set_army(from, M.get_army(from,land) + amount, land)
			end
		else
			--print("Before move: ")
			--check_bad_army()
			local start_amount = amount
			for i = #game_data.queue, 1, -1 do
				local offer = game_data.queue[i]
				if offer[2] == "move" and offer[3] == to and offer[4] == from then
					local damage_bonus = 1
					damage_bonus = damage_bonus*M.calc_army_attack_bonus(land, from, offer[1])
					damage_bonus = damage_bonus/M.calc_army_defense_bonus(offer[1])
					local damage = amount * damage_bonus
					amount = math.floor(damage - offer[5])
					if amount < 0 then
						amount = 0
					else
						table.remove(game_data.queue, i)
					end
				end
			end
			for k, v in pairs(game_data.provinces[to].a) do
				local damage = amount
				local damage_bonus = 1/M.calc_provincial_defense(to)
				damage_bonus = damage_bonus*M.calc_army_attack_bonus(land, from, k)
				damage_bonus = damage_bonus/M.calc_army_defense_bonus(k)
				game_data.lands[k].last_attacked = land
				if game_data.lands[game_data.provinces[to].o].ideology == "communism" then
					amount = ideology.scatter_damage(from, to, amount, land, damage_bonus)
				else
					if damage * damage_bonus > v then
						damage = math.floor(v/damage_bonus)
					end
					-- 21	53452	11	1.7676767676768
					--print("almost middle: ", v, amount, damage, damage_bonus)
					amount = math.floor(amount - damage)
					M.set_army(to, math.floor(v - damage * damage_bonus), k)
					--check_bad_army()
				end

				if game_data.provinces[to].b.hospital then
					-- To avoid incorrect math.floor and discrepancy for 1. Example:
					-- v = 17, damage * damage_bonus = 12.5, we can wrong add math.floor(12.5) = 12, but army lost
					-- 17 - math.floor(17 - 12.5) = 13
					-- So below v - math.floor(v - damage * damage_bonus) instead just damage * damage_bonus
					game_data.provinces[to].p = game_data.provinces[to].p + v - math.floor(v - damage * damage_bonus)
				end

				if amount < 0 then
					print("Set amount = 0", from, to, _amount, land)
					amount = 0
				end
			end
			--print("middle move: ", amount, start_amount, from, to)
			--check_bad_army()
			if amount > 0 and not game_data.provinces[to].wasteland then
				-- if game_data.lands[land].rebels and lume.random() < 0.95 then
					-- M.set_army(from, amount, land)
				-- else
					-- print("Set army because amount > 0", from, to, _amount, land)
					if game_data.provinces[to].o == "Undeveloped_land" and game_data.provinces[to].p < 1000 then
						game_data.provinces[to].p = game_values.min_population
					end
					game_data.provinces[to].o = land
					-- game_data.provinces[to].s = math.floor(lume.random(0, 73))
					game_data.provinces[to].a = {}
					if amount > start_amount then
						amount = start_amount
					end
					M.set_army(to, amount, land)
				-- end
			end
			-- print("after move: ")
			-- check_bad_army()
			table.insert(game_data.current_moves, {from,to, _amount, land})
		end
	end
end

function M.set_army(province, value, land, delete_other, all)
	if land then
		if delete_other then
			for k, v in pairs(game_data.provinces[province].a) do
				v = 0
			end
		end
		game_data.provinces[province].a[land] = value
	else
		for k, v in pairs(game_data.provinces[province].a) do
			v = value
		end
	end
end

function M.validate_army()
	for k, v in pairs(game_data.provinces) do
		if not v.water and not v.a[v.o] then
			v.a[v.o] = 0
		end
		for key, val in pairs(v.a) do
			if val == 0 and key ~= v.o then
				game_data.provinces[k].a[key] = nil
			end
		end
	end
end

function M.shell(land, from, to, count)
	local amount = count
	for k, v in pairs(game_data.provinces[to].a) do
		local damage = amount
		local damage_bonus = 1/M.calc_provincial_defense(to)
		damage_bonus = damage_bonus/M.calc_army_defense_bonus(k)
		if lume.match(game_data.lands[land].bonuses, function(x) return x[1] == "firing_line" end) then
			damage_bonus = damage_bonus * game_values.firing_line_attack_bonus
		end
		if lume.match(game_data.lands[k].bonuses, function(x) return x[1] == "shell_immunity" end) then
			damage_bonus = damage_bonus / game_values.shell_immunity_value
		end
		if math.floor(damage * damage_bonus) > v then
			damage = math.floor(v/damage_bonus)
		end
		amount = amount - damage
		M.set_army(to, v - math.floor(damage * damage_bonus), k)
		if not game_data.provinces[to].water and game_data.provinces[to].b.hospital then
			game_data.provinces[to].p = game_data.provinces[to].p + math.floor(damage * damage_bonus)
		end
		if amount < 0 then
			print("Set amount = 0", from, to, amount, land)
			amount = 0
		end
	end
	table.insert(game_data.current_shell, {from,to, amount, land})
end

function M.tank(land, from, to)
	print("Army function Tank: ", land, from, to)
	local amount = game_values.tank_damage
	for k, v in pairs(game_data.provinces[to].a) do
		local damage = amount
		local damage_bonus = 1/M.calc_provincial_defense(to)
		damage_bonus = damage_bonus*M.calc_army_attack_bonus(land, from, k)
		damage_bonus = damage_bonus/M.calc_army_defense_bonus(k)
		if math.floor(damage * damage_bonus) > v then
			damage = math.floor(v/damage_bonus)
		end
		amount = amount - damage
		M.set_army(to, v - math.floor(damage * damage_bonus), k)
		if amount < 0 then
			print("Set amount = 0", from, to, amount, land)
			amount = 0
		end
	end
	if game_data.provinces[to].b.fortress then
		game_data.provinces[to].b.fortress = game_data.provinces[to].b.fortress - 2
		if game_data.provinces[to].b.fortress <= 0 then
			game_data.provinces[to].b.fortress = nil
		end
	end
	table.insert(game_data.current_tank, {from,to,  land})
end

function M.air_attack(land, from, to)
	local lvl = game_data.provinces[from].b.aerodrome
	if not lvl then
		lvl = 1
	end
	local amount = get_building_data("aerodrome").lvl[lvl].air_attack_damage
	local protected, province = air_protected(land, to, lvl)
	if protected then
		table.insert(game_data.current_planes, {from,to, "fail", province, land, lvl})
	else
		for k, v in pairs(game_data.provinces[to].a) do
			local damage = amount
			local damage_bonus = 1/M.calc_provincial_defense(to)
			damage_bonus = damage_bonus
			damage_bonus = damage_bonus/M.calc_army_defense_bonus(k)
			if math.floor(damage * damage_bonus) > v then
				damage = math.floor(v/damage_bonus)
			end
			amount = amount - damage
			M.set_army(to, v - math.floor(damage * damage_bonus), k)
			if amount < 0 then
				print("Set amount = 0", from, to, _amount, land)
				amount = 0
			end
		end
		local c = get_building_data("aerodrome").lvl[lvl].break_building_chance
		for k, v in pairs(game_data.provinces[to].b) do
			if lume.random() < c then
				if k == "nuclear_reactor" then
					table.insert(game_data.current_explosions, {"nuclear_reactor", to, "nuclear_reactor"})
					game_data.provinces[to].b = {}
					game_data.provinces[to].p = game_data.provinces[to].p * 0.25
					for key, val in pairs(game_data.provinces[to].a) do
						val = math.floor(val * 0.25)
					end
				else
					game_data.provinces[to].b[k] = game_data.provinces[to].b[k] - 1
					if game_data.provinces[to].b[k] == 0 then
						game_data.provinces[to].b[k] = nil
					end
				end
			end
		end

		table.insert(game_data.current_planes, {from,to, "success", to, land, lvl})
	end
end

function M.chemical(land, from, to)
	for k, v in pairs(game_data.provinces[to].a) do
		M.set_army(to, v - math.floor(v * game_values.chemical_weapon_damage), k)
	end
	game_data.provinces[to].p = game_data.provinces[to].p - math.floor(game_data.provinces[to].p * game_values.chemical_weapon_damage)
	table.insert(game_data.current_chemical, {from,to,  land})
end

function M.nuclear(land, to, from)
	local protected, province = missile_protected(land, to)

	if protected then
		table.insert(game_data.current_explosions, {"nuclear_weapon_fail", to, from})
		return
	end
	
	game_data.provinces[to].a = {}
	game_data.lands[game_data.provinces[to].o].last_attacked = land
	game_data.provinces[to].o = "Undeveloped_land"
	game_data.provinces[to].p = 0
	game_data.provinces[to].b = {}


	for _, v in pairs(get_adjacency(to)) do
		local province_data = game_data.provinces[v]
		for key, val in pairs(province_data.a) do
			M.set_army(v, val - math.floor(val * game_values.nuclear_weapon_damage_radius), key)
		end
		if not province_data.water then
			province_data.p = province_data.p
			 - math.floor(province_data.p * game_values.nuclear_weapon_damage_radius)
			for i = #province_data.b, 1 do
				if lume.random() < game_values.nuclear_weapon_destroy_buildings_chance then
					table.remove(province_data.b, i)
				end
			end
		end
	end

	-- Используем переданную провинцию-источник, если она есть
	if from then
		-- print("ОТЛАДКА ЯДЕРНОЙ АТАКИ: Используем переданную провинцию-источник: " .. from)
	else
		-- Для обратной совместимости пытаемся получить провинцию-источник из used_explosions
		-- print("ОТЛАДКА ЯДЕРНОЙ АТАКИ: Поиск источника запуска в used_explosions, количество записей: " .. #game_data.used_explosions)
		
		for _, explosion in pairs(game_data.used_explosions) do
			-- print("ОТЛАДКА ЯДЕРНОЙ АТАКИ: Проверка записи:", explosion[1], explosion[2])
			if explosion[1] == land and explosion[2] == to then
				from = explosion[3]
				-- print("ОТЛАДКА ЯДЕРНОЙ АТАКИ: Найден источник запуска: " .. tostring(from))
				break
			end
		end
	end
	
	if from then
		-- print("ОТЛАДКА ЯДЕРНОЙ АТАКИ: Добавляем в current_explosions с источником: " .. from)
	else
		-- print("ОТЛАДКА ЯДЕРНОЙ АТАКИ: Источник не найден, добавляем без него")
	end

	table.insert(game_data.current_explosions, {"nuclear_weapon", to, from})
end

function M.army_recruit_cost(land)
	local c = game_values.army_recruit_cost

	local b = 1
	for k, v in pairs(game_data.lands[land].bonuses) do
		if v[1] == "hiring_an_army_less" then
			b = b * v[2]
		end
	end

	b = b * ideology.recruit_cost_bonus(land)

	return c * b
end

function M.calc_army_defense_bonus(land)
	local b = 1
	for k, v in pairs(game_data.lands[land].bonuses) do
		if v[1] == "army_defense" then
			b = b*v[2]
		end
	end
	b = b * ideology.army_defense_bonus(land)
	return b
end

function M.calc_army_attack_bonus(land, province, to_land)
	local b = 1
	if game_data.lands[land].capital and game_data.provinces[game_data.lands[land].capital].o ~= land and ideology.is_attack_bonus_without_capital(land) then
		b = 1 - game_values.attack_bonus_without_capital_less
	end
	for k, v in pairs(game_data.lands[land].bonuses) do
		if v[1] == "army_attack" then
			b = b*v[2]
		end
	end
	if game_data.consequence_data[land] then
		b = b * game_values.consequence_effect
	end
	if province and not game_data.provinces[province].water and game_data.provinces[province].b.bridgehead then
		b = b * get_building_data("bridgehead").lvl[1].damage_bonus
	end

	if game_data.lands[land].vassal then
		for k, v in pairs(game_data.lands[game_data.lands[land].vassal].bonuses) do
			if v[1] == "vassals_attack_bonus" then
				b = b*v[2]
			end
		end
	end
	b = b * ideology.army_attack_bonus(land, to_land)

	return b
end

function M.calc_provincial_defense(province)
	local k = 1

	if game_data.provinces[province].water then
		return 1
	end

	for key, val in pairs(game_data.lands[game_data.provinces[province].o].bonuses) do
		if val[1] == "capital_defense" and is_capital(province) then
			k = k*val[2]
		end
	end

	if game_data.provinces[province].b.fortress then
		k = k * get_building_data("fortress").lvl[game_data.provinces[province].b.fortress].defense_bonus
		if lume.match(game_data.lands[game_data.provinces[province].o].bonuses, function(x) return x[1] == "fortress_gives_defense_bonus" end) then
			k = k * game_values.fortress_gives_defense_bonus
		end
	end

	-- print("Return:", province, k)
	return k
end

function M.calc_shell_damage(land)
	return game_values.shell_damage
end

return M