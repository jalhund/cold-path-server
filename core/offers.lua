local M = {}

local relations = require "core.relations"
local event_system = require "core.event_system"
--offers types: peace, pact, alliance, trade, war

function M.register(offer_type, from, to, offer_data)
	for k, v in pairs(game_data.new_offers) do
		if v[2] == offer_type and v[3] == from and v[4] == to and v[2] ~= "trade" then
			return
		end
	end
	table.insert(game_data.new_offers, {
		#game_data.new_offers + 1, offer_type, from, to, offer_data
	})
end

function M.handle()
	game_data.old_offers = deepcopy(game_data.new_offers)
	game_data.new_offers = {}
	for k, v in pairs(game_data.old_offers) do
		if v[2] == "war" then
			if relations.available_war(v[3], v[4]) then
				relations.register_war(v[3], v[4])
				if lume.match(game_data.lands[v[4]].bonuses, function(x) return x[1] == "consequence" end) then
					game_data.consequence_data[v[3]] = game_values.consequence_time
				end
			end
		elseif v[2] == "break_alliance" then
			if relations.check_alliance(v[3], v[4]) then
				relations.break_alliance(v[3], v[4])
			end
		elseif v[2] == "revolt" then
			event_system.dispatch("revolt", v[4], v[3])
			if game_data.lands[v[3]].vassal then
				relations.independence(v[3])
			end
			if relations.available_war(v[3], v[4]) then
				relations.register_war(v[3], v[4])
			end
		end
	end
end

function M.get_offers(land)
	local land_offers = {}
	for k, v in pairs(game_data.old_offers) do
		if v[4] == land then
			table.insert(land_offers, game_data.old_offers[k])
		end
	end
	return land_offers
end

function M.get_offer_by_id(offer_id)
	return game_data.old_offers[offer_id]
end

return M