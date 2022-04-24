local M = {}

local event_system = require "core.event_system"

local function annihilate_enemy_armies(province)
	for k, v in pairs(game_data.provinces[province].a) do
		for key, val in pairs(game_data.provinces[province].a) do
			if M.check_war(k, key) then
				local first_army = v - val
				if first_army < 0 then
					val = - first_army
					game_data.provinces[province].a[k] = nil
				elseif first_army > 0 then
					v = first_army
					game_data.provinces[province].a[key] = nil
				else
					game_data.provinces[province].a[k] = nil
					game_data.provinces[province].a[key] = nil
				end
			end
		end
	end
end

local function resolve_disputes(land1, land2)
	for k, v in pairs(game_data.provinces) do
		if v.a[land1] and v.a[land2] then
			annihilate_enemy_armies(k)
		end
	end
end

local function find_pact_data(land1, land2)
	for k, v in pairs(game_data.pacts_data) do
		if v[1] == land1 and v[2] == land2 or v[1] == land2 and v[2] == land1 then
			return k, v[3]
		end
	end
end

local function update_vassals_state(owner)
	for k, v in pairs(vassal_list(owner)) do
		for key, val in pairs(game_data.lands[v].allies) do
			if not find_in_table(val, game_data.lands[owner].allies) then
				remove_from_table(v, game_data.lands[val].allies)
			end
		end
		for key, val in pairs(game_data.lands[v].pacts) do
			if not find_in_table(val, game_data.lands[owner].pacts) then
				local pact_id = find_pact_data(val, v)
				table.remove(game_data.pacts_data, pact_id)
				remove_from_table(v, game_data.lands[val].pacts)
			end
		end
		for key, val in pairs(game_data.lands[v].enemies) do
			if not find_in_table(val, game_data.lands[owner].enemies) then
				remove_from_table(v, game_data.lands[val].enemies)
			end
		end
		game_data.lands[v].allies = deepcopy(game_data.lands[owner].allies)
		game_data.lands[v].pacts = deepcopy(game_data.lands[owner].pacts)
		game_data.lands[v].enemies = deepcopy(game_data.lands[owner].enemies)
		for key, val in pairs(game_data.lands[owner].allies) do
			if not find_in_table(v, game_data.lands[val].allies) then
				table.insert(game_data.lands[val].allies, v)
			end
		end

		-- print(debug.traceback())

		for key, val in pairs(game_data.lands[owner].pacts) do
			-- pprint("Player pacts: ", land_lang(owner), game_data.lands[owner].pacts)
			-- pprint("Land pacts: ", land_lang(val), game_data.lands[val].pacts)
			if not find_in_table(v, game_data.lands[val].pacts) then
				local pact_id, duration = find_pact_data(val, owner)
				print("Pact data: ", pact_id, duration, val, owner)
				local vassal_pact_id, vassal_duration = find_pact_data(val, v)
				if vassal_pact_id then
					table.remove(game_data.pacts_data, vassal_pact_id)
				end
				-- pprint("Register pact vassal: ", {land_lang(v), land_lang(val), duration})
				table.insert(game_data.pacts_data, {v, val, duration})

				table.insert(game_data.lands[val].pacts, v)
			end
		end
		for key, val in pairs(game_data.lands[owner].enemies) do
			if not find_in_table(v, game_data.lands[val].enemies) then
				table.insert(game_data.lands[val].enemies, v)
			end
		end
	end
end

function M.update_vassals_state(owner)
	update_vassals_state(owner)
end

function M.check_alliance(land1, land2)
	return find_in_table(land1, game_data.lands[land2].allies)
end

function M.is_vassal(land)
	return game_data.lands[land].vassal
end

function M.check_vassal(owner, vassal)
	if not vassal then
		print("Check vassal: ", owner, vassal)
	end
	return game_data.lands[vassal].vassal == owner
end

function M.check_pact(land1, land2)
	return lume.match(game_data.pacts_data, function(x) return x[1] == land1 and x[2] == land2 or x[1] == land2 and x[2] == land1 end)
