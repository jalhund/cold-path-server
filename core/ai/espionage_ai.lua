-- AI espionage behaviour (DLC «Шпионаж»).
--
-- Three independent decisions, all gated on the match-level `espionage_enabled`
-- toggle (via espionage.is_active):
--   * set_counter_intelligence budget from the land's threat level   -> M.set_budget
--   * build a single Intelligence Agency when it can afford one      -> M.maybe_build_agency
--   * run one secret operation per turn against an enemy             -> M.maybe_operate
--
-- Globals used (shared Lua VM): game_data, game_values, lume,
-- get_building_cost, get_province_for_land.

local M = {}

local espionage = require "core.espionage"
local core = require "core.core"

-- How often a country that *can* run an operation actually does so in a turn.
local OPERATE_CHANCE = 0.5
-- Money buffer required before the AI sinks 100k into an agency, so building one
-- never bankrupts it.
local AGENCY_MONEY_BUFFER = 1.5

-- "peace" | "threat" | "high" — drives the counter-intelligence budget.
local function threat_level(land)
	local l = game_data.lands[land]
	local enemies = 0
	local strong_enemy = false
	for _, e in pairs(l.enemies) do
		if e ~= "Undeveloped_land" and game_data.lands[e] and not game_data.lands[e].defeated then
			enemies = enemies + 1
			if game_data.lands[e].army > l.army then
				strong_enemy = true
			end
		end
	end
	if enemies == 0 then return "peace" end
	if strong_enemy then return "high" end
	return "threat"
end

-- Sets the land's counter-intelligence spending to match its current threat.
function M.set_budget(land)
	if not espionage.is_active() then return end
	local cfg = game_values.espionage
	local level = threat_level(land)
	local value = cfg.ai_counter_intelligence_peace
	if level == "threat" then
		value = cfg.ai_counter_intelligence_threat
	elseif level == "high" then
		value = cfg.ai_counter_intelligence_high_threat
	end
	core.set_counter_intelligence(land, value)
end

-- Capital (if still owned) or any owned land province to host the agency.
local function build_province(land)
	local cap = game_data.lands[land].capital
	if cap and game_data.provinces[cap] and not game_data.provinces[cap].water
	and game_data.provinces[cap].o == land then
		return cap
	end
	local p = get_province_for_land(land)
	if p and not game_data.provinces[p].water and game_data.provinces[p].o == land then
		return p
	end
	return nil
end

-- Builds one Intelligence Agency if the country has none and can comfortably afford it.
function M.maybe_build_agency(land)
	if not espionage.is_active() then return end
	local cost = get_building_cost(land, "intelligence_agency", nil)
	if game_data.lands[land].money < cost * AGENCY_MONEY_BUFFER then return end
	if espionage.has_agency(land) then return end
	local province = build_province(land)
	if not province then return end
	core.build(land, province, "intelligence_agency")
end

-- Most expensive operation first: the AI prefers high-impact ops it can afford.
local OP_PRIORITY = { "incite_rebellion", "steal_technology", "sabotage_building", "scout_troops" }

-- Runs at most one operation against a random enemy province this turn.
function M.maybe_operate(land)
	if not espionage.is_active() then return end
	if not espionage.has_agency(land) then return end
	local cfg = game_values.espionage
	local intel = espionage.get_intelligence(land)
	if intel < cfg.op_cost.scout_troops then return end
	if lume.random() > OPERATE_CHANCE then return end

	local enemies = {}
	for _, e in pairs(game_data.lands[land].enemies) do
		if espionage.valid_target_land(land, e) then
			table.insert(enemies, e)
		end
	end
	if #enemies == 0 then return end
	local enemy = lume.randomchoice(enemies)

	local provinces = {}
	for k, v in pairs(game_data.provinces) do
		if not v.water and v.o == enemy then
			table.insert(provinces, k)
		end
	end
	if #provinces == 0 then return end
	local province = lume.randomchoice(provinces)

	for _, op in ipairs(OP_PRIORITY) do
		if intel >= cfg.op_cost[op] and espionage.availability(land, province, op).ok then
			core.espionage(land, op, province)
			return
		end
	end
end

return M
