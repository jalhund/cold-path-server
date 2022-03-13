local M = {}

local buildings_functions = {
	tank_factory = function(province_id, province_data, building_data)
		if game_data.lands[province_data.o].ideology == "fascism" then
			game_data.lands[province_data.o].resources.tank = game_data.lands[province_data.o].resources.tank + 1
		end
	end,
	nuclear_reactor = function(province_id, province_data, building_data)
		local heavy_water = game_data.lands[province_data.o].resources.heavy_water
		if heavy_water > game_values.max_heavy_water_in_reactor then
			heavy_water = game_values.max_heavy_water_in_reactor
		end
		if heavy_water >= game_values.heavy_water_for_reactor_cooling then
			game_data.lands[province_data.o].resources.heavy_water = game_data.lands[province_data.o].resources.heavy_water -
					game_values.heavy_water_for_reactor_cooling
		else
			game_data.lands[province_data.o].resources.heavy_water = 0
		end
		if not game_data.nuclear_reactors_cooling[tostring(province_id)] then
			game_data.nuclear_reactors_cooling[tostring(province_id)] = 0
		end
		game_data.nuclear_reactors_cooling[tostring(province_id)] = game_data.nuclear_reactors_cooling[tostring(province_id)]  + heavy_water

		if game_data.nuclear_reactors_cooling[tostring(province_id)] > game_values.max_heavy_water_in_reactor then
			game_data.nuclear_reactors_cooling[tostring(province_id)] = game_values.max_heavy_water_in_reactor
		end

		game_data.nuclear_reactors_cooling[tostring(province_id)] = game_data.nuclear_reactors_cooling[tostring(province_id)] - game_values.heavy_water_for_reactor_cooling
		if game_data.nuclear_reactors_cooling[tostring(province_id)] <= 0 then
			table.insert(game_data.current_explosions, {"nuclear_reactor", province_id, "nuclear_reactor"})
			province_data.b = {}
			province_data.p = province_data.p * 0.25
			for k, v in pairs(province_data.a) do
				v = math.floor(v * 0.25)
			end
		end
	end,
	--fusion_reactor = function(province_id, province_data, building_data)
	--	game_data.lands[province_data.o].economy.expense.buildings = game_data.lands[province_data.o].economy.expense.buildings +
	--		game_values.money_per_turn_for_fusion_reactor
	--	if lume.random() <= game_values.money_from_fusion_reactor_chance then
	--		game_data.lands[province_data.o].economy.income.buildings = game_data.lands[province_data.o].economy.income.buildings +
	--		game_values.money_from_fusion_reactor
	--	end
	--end,
}

local function calc_building(province_id, province_data, building_data, n, building_type)
	-- pprint("calc specific building: ", building_data)
	local input_done = true
	local input_factor = 1
	if building_data.input then
		for k, v in pairs(building_data.input) do
			local action, resource = k:match("([%a_]+):([%a_]+)")
			-- print("action, resource:", k, action, resource)
			if not action then
				if k == "gold" then
					game_data.lands[province_data.o].economy.expense.buildings =
					game_data.lands[province_data.o].economy.expense.buildings + v
				end
			elseif action == "resource" then
				local res = game_data.lands[province_data.o].resources[resource]
				if res > v then
					res = v
				elseif res < v then
					input_done = false
					-- input_factor = res/v
				end
				if input_done then
					game_data.lands[province_data.o].resources[resource] = game_data.lands[province_data.o].resources[resource] - res
				end
			elseif action == "extract" then
				local res = province_data.r[resource] and province_data.r[resource].count or 0
				if res > v then
					res = v
				elseif res < v then
					input_factor = res/v
				end
				if res > 0 and available_resource(province_data.o, province_data.r[resource]) then
					-- print("Extract resource: ", resource, res)
					province_data.r[resource].count = province_data.r[resource].count - res
					-- game_data.lands[province_data.o].resources[resource] = game_data.lands[province_data.o].resources[resource] + res
				elseif res == 0 then
					province_data.r[resource] = nil
				end
			end
		end
	end
	if building_data.output and input_done then
		for k, v in pairs(building_data.output) do
			local action, resource = k:match("([%a_]+):([%a_]+)")
			if not action then
				local res = v * input_factor
				if k == "gold" and res > 0 then
					game_data.lands[province_data.o].economy.income.buildings =
					game_data.lands[province_data.o].economy.income.buildings + res
				elseif k == "science" then
					local science_per_turn = v * math.pow(game_values.science_building_factor, n - 1)
		
					game_data.lands[province_data.o].science_per_turn.buildings = game_data.lands[province_data.o].science_per_turn.buildings +
						science_per_turn
				end
			elseif action == "resource" then
				local res = v * input_factor
				-- print("Output resource: ", resource, res)
				if res > 0 then
					-- print("before game data resource", game_data.lands[province_data.o].resources[resource], province_data.o)
					game_data.lands[province_data.o].resources[resource] = game_data.lands[province_data.o].resources[resource] + res
					-- print("after game data resource", game_data.lands[province_data.o].resources[resource], province_data.o)
				end
			end
		end
	end
	if input_done and buildings_functions[building_type] then
		buildings_functions[building_type](province_id, province_data, building_data)
	end
end

local function calc_type_buildings(building_type)
	local building_n = {}
	-- print("Calc building: ", building_type)

	for k, v in pairs(game_data.provinces) do
		if not v.water and v.b[building_type] then
			building_n[v.o] = building_n[v.o] and building_n[v.o] + 1 or 1
			-- pprint("buildings data: ", get_building_data(building_type).lvl)
			calc_building(k, v, get_building_data(building_type).lvl[v.b[building_type]], building_n[v.o], building_type)
		end
	end
end

function M.calc_buildings()
	calc_type_buildings("mine")
	calc_type_buildings("mint")
	calc_type_buildings("bank")
	calc_type_buildings("university")
	calc_type_buildings("science_center")
	calc_type_buildings("weapon_factory")
	calc_type_buildings("air_defense")
	calc_type_buildings("chemical_factory")
	calc_type_buildings("tank_factory")
	calc_type_buildings("heavy_water_plant")
	calc_type_buildings("nuclear_reactor")
	calc_type_buildings("fusion_reactor")
end

return M