end

function M.check_war(land1, land2)
	return find_in_table(land1, game_data.lands[land2].enemies)
end

function M.available_peace(land1, land2)
	return M.check_war(land1, land2)
end

function M.available_alliance(land1, land2)
	if not lume.match(game_data.lands[land1].bonuses, function(x)
	 return x[1] == "alliance" end) then
	 	return false
	elseif M.check_alliance(land1, land2) then
		return false
	elseif M.check_vassal(land1, land2) then
		return false
	elseif M.check_vassal(land2, land1) then
		return false
	elseif M.check_pact(land1, land2) then
		return false
	elseif M.check_war(land1, land2) then
		return false
	elseif land1 == land2 then
		return false
	else
		return true
	end
end

function M.available_vassal(owner, vassal)
	if M.check_war(owner, vassal) then
		return true
	else
		return false
	end
end

function M.available_pact(land1, land2)
	if not lume.match(game_data.lands[land1].bonuses, function(x)
	 return x[1] == "pact" end) then
	 	return false
	 elseif M.check_alliance(land1, land2) then
		return false
	elseif M.check_vassal(land1, land2) then
		return false
	elseif M.check_vassal(land2, land1) then
		return false
	elseif M.check_pact(land1, land2) then
		return false
	elseif M.check_war(land1, land2) then
		return false
	else
		return true
	end
end

function M.available_war(land1, land2)
	if M.check_alliance(land1, land2) then
		return false
	elseif M.check_vassal(land1, land2) then
		return false
	elseif M.check_vassal(land2, land1) then
		return false
	elseif M.check_pact(land1, land2) then
		return false
	elseif M.check_war(land1, land2) then
		return false
	elseif land1 == land2 then
		return false
	else
		return true
	end
end

function M.available_trade(land1, land2)
	return not M.check_war(land1, land2)
end

function M.register_peace(land1, land2, no_dispatch)
	remove_from_table(land1, game_data.lands[land2].enemies)
	remove_from_table(land2, game_data.lands[land1].enemies)

	if not no_dispatch then
		M.register_pact(land1, land2, no_dispatch)
	end

	update_vassals_state(land1)
	update_vassals_state(land2)

	if not no_dispatch then
		event_system.dispatch("registered_peace", land1, land2)
	end
end

function M.register_alliance(land1, land2, no_dispatch)
	table.insert(game_data.lands[land2].allies, land1)
	table.insert(game_data.lands[land1].allies, land2)
	if not no_dispatch then
		event_system.dispatch("registered_alliance", land1, land2)
	end
	-- for k, v in pairs(game_data.lands[land1].enemies) do
		-- if M.available_war(land2, v) then
			-- M.register_war(land2, v, no_dispatch)
		-- end
	-- end
	-- for k, v in pairs(game_data.lands[land2].enemies) do
		-- if M.available_war(land1, v) then
			-- M.register_war(land1, v, no_dispatch)
		-- end
	-- end

	update_vassals_state(land1)
	update_vassals_state(land2)
end

function M.clear_territory(land1, land2)
	-- clear the territory of another country
	for k, v in pairs(game_data.provinces) do
		if v.o == land1 then
			v.a[land2] = nil
		end
		if v.o == land2 then
			v.a[land1] = nil
		end
	end
end


function M.break_alliance(land1, land2, no_dispatch)
	remove_from_table(land1, game_data.lands[land2].allies)
	remove_from_table(land2, game_data.lands[land1].allies)
	if not no_dispatch then
		event_system.dispatch("broken_alliance", land1, land2)
	end

	update_vassals_state(land1)
	update_vassals_state(land2)

	if not no_dispatch then
		M.clear_territory(land1, land2)
	end
end

