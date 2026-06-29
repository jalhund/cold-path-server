local M = {}

local army_functions = require "core.army_functions"
local core = require "core.core"

-- Optimized Weapon Usage: Smarter targeting and coordination of weapons systems

-- Calculate province value (for targeting nukes)
local function get_province_strategic_value(province, land)
	local value = 0
	
	-- Count buildings
	local building_count = count_elements_in_table(game_data.provinces[province].b)
	value = value + (building_count * 15)
	
	-- Population value
	value = value + (game_data.provinces[province].p / 500)
	
	-- Army concentration
	for key, val in pairs(game_data.provinces[province].a) do
		value = value + (val / 50)
	end
	
	-- Capital bonus
	local owner = game_data.provinces[province].o
	if owner ~= "Undeveloped_land" and game_data.lands[owner].capital == province then
		value = value + 100
	end
	
	-- Resource value
	if game_data.provinces[province].r.uranium and game_data.provinces[province].r.uranium.count > 0 then
		value = value + 50
	end
	if game_data.provinces[province].r.gold and game_data.provinces[province].r.gold.count > 0 then
		value = value + 30
	end
	
	return value
end

-- Check if province is worth nuking
local function is_high_value_target(province, land, min_value)
	local value = get_province_strategic_value(province, land)
	return value >= min_value
end

-- Get provinces near front lines
local function get_near_enemy_army_provinces(land)
	local t = {}
	for k, v in pairs(game_data.provinces) do
		if v.o == land then
			for key, val in pairs(get_adjacency(k)) do
				for key_, val_ in pairs(game_data.provinces[val].a) do
					if val_ and val_ > 0 and key_ ~= "Undeveloped_land" and find_in_table(key_, game_data.lands[land].enemies) then
						if not t[k] or army_functions.get_army(val) > army_functions.get_army(t[k]) then
							t[k] = val
						end
					end
				end
			end
		end
	end
	return t
end

-- Optimized shell usage: Target concentrations
function M.shell(land)
	local r = game_data.lands[land].resources.weapons / game_values.shell_cost
	if r <= 0 then return end
	
	local t = get_near_enemy_army_provinces(land)
	
	-- Sort targets by enemy army size
	local sorted_targets = {}
	for from, to in pairs(t) do
		table.insert(sorted_targets, {from = from, to = to, army = army_functions.get_army(to)})
	end
	
	table.sort(sorted_targets, function(a, b) return a.army > b.army end)
	
	-- Target largest concentrations first
	for i, target in ipairs(sorted_targets) do
		if r <= 0 then break end
		
		local count = army_functions.get_army(target.to)
		if count > r then
			count = r
		end
		if count > army_functions.get_army(target.from, land) then
			count = army_functions.get_army(target.from, land)
		end
		
		-- Only shell if significant enemy force (min 500 units)
		if count > 0 and army_functions.get_army(target.to) >= 500 then
			if not lume.match(game_data.used_shell, function(x) 
				return x[1] == land and x[2] == target.from and x[3] == target.to 
			end) then
				core.shell(land, target.from, target.to, count)
				r = r - count
			end
		end
	end
end

-- Use plane before we attack
local function use_plane(land, from, to)
	if not lume.match(game_data.used_planes, function(x) return x[1] == land and x[2] == from end)
	and army_functions.get_army(to) > 0 then
		core.air_attack(land, from, to)
	end
end

-- Optimized plane usage: Soften up targets before assault
function M.planes(land)
	local aero_provinces = {}
	for k, v in pairs(game_data.provinces) do
		if v.o == land and v.b.aerodrome then
			table.insert(aero_provinces, k)
		end
	end
	
	-- Find enemy provinces with most troops
	local targets = {}
	for k, v in pairs(aero_provinces) do
		for key, val in pairs(get_adjacency(v)) do
			if not game_data.provinces[val].water and find_in_table(game_data.provinces[val].o, game_data.lands[land].enemies) then
				local army = army_functions.get_army(val)
				if army >= 300 then  -- Only target significant forces
					table.insert(targets, {aerodrome = v, target = val, army = army})
				end
			end
			for key_, val_ in pairs(get_adjacency(val)) do
				if not game_data.provinces[val_].water and find_in_table(game_data.provinces[val_].o, game_data.lands[land].enemies) then
					local army = army_functions.get_army(val_)
					if army >= 300 then
						table.insert(targets, {aerodrome = v, target = val_, army = army})
					end
				end
			end
		end
	end
	
	-- Sort by army size (target biggest threats)
	table.sort(targets, function(a, b) return a.army > b.army end)
	
	-- Use planes on top targets
	for i, target in ipairs(targets) do
		use_plane(land, target.aerodrome, target.target)
	end
end

