local M = {}

M.buildings_data = {
	science = {
		{
			id = "machine_a",
			lvl = {
				[1] = {
					cost = 100000,
					resource_cost = {
						gold = 5000,
						tank = 50
					},
				},
			}
		},
		{
			id = "machine_b",
			lvl = {
				[1] = {
					cost = 100000,
					resource_cost = {
						uranium = 50,
						heavy_water = 600
					},
				},
			}
		},
		{
			id = "machine_c",
			lvl = {
				[1] = {
					cost = 100000,
					resource_cost = {
						weapons = 30000,
						chemical_weapon = 50
					},
				},
			}
		},
		{
			id = "megarefrigerator",
			lvl = {
				[1] = {
					cost = 20000,
				},
			}
		},
	},
}

local function check_machine(land)
	for k, v in pairs(game_data.provinces) do
		if v.o == land then
			if game_data.cause_of_warming == "core" then
				if v.b.machine_a then
					return true
				end
			elseif game_data.cause_of_warming == "solar" then
				if v.b.machine_a or v.b.machine_b then
					return true
				end
			elseif game_data.cause_of_warming == "greenhouse" then
				if v.b.machine_a or v.b.machine_b or v.b.machine_c then
					return true
				end
			end
		end
	end
end

local function check_win(land)
	local almost_lost = false

	if get_num_of_provinces(land) == 1 then
		local province = get_province_for_land(land)
		if game_data.provinces[province].p < 500 then
			almost_lost = true
		end
	end


	return almost_lost and check_machine(land)
end

function M.calc(game_end_callback)
	if game_data.step % 9 == 3 then
		local c = 0
		if game_data.temperature_rise < game_data.step * 0.5 then
			c = math.floor(lume.random(5, 9))
		else
			c = math.floor(lume.random(1, 5))
		end
		for k, v in pairs(game_data.provinces) do
			if not v.water then
				v.tmp = v.tmp + c
			end
		end
		game_data.temperature_rise = game_data.temperature_rise + c
	end
	local loss = {}
	for k, v in pairs(game_data.provinces) do
		if not v.water and v.p > 0 then
			local l_t = 42
			if v.b.machine_a or v.b.machine_b or v.b.machine_c then
				l_t = 52
			end
			local damage = (v.tmp - l_t > 0 and math.pow(v.tmp - l_t, 3) or 0) / 1000000
			loss[v.o] = math.floor((loss[v.o] or 0) + v.p * damage)
			v.p = v.p - v.p * damage
			for key, val in pairs(v.a) do
				val = math.floor(val - val * damage)
			end
			if v.p < 100 then
				v.p = 0
				v.o = "Undeveloped_land"
				v.a = {}
				v.wasteland = true
			end
		end
	end

	for k, v in pairs(loss) do
		if v ~= 0 then
			table.insert(game_data.old_offers, {
				#game_data.old_offers + 1, "loss_due_temperature", "system", k, v
			})
		end
	end

	local steps = {
		[1] = "intro",
		[2] = "warn_1",
		[3] = "warn2",
		[4] = "warn3",
		[5] = "warn4",
		[6] = "warn5",
		[7] = "warn6",
		[10] = "warn7"
	}

	if game_data.cause_of_warming == "core" then
		steps[8] = "no_solar"
		steps[9] = "no_greenhouse"
	elseif game_data.cause_of_warming == "solar" then
		steps[8] = "no_greenhouse"
		steps[9] = "no_core"
	elseif game_data.cause_of_warming == "greenhouse" then
		steps[8] = "no_core"
		steps[9] = "no_solar"
	end

	if steps[game_data.step] then
		for k, v in pairs(game_data.lands) do
			if k ~= "Undeveloped_land" and not v.defeated then
				table.insert(game_data.old_offers, {
					#game_data.old_offers + 1, "weather_news", "system", k, steps[game_data.step] 
				})
			end
		end
	end

	for k, v in pairs(game_data.lands) do
		if k ~= "Undeveloped_land"  and not v.defeated and check_win(k) then
			-- clear_data_about(k)
			-- v.defeated = true
			game_end_callback(k, true, true)
		end
	end
end

function M.build(land, province, building_id)
	if building_id == "megarefrigerator" then
		game_data.provinces[province].tmp = game_data.provinces[province].tmp - game_values.megarefrigerator_effect
	end
end

function M.destroy(land, province, building_id)
	if building_id == "megarefrigerator" then
		game_data.provinces[province].tmp = game_data.provinces[province].tmp + game_values.megarefrigerator_effect
	end
end

return M