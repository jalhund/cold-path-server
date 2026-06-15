-- Espionage operations (DLC «Шпионаж»).
--
-- This module holds the authoritative logic for the four secret operations and
-- the counter-intelligence outcome resolution. It mutates game_data directly and
-- dispatches notification events, so it can be driven:
--   * locally with an authoritative roll (single-player)        -> M.perform
--   * with a server-decided outcome + params (multiplayer)      -> M.execute
--
-- Globals used (shared Lua VM): game_data, game_values, lume, technology_data,
-- deepcopy, get_num_of_provinces, count_elements_in_table.

local M = {}

local event_system = require "core.event_system"
local relations = require "core.relations"
local ideology = require "core.ideology"
local calc_functions = require "core.calc_functions"

-- Buildings that are special scenario objects / not regular buildings and thus
-- cannot be sabotaged.
local SPECIAL_BUILDINGS = {
	megarefrigerator = true,
	machine_a = true,
	machine_b = true,
	machine_c = true,
}

M.operations = { "scout_troops", "sabotage_building", "steal_technology", "incite_rebellion" }

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

function M.is_active()
	return game_data.espionage_enabled == true
end

function M.op_cost(op)
	return game_values.espionage.op_cost[op]
end

-- Does the country currently own an Intelligence Agency? (Operations require one.)
function M.has_agency(land)
	for k, v in pairs(game_data.provinces) do
		if not v.water and v.o == land and v.b and v.b.intelligence_agency then
			return true
		end
	end
	return false
end

function M.get_intelligence(land)
	local l = game_data.lands[land]
	return l and (l.intelligence or 0) or 0
end

-- Operations are allowed against any living foreign country (neutral, allied or
-- vassal). Forbidden against self, defeated countries and Undeveloped land.
function M.valid_target_land(organizer, target)
	if not target or target == organizer then return false end
	if target == "Undeveloped_land" then return false end
	local t = game_data.lands[target]
	if not t or t.defeated then return false end
	return true
end

-- Regular (sabotageable) buildings present in a province.
function M.sabotageable_buildings(province)
	local list = {}
	local p = game_data.provinces[province]
	if p and not p.water and p.b then
		for id, lvl in pairs(p.b) do
			if not SPECIAL_BUILDINGS[id] then
				table.insert(list, id)
			end
		end
	end
	return list
end

-- Technologies the target has researched and the organizer has not.
function M.stealable_technologies(organizer, target)
	local have = {}
	for _, t in ipairs(game_data.lands[organizer].opened_technology) do
		have[t] = true
	end
	local candidates = {}
	for _, t in ipairs(game_data.lands[target].opened_technology) do
		if not have[t] then
			table.insert(candidates, t)
		end
	end
	return candidates
end

-- Whether the existing rebellion system can actually spawn a new state in `target`.
function M.rebellion_possible(target)
	return get_num_of_provinces(target) > 10
		and ideology.available_revolt(target)
		and count_elements_in_table(game_data.lands) < 60
end

----------------------------------------------------------------------
-- Counter-intelligence resolution
----------------------------------------------------------------------

-- Returns hidden, revealed, fail probabilities (fractions, sum to 1) for the
-- target's current counter-intelligence spending.
function M.outcome_probabilities(target)
	local l = game_data.lands[target]
	local c = (l and l.counter_intelligence) or game_values.espionage.counter_intelligence_default
	local p = c * 100
	if p < 0 then p = 0 elseif p > 50 then p = 50 end

	local hidden, revealed, fail
	if p <= 0 then
		hidden, revealed, fail = 1, 0, 0
	elseif p <= 25 then
		-- Each 1% of budget adds 2pp to both revealed success and failure.
		revealed = (p * 2) / 100
		fail = (p * 2) / 100
		hidden = 1 - revealed - fail
	else
		-- Above 25% hidden success is impossible; each extra 1% moves 2pp from
		-- revealed success to failure.
		local extra = p - 25
		hidden = 0
		revealed = (50 - 2 * extra) / 100
		fail = (50 + 2 * extra) / 100
	end
	if hidden < 0 then hidden = 0 end
	if revealed < 0 then revealed = 0 end
	return hidden, revealed, fail
end

-- Authoritative random outcome roll: "hidden" | "revealed" | "fail".
function M.roll_outcome(target)
	local hidden, revealed = M.outcome_probabilities(target)
	local r = lume.random()
	if r < hidden then
		return "hidden"
	elseif r < hidden + revealed then
		return "revealed"
	else
		return "fail"
	end
end

----------------------------------------------------------------------
-- Availability
----------------------------------------------------------------------

-- Returns a table: { ok = true, target = <land>, [buildings|technologies] = ... }
-- or { ok = false, reason = <string> } where reason is a lang key:
-- espionage_disabled, invalid_target, no_agency, not_enough_intelligence,
-- no_building, no_technology, no_rebellion.
function M.availability(organizer, target_province, op)
	if not M.is_active() then
		return { ok = false, reason = "espionage_disabled" }
	end
	local province = game_data.provinces[target_province]
	local target = province and not province.water and province.o
	if not M.valid_target_land(organizer, target) then
		return { ok = false, reason = "invalid_target" }
	end
	if not M.has_agency(organizer) then
		return { ok = false, reason = "no_agency" }
	end
	if M.get_intelligence(organizer) < M.op_cost(op) then
		return { ok = false, reason = "not_enough_intelligence" }
	end

	if op == "scout_troops" then
		return { ok = true, target = target }
	elseif op == "sabotage_building" then
		local list = M.sabotageable_buildings(target_province)
		if #list == 0 then
			return { ok = false, reason = "no_building" }
		end
		return { ok = true, target = target, buildings = list }
	elseif op == "steal_technology" then
		local techs = M.stealable_technologies(organizer, target)
		if #techs == 0 then
			return { ok = false, reason = "no_technology" }
		end
		return { ok = true, target = target, technologies = techs }
	elseif op == "incite_rebellion" then
		if not M.rebellion_possible(target) then
			return { ok = false, reason = "no_rebellion" }
		end
		return { ok = true, target = target }
	end

	return { ok = false, reason = "invalid_target" }