-- Optimized chemical weapon usage: Coordinate with potential attacks
function M.chemical(land)
	local r = game_data.lands[land].resources.chemical_weapon
	if r <= 0 then return end
	
	local t = get_near_enemy_army_provinces(land)
	
	-- Prioritize targets we're about to attack
	local priority_targets = {}
	for k, v in pairs(t) do
		if not game_data.provinces[v].water then
			local enemy_army = army_functions.get_army(v)
			local our_army = army_functions.get_army(k, land)
			
			-- Prioritize where we have nearby army that could benefit
			local priority = 0
			if our_army > enemy_army * 0.5 and our_army < enemy_army * 1.5 then
				-- Close fight - chemical could tip balance
				priority = enemy_army * 2
			elseif enemy_army > our_army then
				-- We're weaker - help needed
				priority = enemy_army * 1.5
			else
				priority = enemy_army
			end
			
			table.insert(priority_targets, {from = k, to = v, priority = priority})
		end
	end
	
	-- Sort by priority
	table.sort(priority_targets, function(a, b) return a.priority > b.priority end)
	
	-- Use chemical weapons on top targets
	for i, target in ipairs(priority_targets) do
		if r <= 0 then break end
		core.chemical_weapon(land, target.from, target.to)
		r = r - 1
	end
end

-- Optimized tank usage: Breakthrough attacks
function M.tank(land)
	local r = game_data.lands[land].resources.tank
	if r <= 0 then return end
	
	local t = get_near_enemy_army_provinces(land)
	
	-- Use tanks where we have army advantage for breakthrough
	local breakthrough_targets = {}
	for k, v in pairs(t) do
		if not game_data.provinces[v].water then
			local our_army = army_functions.get_army(k, land)
			local enemy_army = army_functions.get_army(v)
			
			-- Tanks most effective when we already have advantage
			if our_army > enemy_army * 0.8 then
				local score = our_army - enemy_army
				table.insert(breakthrough_targets, {from = k, to = v, score = score})
			end
		end
	end
	
	-- Sort by breakthrough potential
	table.sort(breakthrough_targets, function(a, b) return a.score > b.score end)
	
	for i, target in ipairs(breakthrough_targets) do
		if r <= 0 then break end
		core.tank(land, target.from, target.to)
		r = r - 1
	end
end

-- Optimized drone usage: autonomous strikes (Technocracy)
function M.drone(land)
	local r = game_data.lands[land].resources.drone or 0
	if r <= 0 then return end

	local t = get_near_enemy_army_provinces(land)

	local strike_targets = {}
	for k, v in pairs(t) do
		if not game_data.provinces[v].water then
			local our_army = army_functions.get_army(k, land)
			local enemy_army = army_functions.get_army(v)

			-- Strike where we already have an advantage, like tanks
			if our_army > enemy_army * 0.8 then
				local score = our_army - enemy_army
				table.insert(strike_targets, {from = k, to = v, score = score})
			end
		end
	end

	table.sort(strike_targets, function(a, b) return a.score > b.score end)

	for i, target in ipairs(strike_targets) do
		if r <= 0 then break end
		core.drone(land, target.from, target.to)
		r = r - 1
	end
end

-- Optimized nuclear weapon usage: High-value strategic targets only
function M.nuclear(land)
	if game_data.lands[land].resources.uranium < game_values.nuclear_weapon_cost_uranium then
		return
	end
	
	local best_provinces = {}
	for k, v in pairs(game_data.provinces) do
		if not v.water and v.o ~= "Undeveloped_land" and find_in_table(v.o, game_data.lands[land].enemies) then
			local value = get_province_strategic_value(k, land)
			
			-- Only consider high-value targets (capitals, major cities, army concentrations)
			if value >= 80 then
				table.insert(best_provinces, {province = k, value = value})
			end
		end
	end
	
	-- Sort by strategic value
	table.sort(best_provinces, function(a, b) return a.value > b.value end)
	
	local target = best_provinces[1]
	
	-- Only use nuke if it's a really valuable target
	if target and target.value >= 100 then
		if not lume.match(game_data.used_explosions, function(x) return x[1] == land and x[2] == target.province end) then
			core.nuclear_weapon(land, target.province)
		end
	end
end

-- Execute all weapons in coordinated manner
function M.execute_weapons_strategy(land)
	-- First: Air strikes to weaken defenses
	M.planes(land)
	
	-- Second: Artillery bombardment
	M.shell(land)
	
	-- Third: Chemical weapons for critical battles
	M.chemical(land)
	
	-- Fourth: Tank assaults for breakthrough
	M.tank(land)

	-- Fifth: Drone strikes (Technocracy)
	M.drone(land)

	-- Last: Nuclear option for strategic targets
	M.nuclear(land)
end

return M
