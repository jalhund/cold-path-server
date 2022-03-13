local M = {}

function M.gold_per_turn_bonus(land)
    local i = game_data.lands[land].ideology
    if i == "trade_republic" then
        return game_values.ideology.trade_republic_gold_per_turn_bonus
    elseif i == "communism" then
        return game_values.ideology.communism_gold_per_turn_bonus
    end
    return 1
end

function M.maintenance_bonus(land)
    local i = game_data.lands[land].ideology
    if i == "trade_republic" then
        return game_values.ideology.trade_republic_maintenance_bonus
    end
    return 1
end

function M.population_increase_bonus(land)
    local i = game_data.lands[land].ideology
    if i == "democracy" then
        return game_values.ideology.democracy_population_increase_bonus
    end
    return 1
end

function M.science_per_turn_bonus(land)
    local i = game_data.lands[land].ideology
    if i == "democracy" then
        return game_values.ideology.democracy_science_increase_bonus
    elseif i == "monarchy" then
        return game_values.ideology.monarchy_science_increase_bonus
    end
    return 1
end

local function available_for_attack(from, to)
	local a = false
	for k, v in pairs(game_data.provinces) do
		if not v.water and v.o == from then
			if get_short_path_to_enemy(k, from, to) then
				a = true
			end
		end
	end
	return a
end

function M.get_war_weariness_bonus(land)
    if game_data.lands[land].ideology == "anarchism" then
        return game_values.ideology.anarchism_war_weariness_mod
    end
    for k, v in pairs(game_data.lands[land].enemies) do
        if game_data.lands[v].ideology == "anarchism" and available_for_attack(land, v) then
            return game_values.ideology.anarchism_war_weariness_mod
        end
    end
    return 1
end

function M.get_inflation_bonus(land)
    local i = game_data.lands[land].ideology
    if i == "anarchism" then
        return game_values.ideology.anarchism_inflation_mod
    end
    return 1
end

function M.army_attack_bonus(land, to_land)
    local i = game_data.lands[land].ideology
    if i == "democracy" then
        return game_values.ideology.democracy_attack_bonus
    elseif i == "fascism" then
        if game_data.lands[land].declared_war then
            if game_data.step - game_data.lands[land].declared_war <=
                    game_values.ideology.fascism_attack_bonus_duration then
                return game_values.ideology.fascism_attack_bonus_after_declaring_war
            else
                return game_values.ideology.fascism_attack_debuff
            end
        end
    elseif i == "anarchism" and to_land and get_num_of_provinces(to_land) > get_num_of_provinces(land) then
        local k = math.floor(get_num_of_provinces(to_land)/10)
        
        return math.pow(game_values.ideology.anarchism_attack_bonus, k)
    end
    return 1
end

function M.army_defense_bonus(land)
    local i = game_data.lands[land].ideology
    if i == "monarchy" then
        local b = false
        for k, v in pairs(game_data.lands[land].enemies) do
            if get_land_points(v) > get_land_points(land) then
                b = true
            end
        end
        if b then
            return game_values.ideology.monarchy_defense_bonus_if_enemy_has_more_army
        end
    end
    return 1
end

function M.recruit_cost_bonus(land)
    local i = game_data.lands[land].ideology
    if i == "theocracy" then
        return game_values.ideology.theocracy_recruit_cost_bonus
    end
    return 1
end

function M.available_revolt(land)
    local i = game_data.lands[land].ideology
    return i ~= "theocracy"
end

function M.is_attack_bonus_without_capital(land)
    local i = game_data.lands[land].ideology
    return i ~= "anarchism" 
end

function M.handle_defeat(game_end_callback)
    for k, v in pairs(game_data.lands) do
        if k ~= "Undeveloped_land" and not v.defeated and v.ideology == "theocracy" and v.capital and game_data.provinces[v.capital].o ~= k then
            for key, val in pairs(game_data.provinces) do
                if not val.water and val.o == k then
                    val.o = "Undeveloped_land"
                end
            end
            -- game_data.lands.Undeveloped_land.defeated = nil
            -- clear_data_about(k)
            -- game_end_callback(k)
        end
    end
end

local function get_land_army_in_provinces(land)
    local n = 0
    for k, v in pairs(game_data.provinces) do
        if not v.water and v.o == land then
            n = n + army_functions.get_army(k)
        end
    end
    return n
end

function M.scatter_damage(from, to, amount, land, damage_bonus)
    local defending_land = game_data.provinces[to].o

    local provinces_army = {}
    --print("Total damage: ", amount)
    amount = math.floor(amount * (1 - game_values.ideology.communism_damage_to_ignore))
    --print("Ignore 25%: ", amount)

    for k, v in pairs(game_data.provinces) do
        if not v.water and v.o == defending_land and army_functions.get_army(k) > 0 then
            provinces_army[k] = army_functions.get_army(k, defending_land)
        end
    end

    local total_army = get_land_army_in_provinces(defending_land)
    --print("Total army: ", total_army)

    local distribution = {}
    for k, v in pairs(provinces_army) do
        distribution[k] = v/total_army
    end

    local damage_to_all_provinces = math.floor(amount * game_values.ideology.communism_damage_to_all_provinces)
    --print("Damage to all provinces: ", damage_to_all_provinces)
    if damage_to_all_provinces * damage_bonus > total_army then
        damage_to_all_provinces = total_army / damage_bonus
    end
    --print("Damage to all provinces after check: ", damage_to_all_provinces)
    local damage_to_main_province = amount - damage_to_all_provinces

    --pprint("Scatter damage: ", from, to, amount, land, damage, damage_bonus)
    --pprint("Info: ", provinces_army, distribution)

    for k, v in pairs(distribution) do
        local cur_damage = math.floor(v * damage_to_all_provinces)
        for key, val in pairs(game_data.provinces[k].a) do
            army_functions.set_army(k, math.floor(val - cur_damage * damage_bonus), key)
        end
        -- 	vilnius	20.571428571429	72	20.285714285714	1.0140845070423
        --print("Damage province for: ", k, cur_damage, cur_damage * damage_bonus, damage_to_all_provinces, v)
    end
    --print("Damage main province: ", damage_to_main_province)
    for k, v in pairs(game_data.provinces[to].a) do
        local damage = damage_to_main_province
        if damage * damage_bonus > v then
            damage = v/damage_bonus
        end
        damage_to_main_province = math.floor(damage_to_main_province - damage)
        army_functions.set_army(to, math.floor(v - damage * damage_bonus), k)
    end

    return damage_to_main_province
end

return M