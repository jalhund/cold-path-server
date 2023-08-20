local M = {}

adjacency_map = {}
local json = require "scripts.utils.json"
army_functions = require "core.army_functions"
local relations = require "core.relations"

--debug game_data file
function table_print(tt, indent, done)
	done = done or {}
	indent = indent or 0
	if type(tt) == "table" then
		local sb = {}
		for key, value in pairs (tt) do
			table.insert(sb, string.rep (" ", indent)) -- indent it
			if type (value) == "table" and not done [value] then
				done [value] = true
				table.insert(sb, key .. " = {\n");
				table.insert(sb, table_print (value, indent + 2, done))
				table.insert(sb, string.rep (" ", indent)) -- indent it
				table.insert(sb, "}\n");
			elseif "number" == type(key) then
				table.insert(sb, string.format("\"%s\"\n", tostring(value)))
			else
				table.insert(sb, string.format(
				"%s = \"%s\"\n", tostring (key), tostring(value)))
			end
		end
		return table.concat(sb)
	else
		return tt .. "\n"
	end
end

function color_to_vector(t)
	return vmath.vector4(t[1]/255, t[2]/255, t[3]/255, 1)
end

function get_land_color(land)
	return color_to_vector(game_data.lands[land].color)
end

function find_in_table(item,items)
	for _,v in pairs(items) do
		if v == item then
			return true
		end
	end
	return false
end

function remove_from_table(item,items)
	local deleted = false
	for i = 1, #items do
		if items[i] == item then
			table.remove(items,i)
			deleted = true
			return deleted
		end
	end
	return deleted
end

function join(items, delimitor, start_pos)
	local str = ""
	for i = start_pos, #items do
		str = str..items[i]..delimitor
	end
	return str
end

function split_string(str, n_line)
	local splitted_str = {}
	local i = 1
	local j = 1
	for line in string.gmatch(str, "[^\n]+") do
		splitted_str[i] = (splitted_str[i] or "")..line.."\n"
		if j > n_line then
			i = i + 1
			j = 1
		end
		j = j + 1
	end
	return splitted_str
end

function get_key_for_value( t, value )
	for k, v in pairs(t) do
		if v == value then
			return k
		end
	end
	return nil
end