function M.register_vassal(owner, vassal, no_dispatch)
    -- clear vassals of vassal
    for k, v in pairs(vassal_list(vassal)) do
        M.independence(v)
    end
	game_data.lands[vassal].vassal = owner
	if not no_dispatch then
		M.register_peace(owner, vassal, true)
		event_system.dispatch("registered_vassal", owner, vassal)
	end

	update_vassals_state(owner)
end

function M.independence(land)
	event_system.dispatch("independence", game_data.lands[land].vassal, land)
	M.clear_territory(land, game_data.lands[land].vassal)
	game_data.lands[land].vassal = nil
end

function M.register_pact(land1, land2, no_dispatch)
	table.insert(game_data.pacts_data, { land1, land2, game_values.pact_duration })
	table.insert(game_data.lands[land2].pacts, land1)
	table.insert(game_data.lands[land1].pacts, land2)

	if not no_dispatch then
		event_system.dispatch("registered_pact", land1, land2)
	end

	update_vassals_state(land1)
	update_vassals_state(land2)
end

function M.register_war(land1, land2, no_dispatch)
	table.insert(game_data.lands[land2].enemies, land1)
	table.insert(game_data.lands[land1].enemies, land2)
	game_data.lands[land1].declared_war = game_data.step
	if not no_dispatch then
		event_system.dispatch("registered_war", land1, land2)
		resolve_disputes(land1, land2)
	end
	-- for k, v in pairs(game_data.lands) do
	-- 	if k ~= "Undeveloped_land" and not v.defeated and k ~= land1 and k ~= land2 then
	-- 		if M.check_war(k, land1) then
	-- 			event_system.dispatch("common_enemy", land2, k)
	-- 		elseif M.check_war(k, land2) then
	-- 			event_system.dispatch("common_enemy", land1, k)
	-- 		end
	-- 	end
	-- end
	-- if not ensuring_integrity then
		-- for k, v in pairs(game_data.lands[land2].allies) do
			-- if M.available_war(land1, v) then
				-- M.register_war(land1, v, no_dispatch)--, true)
			-- end
		-- end
		-- for k, v in pairs(game_data.lands[land1].allies) do
			-- if M.available_war(land2, v) then
				-- M.register_war(land2, v, no_dispatch)--, true)
			-- end
		-- end
	-- end

	update_vassals_state(land1)
	update_vassals_state(land2)
end

function M.is_friendly_province(land, province)
	local to_province_owner = game_data.provinces[province].o
	if to_province_owner then
		if to_province_owner == land or M.check_alliance(land, to_province_owner) or
		M.check_vassal(land, to_province_owner) or M.check_vassal(land, to_province_owner) then
			return true
		else
			return false
		end
	else
		for k, v in pairs(game_data.provinces[province].a) do
			if M.check_war(land, k) and v > 0 then
				return false
			end
		end
		return true
	end
end

function M.possible_move(land, from_province, to_province)
	local to_province_owner = game_data.provinces[to_province].o
	if not to_province_owner then
		if game_data.provinces[from_province].water or game_data.provinces[from_province].b.port then
			return true
		else
			return false
		end
	elseif to_province_owner == land
	or M.check_war(land, to_province_owner) or M.check_alliance(land, to_province_owner) or
	M.check_vassal(land, to_province_owner) or M.check_vassal(to_province_owner, land) then
		return true
	end
	return false
end 

function M.possible_shell(land, from_province, to_province)
	local to_province_owner = game_data.provinces[to_province].o
	if not to_province_owner then
		for k, v in pairs(game_data.provinces[to_province].a) do
			if not M.check_war(land, k) then
				return false, "here arre neutral army"
			end
		end
		return true
	else
		return M.check_war(land, to_province_owner)
	end
end

function M.possible_air_attack(land, province)
	local to_province_owner = game_data.provinces[province].o
	if not to_province_owner then
		-- for k, v in pairs(game_data.provinces[province].a) do
			-- if not M.check_war(land, k) then
				-- return false, "here are neutral army"
			-- end
		-- end
		-- return true
		return false
	elseif M.check_war(land, to_province_owner) then
		return true
	end
	return false
end

return M