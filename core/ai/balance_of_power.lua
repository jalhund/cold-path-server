local M = {}

local core = require "core.core"
local relations = require "core.relations"

local function get_union_points(union)
	local p = 0
	for k, v in pairs(union) do
		p = p + get_land_points(v)
	end
	return p
end

local function get_union(land)
	local union = {
		land
	}
	local chunk_value = get_land_points(land)
	for k, v in pairs(game_data.lands) do
		if k ~= "Undeveloped_land" and not v.defeated then
			if relations.check_alliance(land, k) or relations.check_vassal(land, k) or relations.check_vassal(k, land) then
				table.insert(union, k)
				chunk_value = chunk_value + get_land_points(k)
			end
		end
	end
	return union, chunk_value
end

-- Advantage of union2
function M.check_advantage(union1, union2)
	return get_union_points(union1) + 200 < get_union_points(union2)
end

function M.check_land_advantage(land1, land2)
	local union1 = get_union(land1)
	local union2 = get_union(land2)

	return M.check_advantage(union1, union2)
end

function M.registered_war(aggressor, defender, is_player_function)
	local aggressor_union = get_union(aggressor)
	local defender_union = get_union(defender)

	local offers_count = 3
	if M.check_advantage(defender_union, aggressor_union) then
		for k, v in rpairs(game_data.lands) do
			if offers_count > 0 and k ~= "Undeveloped_land" and
			 not v.defeated and k ~= aggressor and k ~= defender and relations.available_war(k, aggressor)
			 and not is_player_function(defender) then
				core.alliance(defender, k)
				offers_count = offers_count - 1
			end
		end
	end
end

function M.prepare_pact(aggressor, defender, is_player_function)
	if not M.check_advantage(get_union(defender), get_union(aggressor)) then
		for k, v in rpairs(game_data.lands) do
			if not v.defeated and k ~= "Undeveloped_land" and relations.available_pact(aggressor, k)
			and not is_player_function(aggressor) and k ~= aggressor then
				core.pact(aggressor, k)
				break
			end
		end
	end
end

function M.update_balance(is_player_function)
	local max_union_value = 0
	local max_union = {}
	local second_union_value = 0

	local calculated_lands = {}

	for k, v in rpairs(game_data.lands) do
		if k ~= "Undeveloped_land" and not v.defeated and not find_in_table(k, calculated_lands) then
			local union, union_value = get_union(k)
			if union_value > max_union_value then
				second_union_value = max_union_value
				max_union_value = union_value
				max_union = union
				lume.extend(calculated_lands, max_union)
			end
		end
	end

	if max_union_value > second_union_value * 2.5 and lume.random() < 0.05 then
		for k, v in spairs(max_union, function(t,a,b)
			return get_land_points(max_union[a]) > get_land_points(max_union[b])
		end) do
			if #game_data.lands[v].allies > 0 and 
			not is_player_function(v) then
				core.break_alliance(v, game_data.lands[v].allies[1])
				break
			end
		end
	end
end

return M