end

----------------------------------------------------------------------
-- Notifications
----------------------------------------------------------------------

-- Queues a target-side notification. All targets are queued (the queue travels
-- inside game_data, so in multiplayer every client receives it); each recipient
-- filters the queue to its own land when draining it (see handle_espionage_notifications).
local function queue_target(info)
	game_data.espionage_notifications = game_data.espionage_notifications or {}
	table.insert(game_data.espionage_notifications, info)
end

function M.notify(result)
	-- The organizer always learns the full outcome immediately.
	event_system.dispatch("espionage_organizer_result", result)

	-- What the target learns depends on the outcome.
	if result.outcome == "revealed" then
		local info = {
			op = result.op,
			outcome = "revealed",
			organizer = result.organizer, -- revealed: the target learns who did it
			target = result.target,
			province = result.province,
			building = result.building,
			technology = result.technology,
			new_land = result.new_land,
		}
		event_system.dispatch("espionage_target_result", info)
		queue_target(info)
	elseif result.outcome == "fail" then
		local info = {
			op = result.op,
			outcome = "fail",
			organizer = nil, -- failure: counter-intel intercepted, organizer not revealed
			target = result.target,
			province = result.province,
		}
		event_system.dispatch("espionage_target_result", info)
		queue_target(info)
	end
	-- "hidden": the target receives no spy notification. Visible consequences
	-- (destroyed building, rebellion) surface through the usual game events.
end

----------------------------------------------------------------------
-- Effects
----------------------------------------------------------------------

local function spend(organizer, op)
	game_data.lands[organizer].intelligence = M.get_intelligence(organizer) - M.op_cost(op)
end

local function store_scouting(organizer, target_province)
	local snapshot = {}
	for owner, count in pairs(game_data.provinces[target_province].a) do
		snapshot[owner] = count
	end
	game_data.espionage_scouted = game_data.espionage_scouted or {}
	game_data.espionage_scouted[organizer] = game_data.espionage_scouted[organizer] or {}
	game_data.espionage_scouted[organizer][target_province] = snapshot
	return snapshot
end

local function apply_stolen_technology(organizer, tech)
	for _, t in ipairs(game_data.lands[organizer].opened_technology) do
		if t == tech then return false end
	end
	table.insert(game_data.lands[organizer].opened_technology, tech)
	for _, bonus in pairs(technology_data[tech].bonuses) do
		local b = deepcopy(bonus)
		if not b[2] then b[2] = 0 end
		b[3] = "technology"
		table.insert(game_data.lands[organizer].bonuses, b)
	end
	return true
end

-- Executes an operation with a pre-determined outcome and params. Authoritative
-- side (single-player local or multiplayer server) decides `outcome` and `params`.
-- params: { building = <id> } for sabotage, { technology = <id> } for steal.
function M.execute(organizer, op, target_province, outcome, params)
	params = params or {}
	local target = game_data.provinces[target_province].o

	spend(organizer, op)

	local result = {
		op = op,
		organizer = organizer,
		target = target,
		province = target_province,
		outcome = outcome,
	}

	if outcome == "fail" then
		M.notify(result)
		return result
	end

	if op == "scout_troops" then
		result.scouted = store_scouting(organizer, target_province)

	elseif op == "sabotage_building" then
		local building = params.building
		if building and game_data.provinces[target_province].b[building] then
			game_data.provinces[target_province].b[building] = nil
			result.building = building
		else
			result.failed_effect = true
		end

	elseif op == "steal_technology" then
		local tech = params.technology
		if tech and apply_stolen_technology(organizer, tech) then
			result.technology = tech
		else
			result.failed_effect = true
		end

	elseif op == "incite_rebellion" then
		local new_land = calc_functions.force_rebellion(target)
		if new_land then
			relations.register_war(new_land, target)
			result.new_land = new_land
		else
			result.failed_effect = true
		end
	end

	M.notify(result)
	return result
end

-- Authoritatively performs an operation: validates, rolls the outcome, picks any
-- random params and executes. Used in single-player and on the multiplayer server.
-- Returns the result table, or the availability table when not allowed.
function M.perform(organizer, op, target_province, chosen_building)
	local avail = M.availability(organizer, target_province, op)
	if not avail.ok then
		return avail
	end

	local outcome = M.roll_outcome(avail.target)
	local params = {}
	if op == "sabotage_building" then
		params.building = chosen_building or lume.randomchoice(avail.buildings)
	elseif op == "steal_technology" then
		params.technology = lume.randomchoice(avail.technologies)
	end

	return M.execute(organizer, op, target_province, outcome, params)
end

-- Per-turn cleanup: scouting snapshots only last until the end of the turn.
function M.clear_scouting()
	game_data.espionage_scouted = {}
end

return M
