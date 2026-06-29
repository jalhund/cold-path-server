local M = {}

-- Adaptive Difficulty: Dynamically adjusts AI bonuses based on player performance
-- Helps create more balanced and engaging gameplay

local function get_player_land(is_player_function)
	for k, v in pairs(game_data.lands) do
		if k ~= "Undeveloped_land" and not v.defeated and is_player_function(k) then
			return k
		end
	end
	return nil
end

local function get_average_ai_points()
	local total = 0
	local count = 0
	for k, v in pairs(game_data.lands) do
		if k ~= "Undeveloped_land" and not v.defeated then
			total = total + get_land_points(k)
			count = count + 1
		end
	end
	return count > 0 and (total / count) or 0
end

-- Calculate player's relative strength
function M.get_player_dominance_ratio(is_player_function)
	if not game_data.adaptive_difficulty_enabled then return 1.0 end
	
	local player_land = get_player_land(is_player_function)
	if not player_land then return 1.0 end
	
	local player_points = get_land_points(player_land)
	local avg_ai_points = get_average_ai_points()
	
	if avg_ai_points == 0 then return 1.0 end
	
	return player_points / avg_ai_points
end

-- Get dynamic difficulty modifier for AI
-- Returns multiplier for AI costs (lower = AI gets cheaper units)
function M.get_adaptive_cost_modifier(base_modifier, is_player_function)
	if not game_data.adaptive_difficulty_enabled then return base_modifier end
	
	local dominance = M.get_player_dominance_ratio(is_player_function)
	
	-- If player is dominating (2x stronger than average)
	if dominance > 2.0 then
		-- Give AI a boost (reduce costs)
		return base_modifier * 0.7
	-- If player is very strong (1.5x)
	elseif dominance > 1.5 then
		return base_modifier * 0.85
	-- If player is struggling (0.5x weaker)
	elseif dominance < 0.5 then
		-- Make AI slightly more expensive (easier for player)
		return base_modifier * 1.15
	-- If player is weak (0.75x)
	elseif dominance < 0.75 then
		return base_modifier * 1.08
	end
	
	-- Normal range - no adjustment
	return base_modifier
end

-- Check if AI should form coalition against player
function M.should_form_anti_player_coalition(is_player_function)
	if not game_data.adaptive_difficulty_enabled then return false end
	
	local dominance = M.get_player_dominance_ratio(is_player_function)
	
	-- If player is very strong, encourage AIs to band together
	if dominance > 2.5 then
		return lume.random() < 0.15  -- 15% chance per turn
	elseif dominance > 2.0 then
		return lume.random() < 0.08  -- 8% chance per turn
	end
	
	return false
end

-- Get bonus aggression toward player if they're too strong
function M.get_player_target_priority_bonus(is_player_function)
	if not game_data.adaptive_difficulty_enabled then return 0 end
	
	local dominance = M.get_player_dominance_ratio(is_player_function)
	
	-- Add bonus score when considering player as target
	if dominance > 2.5 then
		return 60  -- High priority
	elseif dominance > 2.0 then
		return 35  -- Medium priority
	elseif dominance > 1.5 then
		return 15  -- Low priority
	end
	
	return 0
end

-- Form coalition against dominant player
function M.form_anti_player_coalition(is_player_function)
	if not M.should_form_anti_player_coalition(is_player_function) then
		return
	end
	
	local player_land = get_player_land(is_player_function)
	if not player_land then return end
	
	local relations = require "core.relations"
	local core = require "core.core"
	
	-- Find AIs not allied with player
	local potential_allies = {}
	for k, v in pairs(game_data.lands) do
		if k ~= "Undeveloped_land" and not v.defeated and k ~= player_land 
			and not is_player_function(k) then
			if not relations.check_alliance(k, player_land) and not relations.check_vassal(k, player_land) then
				table.insert(potential_allies, k)
			end
		end
	end
	
	-- Form alliances between AIs
	if #potential_allies >= 2 then
		local land1 = lume.randomchoice(potential_allies)
		table.remove(potential_allies, lume.find(potential_allies, land1))
		local land2 = lume.randomchoice(potential_allies)
		
		if relations.available_alliance(land1, land2) then
			core.alliance(land1, land2, {
				id = "balance_of_power",
				land = player_land
			})
		end
	end
end

-- Apply adaptive difficulty adjustments
function M.apply(difficulty_data, is_player_function)
	if not game_data.adaptive_difficulty_enabled then 
		return difficulty_data 
	end
	
	-- Create modified difficulty data
	local modified = {
		recruit_cost_modifier = M.get_adaptive_cost_modifier(difficulty_data.recruit_cost_modifier, is_player_function),
		maintenance_cost_modifier = M.get_adaptive_cost_modifier(difficulty_data.maintenance_cost_modifier, is_player_function),
		discontent_pay_off = difficulty_data.discontent_pay_off,
		discontent_disperse = difficulty_data.discontent_disperse,
		discontent_independence = difficulty_data.discontent_independence,
		move_army = difficulty_data.move_army
	}
	
	return modified
end

return M