function rpairs(t)
	local keys = {}
	for k in pairs(t) do keys[#keys+1] = k end

	-- if order function given, sort by it by passing the table and keys a, b,
	-- otherwise just sort the keys 
	lume.shuffle(keys)

	-- return the iterator function
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

function spairs(t, order)
	-- collect the keys
	local keys = {}
	for k in pairs(t) do keys[#keys+1] = k end

	-- if order function given, sort by it by passing the table and keys a, b,
	-- otherwise just sort the keys 
	if order then
		table.sort(keys, function(a,b) return order(t, a, b) end)
	else
		table.sort(keys)
	end

	-- return the iterator function
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

function count_elements_in_table(tab)
	local n = 0
	for k, v in pairs(tab) do
		n = n + 1
	end
	return n
end

function get_rotation(vec1,vec2)
	if vec1.x == vec2.x then
		if vec1.y < vec2.y then
			return math.pi/2
		else
			return 3*math.pi/2
		end
	elseif vec1.y == vec2.y then
		if vec1.x < vec2.x then
			return 0
		else
			return math.pi
		end
	else
		return math.atan2(vec2.y-vec1.y,vec2.x-vec1.x)
	end
end

function vassal_list(land)
	local t = {}
	for k, v in pairs(game_data.lands) do
		if not v.defeated and v.vassal == land then
			table.insert(t, k)
		end
	end
	return t
end

function load_adjacency(debug_mode, custom_path)
	adjacency_map = {}
	local data = ""
	local path
	if game_data.map == "europe" then
		path = "assets/adjacency_map_europe.dat"
	elseif game_data.map == "america" then
		path = "assets/adjacency_map_america.dat"
	elseif game_data.map == "lp_16" then
		path = "assets/adjacency_map_lp_16.dat"
	elseif game_data.map == "pvp" then
		path = "assets/adjacency_map_pvp.dat"
	elseif game_data.map == "europeamerica" then
		path = "assets/adjacency_map_europeamerica.dat"
	elseif game_data.map == "europe_remastered" then
		path = "assets/adjacency_map_europe_remastered.dat"
	else
	    if not network.is_console()  then
            path = debug_game_mode_file_path.."exported_map/adjacency.dat"
        else
            path = "maps/"..game_data.map.."/adjacency.dat"
        end
	end

	if debug_mode then
		path = "adjacency_map.dat"
		if custom_path then
			path = custom_path
		end
	end
    log("Load adjacency path is: ", path)
	if network.is_console() or debug_mode then
		local file = io.open(path, "r")
		data = file:read("*a")
		file:close()
	else
		data = sys.load_resource("/"..path)
	end
	-- pprint("Adjacency. Loaded data: ", data)

	local first = true
	for line in string.gmatch(data, "[^\n]+") do
		local prov = nil
		for i in string.gmatch(line, "%S+") do
			if custom_path then
				i = tonumber(i)
			end
			if first then
				first = false
				prov = i
				adjacency_map[i] = {}
			else
				table.insert(adjacency_map[prov], i)
			end
		end
		first = true
	end
	for k, v in pairs(adjacency_map) do
		for key, val in pairs(v) do
			if not find_in_table(k, adjacency_map[val]) then
				print("\n ERROR ON PROVINCES: ", k, val)
			end
		end
	end
    -- pprint("adjacency map is", adjacency_map)
end

function get_adjacency(province)
	return adjacency_map[province]
end

function is_neighbour(land1,land2)
	for k, v in pairs(adjacency_map) do
		for key, val in pairs(v) do
			if game_data.provinces[k].o == land1 and game_data.provinces[val].o == land2 then
				return true
			end
		end
	end
	return false
end

function is_neighbour_province(province,land2)
	for key, val in pairs(adjacency_map[province]) do
		if game_data.provinces[val].o == land2 then
			--print("Province: ", province, " is neighbour ", land2)
			return true
		end
	end
	return false
end

function without_neighbour_province(province)
	for key, val in pairs(adjacency_map[province]) do
		local o = {}
		if game_data.provinces[val].water then
			for k, v in pairs(game_data.provinces[val].a) do
				table.insert(o, k)
			end
		else
			table.insert(o, game_data.provinces[val].o)
		end
		for k, v in pairs(o) do
			if v ~= game_data.provinces[province].o
			and v ~= "Undeveloped_land"
			and not relations.check_alliance(v, game_data.provinces[province].o)
			and not relations.check_vassal(v, game_data.provinces[province].o)
			and not relations.check_vassal(game_data.provinces[province].o, v) then
				--print("Province: ", province, " is neighbour ", land2)
				return false
			end
		end
	end
	return true
end

function get_neighbour_provinces(land1,land2)
	t = {}
	for k, v in pairs(adjacency_map) do
		for key, val in pairs(v) do
			if game_data.provinces[k].o == land1 and game_data.provinces[val].o == land2 then
				--print("Province: ", k, " is neightbour ", val)
				if not t[k] then
					t[k] = {}
				end
				table.insert(t[k],val)
			end
		end
	end
	return t
end

function get_list_adjacency_map(province)
	return adjacency_map[province]
end

function check_skill(skill, land)
	if find_in_table(skill, game_data.lands[land].opened_skills) then
		return "opened"
	elseif not skills_data[skill].requirement or find_in_table(skills_data[skill].requirement, game_data.lands[land].opened_skills) then
		return "available"
	else
		return "closed"
	end
end

function check_technology(technology, land)
	local opened_req = true
	if technology_data[technology].requirements then
		for k, v in pairs(technology_data[technology].requirements) do
			if not find_in_table(v, game_data.lands[land].opened_technology) then
				opened_req = false
			end
		end
	end
	if find_in_table(technology, game_data.lands[land].opened_technology) then
		return "opened"
	elseif opened_req then
		return "available"
	else
		return "closed"
	end
end

function get_building_data(id)
	for k, v in pairs(buildings_data) do
		for i = 1, #v do
			if v[i].id == id then
				return v[i]
			end
		end
	end
	print("Error: not found building_data for: ", id)
end

function get_buildings_data(land)
	local t = {}
	for k, v in pairs(game_data.provinces) do
		if not v.water and v.o == land then
			for key, val in pairs(v.b) do
				t[key] = (t[key] or 0) + 1
			end
		end
	end
	return t
end

function available_building(land, province, id)
	local building_data = get_building_data(id)
	local n_lvl = game_data.provinces[province].b[id] and game_data.provinces[province].b[id] + 1 or 1
	local lvl = ""
	if #building_data.lvl > 1 then
		lvl = "_"..n_lvl
	end

	if building_data.lvl[n_lvl] and building_data.lvl[n_lvl].resource_cost then
		for k, v in pairs(building_data.lvl[n_lvl].resource_cost) do
			if game_data.lands[land].resources[k] < v then
				return false, "no_resources"
			end
		end
	end

	if game_data.provinces[province].o ~= land then
		return false, "you cannot build here"
	elseif game_data.provinces[province].b[id] and
		game_data.provinces[province].b[id] == #get_building_data(id).lvl then
		return false, "maximum level"
	elseif not game_data.provinces[province].b[id] and 
	count_elements_in_table(game_data.provinces[province].b) >= province_buildings_limit(province) then
		return false, "buildings limit"
	elseif game_data.lands[land].money < get_building_cost(land, id, game_data.provinces[province].b[id]) then
		return false, "no_money"
	elseif not lume.match(game_data.lands[land].bonuses, function(x) return x[1] == "building_"..id..lvl end) then
		return false, "no_technology"
	else
		return true
	end
end

function check_building(province, building)
	-- print("check building:", province, building)
	return game_data.provinces[province].b[building]
end

function get_building_cost(land, id, lvl)
	-- print("land, id, lvl: ", land, id, lvl)
	local lvl = lvl and lvl + 1 or 1
	local max_lvl = #get_building_data(id).lvl
	if lvl > max_lvl then
		lvl = max_lvl
	end

	local b = 1
	for k, v in pairs(game_data.lands[land].bonuses) do
		if v[1] == "cheaper_buildings" then
			b = b * v[2]
		end
	end
	return math.floor(get_building_data(id).lvl[lvl].cost / b)
end

function province_buildings_limit(province)
	if is_capital(province) then
		return game_values.buildings_limit_capital
	else
		return game_values.buildings_limit
	end
end

function available_resource(land, resource_data)
	if resource_data.requirment and not lume.match(game_data.lands[land].bonuses, function(x)
	 return x[1] == resource_data.requirment end) then
		return false
	end
	return true
end

function is_visible(land1, province)
	if debug_visible then
		return true
	end
	local land2 = game_data.provinces[province].o
	if land2 then
		if land1 == land2 then
			return true
		elseif relations.check_alliance(land1, land2) then
			return true
		elseif relations.check_vassal(land1, land2) or relations.check_vassal(land2, land1) then
			return true
		end
		for k, v in pairs(adjacency_map[province]) do
			if (game_data.provinces[v].water and army_functions.get_army(v, land1) > 0) then
				return true
			elseif game_data.provinces[v].o == land1 then
				return true
			end
		end

	else
        -- print("Look path for province: ", province)
		for k, v in pairs(adjacency_map[province]) do
            --print(k,v, game_data.provinces[v])
			if game_data.provinces[v].water and army_functions.get_army(v, land1) > 0 then
				return true
			elseif army_functions.get_army(province, land1) > 0 then
				return true
			elseif game_data.provinces[v].o == land1 then
				return true
			end
		end
	end
end

function is_full_visible(land1, province)
	if debug_visible then
		return true
	end
	local land2 = game_data.provinces[province].o
	local b = false
	if land2 then
		if land1 == land2 then
			return true
		elseif relations.check_alliance(land1, land2) then
			return true
		elseif relations.check_vassal(land1, land2) or relations.check_vassal(land2, land1) then
			return true
		end
		for k, v in pairs(adjacency_map[province]) do
			if (game_data.provinces[v].water and army_functions.get_army(v, land1) > 0) then
				b = false
			elseif game_data.provinces[v].o == land1 then
				if check_building(v, "tower") then
					b = true
				end
			end
		end

	else
		for k, v in pairs(adjacency_map[province]) do
			if game_data.provinces[v].water and army_functions.get_army(v, land1) > 0 then
				return true
			elseif army_functions.get_army(province, land1) > 0 then
				return true
			elseif game_data.provinces[v].o == land1 then
				if check_building(v, "beacon") then
					b = true
				end
			end
		end
	end
	return b
end

function air_protected(land, province, lvl)
	lvl = lvl or 1
	if not game_data.provinces[province].water and
	game_data.provinces[province].b.air_defense and game_data.provinces[province].b.air_defense >= lvl then
		return true, province
	end
	--Radius 3
	for k, v in pairs(adjacency_map[province]) do
		if not game_data.provinces[v].water and game_data.provinces[v].b.air_defense and game_data.provinces[v].b.air_defense >= lvl
		and (relations.check_war(land, game_data.provinces[v].o)) then
			return true, v
		end
		for key, val in pairs(adjacency_map[v]) do
			if not game_data.provinces[val].water and 
			game_data.provinces[val].b.air_defense and game_data.provinces[val].b.air_defense >= lvl
			and (relations.check_war(land, game_data.provinces[val].o)) then
				return true, val
			end
		end
	end
	return false
end

function air_available(land, from, to)
	--Radius 3
	for k, v in pairs(adjacency_map[from]) do
		if v == to and relations.possible_air_attack(land, to) then
			return true
		end
		for key, val in pairs(adjacency_map[v]) do
			if val == to and relations.possible_air_attack(land, to) then
				return true
			end
		end
	end
	return false
end

function is_capital(province)
	for k, v in pairs(game_data.lands) do
		if not v.defeated and v.capital == province then
			return true
		end
	end
	return false
end

function clear_data_about(land)
	if game_data.new_offers then
		for i = #game_data.new_offers, 1, -1 do
			if game_data.new_offers[i][3] == land or game_data.new_offers[i][4] == land then
				table.remove(game_data.new_offers, i)
			end
		end
	end
	if game_data.lands[land].allies then
		for i = #game_data.lands[land].allies, 1, -1 do
			remove_from_table(land, game_data.lands[game_data.lands[land].allies[i]].allies)
			table.remove(game_data.lands[land].allies, i)
		end
	end
	if game_data.lands[land].enemies then
		for i = #game_data.lands[land].enemies, 1, -1 do
			remove_from_table(land, game_data.lands[game_data.lands[land].enemies[i]].enemies)
			table.remove(game_data.lands[land].enemies, i)
		end
	end
	if game_data.lands[land].pacts then
		for i = #game_data.lands[land].pacts, 1, -1 do
			remove_from_table(land, game_data.lands[game_data.lands[land].pacts[i]].pacts)
			table.remove(game_data.lands[land].pacts, i)
		end
	end
	if game_data.pacts_data then
		for i = #game_data.pacts_data, 1, -1 do
			if game_data.pacts_data[i][1] == land or game_data.pacts_data[i][2] == land then
				table.remove(game_data.pacts_data, i)
			end
		end
	end
	for k, v in pairs(game_data.lands) do
		if v.vassal == land then
			game_data.lands[k].vassal = nil
		end
	end
	game_data.lands[land].vassal = nil
	for k, v in pairs(game_data.provinces) do
		if v.a and v.a[land] then
			v.a[land] = 0
		end
	end
end

function get_land_points(land)
	local p = 0
	for k, v in pairs(game_data.provinces) do
		-- pprint(land, k, v)
		if v.o == land then
			p = p + #v.b * 10
			p = p + v.p / 1000
		end
		for key, val in pairs(v.a) do
			if key == land then
				p = p + val/100
			end
		end
	end
	p = p + #game_data.lands[land].opened_technology * 10
	return p
end

function get_max_points_land()
	local max_land = nil
	local max_points = -1
	for k, v in pairs(game_data.lands) do
		local p = get_land_points(k)
		if p > max_points then
			max_land = k
			max_points = p
		end
	end
	return max_land, max_points
end

function get_num_of_provinces(land)
	local n = 0
	for k, v in pairs(game_data.provinces) do
		if v.o == land then
			n = n + 1
		end
	end
	return n
end

function get_stability(land)
	local w = 100 - (game_data.lands[land].war_weariness + 50)
	local r = 0
	local t = game_data.lands[land].tax * 100

	for k, v in pairs(game_data.lands[land].rebellion_support) do
		r = r + v[2]
	end

	r = r / game_data.lands[land].economy.income_total * 5

	if game_data.lands[land].economy.income_total <= 0 then
		r = 0
	elseif r > 100 then
		r = 100
	end

	local p = 0

	if lume.match(game_data.lands[land].actions_taken, function(x) return x[1] == "pay_off" end) then
		p = 10
	end

	local d = 0

	if lume.match(game_data.lands[land].actions_taken, function(x) return x[1] == "disperse" end) then
		d = 10
	end

	local e = 0

	if lume.match(game_data.lands[land].actions_taken, function(x) return x[1] == "separatism" end) then
		e = 15
	end

	local s = w + r + t

	return s / 3  - p - d - e, w/3, r/3, t/3, p, d, e
end

local table_insert = table.insert
 -- optimized find in table
local function ofit(element,t)
    for i=1,#t do
        if t[i] == element then
            return true
        end
    end
    return false
end

function get_short_path_to_enemy(province, land, enemy)
	local paths = {}
	local points = {}
	local points_mas = {}
	points[province] = 0
	table_insert(points_mas, province) 
	local d = 0 
	local enemy_province = nil
	local points_num = 0
	
	local ld = game_data.lands[land]
	
	repeat
		points_num = points_num + 1
		local k = points_mas[points_num]
		if not k then
			return nil
		end
		d = points[k]
		--print(k)
		for key_, val_ in ipairs(adjacency_map[k]) do
			local a = false
            
            local o = game_data.provinces[val_].o 

            if not game_data.provinces[val_].water then
                if o == land
                        or o == enemy
                        or ofit(o, ld.allies)
                        or ofit(o,ld.enemies)
                        or ld.vassal == o
                        or game_data.lands[o].vassal == land then
                    a = true
                end
            else
				-- potential mean that you can build port and move to this province
				if game_data.provinces[k].water or game_data.provinces[k].b.port then
					a = true
				end
			end

			if not points[val_] and a then
				points[val_] = d + 1
				table_insert(points_mas, val_)
			end
			if not enemy then
				if o == land then
					return val_
				end
			end
			if o == enemy then
				enemy_province = val_
				--goto continue_pathfinding
			end
		end
		d = d + 1
		-- ::continue_pathfinding::
	until points[enemy_province] --or points_num >= map_num_of_provinces[game_data.map]
	table_insert(paths, enemy_province)
	--pprint(points_mas, d, enemy_province)
	--pprint(points)
	if points[enemy_province] then
		local current_point = enemy_province
		repeat
			--pprint("Maps for:", current_point, adjacency_map[current_point])
			--print("current_point: ", current_point)
			for key, val in ipairs(adjacency_map[current_point]) do
				if points[val] == points[current_point] - 1 then
					table_insert(paths, val)
					current_point = val
				end
			end
			--pprint("After maps for:", current_point, adjacency_map[current_point])
		until current_point == province
	end
	--print("Short_path_to_enemy:", province,enemy)
	--pprint(paths)
	return paths
end

-- fn is function for selecting a province
function get_path_to_specific_enemy_province(province, land, enemy, fn)
    local paths = {}
    local points = {}
    local points_mas = {}
    points[province] = 0
    table_insert(points_mas, province)
    local d = 0
    local enemy_province = nil
    local enemy_provinces = {}
    local points_num = 0
    
    local ld = game_data.lands[land]
    
    repeat
        points_num = points_num + 1
        local k = points_mas[points_num]
        if not k then
            return nil
        end
        d = points[k]
        for key_, val_ in ipairs(adjacency_map[k]) do
            local a = false
            
            local o = game_data.provinces[val_].o 

            if not game_data.provinces[val_].water then
                if o == land
                        or o == enemy
                        or ofit(o, ld.allies)
                        or ofit(o,ld.enemies)
                        or ld.vassal == o
                        or game_data.lands[o].vassal == land then
                    a = true
                end
            else
                -- potential mean that you can build port and move to this province
                if game_data.provinces[k].water or game_data.provinces[k].b.port then
                    a = true
                end
            end

            if not points[val_] and a then
                points[val_] = d + 1
                table_insert(points_mas, val_)
            end
            if not enemy then
                if o == land then
                    return val_
                end
            end
            if o == enemy then
                enemy_province = val_
                table_insert(enemy_provinces, val_)
            end
        end
        d = d + 1
        if #enemy_provinces ~= 0 then
            enemy_province = fn(enemy_provinces)
        end
    until points[enemy_province]
    table_insert(paths, enemy_province)
    if points[enemy_province] then
        local current_point = enemy_province
        repeat
            for key, val in ipairs(adjacency_map[current_point]) do
                if points[val] == points[current_point] - 1 then
                    table_insert(paths, val)
                    current_point = val
                end
            end
        until current_point == province
    end
    return paths
end

function path_to_province(province, to_province)
	local paths = {}
	local points = {}
	local points_mas = {}
	points[province] = 0
	table.insert(points_mas, province) 
	local d = 0 
	local capital_province = nil
	local points_num = 0
	repeat
		points_num = points_num + 1
		local k = points_mas[points_num]
		if not k then
			return nil
		end
		d = points[k]
		--print(k)
		for key_, val_ in pairs(adjacency_map[k]) do
			local a = true

			if not points[val_] and a then
				points[val_] = d + 1
				table.insert(points_mas, val_)
			end
			if val_ == to_province then
				capital_province = val_
				--goto continue_pathfinding
			end
		end
		d = d + 1
		-- ::continue_pathfinding::
	until points[capital_province] --or points_num >= map_num_of_provinces[game_data.map]
	table.insert(paths, capital_province)
	--pprint(points_mas, d, enemy_province)
	--pprint(points)
	if points[capital_province] then
		local current_point = capital_province
		repeat
			--pprint("Maps for:", current_point, adjacency_map[current_point])
			--print("current_point: ", current_point)
			for key, val in pairs(adjacency_map[current_point]) do
				if points[val] == points[current_point] - 1 then
					table.insert(paths, val)
					current_point = val
				end
			end
			--pprint("After maps for:", current_point, adjacency_map[current_point])
		until current_point == province
	end
	--print("Short_path_to_enemy:", province,enemy)
	--pprint(paths)
	return paths
end

--Not used
--[[function available_shell(land, count, from, to)
	local err
	if not lume.match(game_data.lands[land].bonuses, function(x) return x[1] == "shell" end) then
		err = "no_technology"
	elseif game_data.lands[land].money < count * game_values.shell_cost then
		err = "no_money"
	elseif not relations.check_war(land, game_data.lands[game_data.province[to].o]) then
		err = "is_not_enemy"
	elseif count > get_army(from, land) then
		err = "not_enough_army"
	else
		return true
	end
	return false, err
end--]]

function no_enemies(land)
	local ai_utils = require "core.ai.ai_utils"
	local l = true
	for k, v in pairs(game_data.lands[land].enemies) do
		if v ~= "Undeveloped_land" and ai_utils.available_for_attack(land, v) then
			l = false
		end
	end
	return l
end

function get_province_for_land(land)
	for k, v in pairs(game_data.provinces) do
		if v.o == land then
			return k
		end
	end
	print("No provinces")
end

function show_error(title, text)
	msg.post("error_message:/error_message", "show_error", { name = title,
		text = text})
end

function set_settings(field, value)
	settings[field] = value
	local settings_path = sys.get_save_file("Cold_Path", "settings")
	sys.save(settings_path, settings)
end

function lang(key, section)
	if section then
		return langs[settings.lang][section] and langs[settings.lang][section][key] or key
	else
		return langs[settings.lang][key] or key
	end
end

function land_lang(land_id)
	-- return lang(game_data.lands[land_id] and game_data.lands[land_id].name or "error getting civilization name", "lands")
	local name = lang(game_data.lands[land_id].name, "lands")
	if game_data.lands[land_id].rebels then
		if langs[settings.lang].rebels_names then
			for k, v in pairs(langs[settings.lang].rebels_names) do
				name = name:gsub(k, v)
			end
		end
		name = name:gsub(game_data.lands[land_id].rebelled_against, land_lang(game_data.lands[land_id].rebelled_against))
	end
	return name
end

function building_name(buildings_id)
	return lang(buildings_id, "buildings_list")
end

function building_description(buildings_id, lvl)
	return lang(buildings_id.."_description", "buildings_list")
end

function validate_text(text)
	return string.find(text, "<") and string.find(text, ">") or string.find(text, "|") or not string.match(text, "%S")
end

function translate_message(text)
	local translated_message = text

	while true do
		local before_tag, tag, after_tag = translated_message:match("(.-)(|%S-|)(.*)")
		
		if not before_tag or not tag or not after_tag then
			break
		end

		local id, lang_section = tag:match("|(%S+),(%S+)|")
		if id and lang_section then
			-- print("Catched id and lang_section: ", id, lang_section)
			translated_message = before_tag..lang(id, lang_section)..after_tag
		end
	end

	return translated_message
end

-- For some reason not working in civ_menu the way I expected. The examples work
-- local function string_insert(str1, str2, pos)
--     return str1:sub(1,pos)..str2..str1:sub(pos+1)
-- end

-- local function fill_string(c, l)
-- 	-- print("fill string: ", c, l)
-- 	local str = ""
-- 	for i = 1, l do
-- 		str = str..c
-- 	end
-- 	return str
-- end

-- local function remove_char(text, l)
-- 	local str = ""
-- 	for i = 1, #text do
-- 		local c = text:sub(i,i)
-- 		if i ~= l then
-- 			str = str..c
-- 		end
-- 	end
-- 	return str
-- end

-- -- '|' for columns
-- function split_text_into_columns(text)

-- 	local column_start = 0
-- 	local counting = false
-- 	local k = 0
-- 	for i = 1, #text do
-- 		local c = text:sub(i,i)
-- 		if c == "\n" then
-- 			counting = true
-- 		end
-- 		if counting then
-- 			k = k + 1
-- 		end
-- 		if c == '|' then
-- 			if k > column_start then
-- 				column_start = k
-- 			end
-- 			counting = false
-- 			k = 0
-- 		end
-- 	end

-- 	-- print("Symbols before | is: ", column_start)
-- 	counting = false
-- 	k = 0
-- 	local text_k = 0
-- 	local i = 0
-- 	local text_size = #text
-- 	while i <= text_size do
-- 		i = i + 1
-- 		local c = text:sub(i,i)
-- 		if c == "\n" then
-- 			counting = true
-- 		end
-- 		if counting then
-- 			k = k + 1
-- 		end
-- 		text_k = text_k + 1
-- 		if c == '|' then
-- 			-- print("Now symbols before | is ", k)
-- 			text = remove_char(text, text_k)
-- 			text = string_insert(text, fill_string(' ', column_start - k), text_k - 1)
-- 			text_size = #text
-- 			counting = false
-- 			k = 0
-- 		end
-- 	end

-- 	return text
-- end

function modify_game_data(game_data_id)
	buildings_data = deepcopy(require "scripts.buildings_data")

	-- debug_log("Modify before:", buildings_data)

	local t = {
		consequences = require "scripts.scenarios_modifiers.consequences",
		lost = require "scripts.scenarios_modifiers.lost",
	}
	if t[game_data.id] and t[game_data.id].buildings_data then
		for k, v in pairs(t[game_data.id].buildings_data) do
			buildings_data[k] = lume.concat(buildings_data[k], t[game_data.id].buildings_data[k])
		end
	end

	if t[game_data.id] and t[game_data.id].init then
		t[game_data.id].init()
	end

	-- debug_log("Modify after:", buildings_data)
end

function get_temperature(land)
	local s = 0
	local n = 0
	for k, v in pairs(game_data.provinces) do
		if v.o == land then
			s = s + v.tmp
			n = n + 1
		end
	end
	if n ~= 0 then
		return s/n
	else
		return 0
	end
end

function format_temperature(n)
	if n < 0 then
		return n.."°C"
	else
		return "+"..n.."°C"
	end
end

function to_roman(num)
	local t = {
		"I", "II", "III", "IV", "V"
	}
	return t[num]
end

return M
