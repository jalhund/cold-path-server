local M = {}

-- AI Memory System: Tracks diplomatic relationships and historical events
-- This improves AI decision-making by remembering past interactions

local function init_land_memory(land)
	if not game_data.lands[land].ai.memory then
		game_data.lands[land].ai.memory = {
			betrayals = {},           -- Who broke alliances with us {land: turn_number}
			reliable_allies = {},     -- Who helped in wars {land: times_helped}
			historical_enemies = {},  -- Long-term rivalries {land: wars_fought}
			trade_partners = {},      -- Positive economic relationships {land: trades_completed}
			war_history = {},         -- Track wars {land: {won: X, lost: Y, ongoing: bool}}
		}
	end
end

-- Initialize memory for all lands
function M.init()
	if not game_data then return end
	if not game_data.lands then return end
	
	for k, v in pairs(game_data.lands) do
		if k ~= "Undeveloped_land" and not v.defeated then
			init_land_memory(k)
		end
	end
end

-- Record when an alliance is broken
function M.record_betrayal(betrayer, victim)
	if not game_data.ai_memory_enabled then return end
	if not game_data.lands[victim] or game_data.lands[victim].defeated then return end
	
	init_land_memory(victim)
	game_data.lands[victim].ai.memory.betrayals[betrayer] = game_data.step
	
	-- Remove from reliable allies if they were there
	game_data.lands[victim].ai.memory.reliable_allies[betrayer] = nil
	
	-- Increase historical enmity
	if not game_data.lands[victim].ai.memory.historical_enemies[betrayer] then
		game_data.lands[victim].ai.memory.historical_enemies[betrayer] = 0
	end
	game_data.lands[victim].ai.memory.historical_enemies[betrayer] = 
		game_data.lands[victim].ai.memory.historical_enemies[betrayer] + 2
end

-- Record when an ally helps in war
function M.record_ally_help(helper, helped)
	if not game_data.ai_memory_enabled then return end
	
	init_land_memory(helped)
	if not game_data.lands[helped].ai.memory.reliable_allies[helper] then
		game_data.lands[helped].ai.memory.reliable_allies[helper] = 0
	end
	game_data.lands[helped].ai.memory.reliable_allies[helper] = 
		game_data.lands[helped].ai.memory.reliable_allies[helper] + 1
end

-- Record war start/end
function M.record_war(land1, land2, started)
	if not game_data.ai_memory_enabled then return end
	
	init_land_memory(land1)
	init_land_memory(land2)
	
	if started then
		-- Increment historical enemy counter
		if not game_data.lands[land1].ai.memory.historical_enemies[land2] then
			game_data.lands[land1].ai.memory.historical_enemies[land2] = 0
		end
		if not game_data.lands[land2].ai.memory.historical_enemies[land1] then
			game_data.lands[land2].ai.memory.historical_enemies[land1] = 0
		end
		
		game_data.lands[land1].ai.memory.historical_enemies[land2] = 
			game_data.lands[land1].ai.memory.historical_enemies[land2] + 1
		game_data.lands[land2].ai.memory.historical_enemies[land1] = 
			game_data.lands[land2].ai.memory.historical_enemies[land1] + 1
			
		-- Initialize war history
		if not game_data.lands[land1].ai.memory.war_history[land2] then
			game_data.lands[land1].ai.memory.war_history[land2] = {won = 0, lost = 0, ongoing = false}
		end
		if not game_data.lands[land2].ai.memory.war_history[land1] then
			game_data.lands[land2].ai.memory.war_history[land1] = {won = 0, lost = 0, ongoing = false}
		end
		
		game_data.lands[land1].ai.memory.war_history[land2].ongoing = true
		game_data.lands[land2].ai.memory.war_history[land1].ongoing = true
	end
end

-- Record successful trade
function M.record_trade(land1, land2)
	if not game_data.ai_memory_enabled then return end
	
	init_land_memory(land1)
	init_land_memory(land2)
	
	if not game_data.lands[land1].ai.memory.trade_partners[land2] then
		game_data.lands[land1].ai.memory.trade_partners[land2] = 0
	end
	if not game_data.lands[land2].ai.memory.trade_partners[land1] then
		game_data.lands[land2].ai.memory.trade_partners[land1] = 0
	end
	
	game_data.lands[land1].ai.memory.trade_partners[land2] = 
		game_data.lands[land1].ai.memory.trade_partners[land2] + 1
	game_data.lands[land2].ai.memory.trade_partners[land1] = 
		game_data.lands[land2].ai.memory.trade_partners[land1] + 1
end

-- Get trust level between two nations (-100 to 100)
function M.get_trust_level(land1, land2)
	if not game_data.ai_memory_enabled then return 0 end
	
	init_land_memory(land1)
	local memory = game_data.lands[land1].ai.memory
	local trust = 0
	
	-- Betrayals heavily reduce trust
	if memory.betrayals[land2] then
		local turns_ago = game_data.step - memory.betrayals[land2]
		-- Trust recovers slowly over time (100 turns to forgive)
		trust = trust - math.max(0, 50 - (turns_ago / 2))
	end
	
	-- Reliable allies increase trust
	if memory.reliable_allies[land2] then
		trust = trust + (memory.reliable_allies[land2] * 15)
	end
	
	-- Historical enemies reduce trust
	if memory.historical_enemies[land2] then
		trust = trust - (memory.historical_enemies[land2] * 8)
	end
	
	-- Trade partners increase trust
	if memory.trade_partners[land2] then
		trust = trust + (memory.trade_partners[land2] * 3)
	end
	
	-- Clamp between -100 and 100
	return math.max(-100, math.min(100, trust))
end

-- Check if land should avoid alliance with another due to history
function M.should_avoid_alliance(land1, land2)
	if not game_data.ai_memory_enabled then return false end
	
	local trust = M.get_trust_level(land1, land2)
	return trust < -30
end

-- Check if land prefers this ally over others
function M.is_preferred_ally(land1, land2)
	if not game_data.ai_memory_enabled then return false end
	
	local trust = M.get_trust_level(land1, land2)
	return trust > 30
end

-- Get historical enemy score (higher = more conflicts)
function M.get_rivalry_score(land1, land2)
	if not game_data.ai_memory_enabled then return 0 end
	
	init_land_memory(land1)
	return game_data.lands[land1].ai.memory.historical_enemies[land2] or 0
end

return M
