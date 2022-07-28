-- Anticheat plugin. This plugin checks if players can take some action.
-- Example: Server received a command from the player to build some building. But the player doesn't have enough money
-- TODO: almost nothing has been done

local M = {}

local relations = require "core.relations"
local offers = require "core.offers"

local t = {}

local function is_water(province)
	return game_data.provinces[province].water
end

function t.recruit(land, province, amount)
	if not game_data.lands[land] or not game_data.provinces[province] then
		return false
	end
	return not is_water(province) and game_data.provinces[province].p - amount >= game_values.min_population
			and game_data.lands[land].money > 0
end

function t.move(land,from,to,amount)
	if not game_data.lands[land] or not game_data.provinces[from] or not game_data.provinces[to] then
		return false
	end
	return army_functions.get_army(from, land) >= amount
end

function t.dissolve(land, province, percent)
	if not game_data.lands[land] or not game_data.provinces[province] then
		return false
	end
	return army_functions.get_army(province, land) > 0 and percent >= 0 and percent <= 1
end

function t.shell(land, from, to, count)
	if not game_data.lands[land] or not game_data.provinces[from] or not game_data.provinces[to] then
		return false
	end
	return army_functions.get_army(from, land) > count and relations.possible_shell(land, from, to)
end

function t.air_attack(land, from, to)
	if not game_data.lands[land] or not game_data.provinces[from] or not game_data.provinces[to] then
		return false
	end
	return not is_water(from) and game_data.provinces[from].b.aerodrome
			and relations.possible_air_attack(land, to)
end

function t.tank(land, from, to)
	if not game_data.lands[land] or not game_data.provinces[from] or not game_data.provinces[to] then
		return false
	end
	return game_data.lands[land].resources.tank > 0 and game_data.provinces[from].o == land
end

function t.open_skill(land, skill)
	if not game_data.lands[land] or not skills_data[skill] then
		return false
	end
	return game_data.lands[land].skills >= skills_data[skill].cost and check_skill(skill, land) == "available"
end

function t.select_technology(land, technology)
	if not game_data.lands[land] or not technology_data[technology] then
		return false
	end
	return check_technology(technology, land) == "available"
end

function t.set_tax(land, tax)
	if not game_data.lands[land] then
		return false
	end
	return tax >= 0 and tax <= 1
end

function t.set_ideology(land, ideology)
	if not game_data.lands[land] then
		return false
	end
	local t = {
		"republic", "trade_republic", "democracy", "monarchy", "theocracy", "communism", "fascism", "anarchism"
	}
	return find_in_table(ideology, t) and ideology ~= game_data.lands[land].ideology and
			game_data.step - game_data.lands[land].changed_ideology >= game_values.ideology_cooldown
end

function t.build(land, province, building_id)
	if not game_data.lands[land] or not game_data.provinces[province] or not get_building_data(building_id) then
		return false
	end
	return not is_water(province) and game_data.provinces[province].o == land and
			game_data.lands[land].money >= get_building_cost(land, building_id, game_data.provinces[province].b[building_id])
			and (not game_data.provinces[province].b[building_id] or
			game_data.provinces[province].b[building_id] < #get_building_data(building_id).lvl)
end

function t.destroy(land, province, building_id)
	if not game_data.lands[land] or not game_data.provinces[province] or not get_building_data(building_id) then
		return false
	end
	return not game_data.provinces[province].water and game_data.provinces[province].o == land and
			game_data.provinces[province].b[building_id]
end

function t.peace(from, to)
	if not game_data.lands[from] or not game_data.lands[to] then
		return false
	end
	return true
end

function t.pact(from, to)
	if not game_data.lands[from] or not game_data.lands[to] then
		return false
	end
	return true
end

function t.war(from, to)
	if not game_data.lands[from] or not game_data.lands[to] then
		return false
	end
	return true
end

function t.alliance(from, to)
	if not game_data.lands[from] or not game_data.lands[to] then
		return false
	end
	return true
end

function t.break_alliance(from, to)
	if not game_data.lands[from] or not game_data.lands[to] then
		return false
	end
	return true
end

function t.chemical_weapon(land, from, to)
	if not game_data.lands[land] or not game_data.provinces[from] or not game_data.provinces[to] then
		return false
	end
	return not is_water(from) and not is_water(to) and relations.check_war(game_data.provinces[to].o,
			game_data.provinces[from].o) and is_neighbour_province(to, game_data.provinces[from].o) and
			game_data.lands[game_data.provinces[from].o].resources.chemical_weapon > 0
end

function t.nuclear_weapon(land, province)
	if not game_data.lands[land] or not game_data.provinces[province] then
		return false
	end
	return not is_water(province) and relations.check_war(land, game_data.provinces[province].o) and
			game_data.lands[land].resources.uranium >= game_values.nuclear_weapon_cost_uranium
end

function t.vassal(land1, land2)
	if not game_data.lands[land1] or not game_data.lands[land2] then
		return false
	end
	return true
end

function t.revolt(owner, vassal)
	if not game_data.lands[owner] or not game_data.lands[vassal] then
		return false
	end
	return game_data.lands[vassal].vassal == owner
end

function t.independence(owner, vassal)
	if not game_data.lands[owner] or not game_data.lands[vassal] then
		return false
	end
	return game_data.lands[vassal].vassal == owner
end

function t.trade(from, to, from_list, to_list)
	if not game_data.lands[from] or not game_data.lands[to] then
		return false
	end
	return true
end

function t.urge_allies(land, enemy)
	if not game_data.lands[land] or not game_data.lands[enemy] then
		return false
	end
	return relations.check_war(land, enemy)
end

function t.support_revolt(from, to, value)
	if not game_data.lands[from] or not game_data.lands[to] then
		return false
	end
	return game_data.lands[from].money > value
end

function t.accept_offer(land, offer_id)
	if not game_data.lands[land] then
		return false
	end
	local offer = offers.get_offer_by_id(offer_id)
	return offer and offer[4] == land
end

function M.verify_action(action_id, ...)
	local arg = {...}
	if t[action_id] then
		local result = t[action_id](unpack(arg))
		pprint("anticheat: verify_action", action_id, arg, result)
		return result
	else
		return true
	end
end

return M