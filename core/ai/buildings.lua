local M = {}

local ai_utils = require "core.ai.ai_utils"
local core = require "core.core"

local function water_is_near(province)
    for k, v in pairs(get_list_adjacency_map(province)) do
        if game_data.provinces[v].water then
            return true
        end
    end
    return false
end

local function safe_provinces(land)
    local provinces_priority = ai_utils.get_provinces_priority(land)
    local t = {}
    for k, v in pairs(provinces_priority) do
        if v == 1 then
            table.insert(t, k)
        end
    end
    return t
end

local function neutral_provinces(land)
    local provinces_priority = ai_utils.get_provinces_priority(land)
    local t = {}
    for k, v in pairs(provinces_priority) do
        if v == 1 or v == 2 then
            table.insert(t, k)
        end
    end
    return t
end

local function danger_provinces(land)
    local provinces_priority = ai_utils.get_provinces_priority(land)
    local t = {}
    for k, v in pairs(provinces_priority) do
        if v == 3 or v == 2 then
            table.insert(t, k)
        end
    end
    if #t == 0 then
        for k, v in pairs(provinces_priority) do
            if v == 1 then
                table.insert(t, k)
            end
        end
    end
    return t
end

local function coast_provinces(land)
    local t = {}
    for k, v in pairs(game_data.provinces) do
        if not v.water and v.o == land and water_is_near(k) then
            table.insert(t, k)
        end
    end
    return t
end

local function gold_provinces(land)
    local t = {}
    for k, v in pairs(game_data.provinces) do
        if not v.water and v.o == land and (v.r.gold and v.r.gold.count > 0 and available_resource(land, v.r.gold)
                or v.r.uranium and v.r.uranium.count > 0 and available_resource(land, v.r.uranium)) then
            table.insert(t, k)
        end
    end
    return t
end

local function land_has_building(land, building)
    for k, v in pairs(game_data.provinces) do
        if not v.water and v.o == land and v.b[building] then
            return true
        end
    end
    return false
end

local function build_technocracy_robot_factory_if_needed(land)
    if game_data.lands[land].ideology ~= "technocracy" then
        return false
    end

    local at_war = lume.count(game_data.lands[land].enemies, function(x) return x ~= "Undeveloped_land" end) > 0
    if not at_war and land_has_building(land, "robot_factory") then
        return false
    end

    local cost = get_building_cost(land, "robot_factory")
    if game_data.lands[land].money < cost then
        return false
    end

    local provinces = safe_provinces(land)
    if #provinces == 0 then
        provinces = neutral_provinces(land)
    end

    for k, province in pairs(provinces) do
        if available_building(land, province, "robot_factory") then
            core.build(land, province, "robot_factory")
            return true
        end
    end

    return false
end


-- Optimized building strategy based on actual needs
local function should_prioritize_economy(land)
    -- Prioritize economy if we're struggling financially
    if not game_data.lands[land] or not game_data.lands[land].economy then
        return false
    end
    
    local income = game_data.lands[land].economy.balance
    local army_cost = game_data.lands[land].army * game_values.army_cost
    
    -- If army maintenance is eating > 60% of income
    if income > 0 and army_cost > income * 0.6 then
        return true
    end
    
    -- If we're in debt
    if game_data.lands[land].money < 0 then
        return true
    end
    
    return false
end

local function should_prioritize_science(land)
    -- Check if we're falling behind in technology
    if not game_data.lands[land] or not game_data.lands[land].technology then
        return false
    end
    
    local our_tech_count = 0
    for k, v in pairs(game_data.lands[land].technology) do
        if v then our_tech_count = our_tech_count + 1 end
    end
    
    -- Compare to average
    local total_tech = 0
    local land_count = 0
    for k, v in pairs(game_data.lands) do
        if k ~= "Undeveloped_land" and not v.defeated and v.technology then
            for key, val in pairs(v.technology) do
                if val then total_tech = total_tech + 1 end
            end
            land_count = land_count + 1
        end
    end
    
    local avg_tech = land_count > 0 and (total_tech / land_count) or 0
    return our_tech_count < avg_tech * 0.8  -- Behind by 20%
end

function M.build(land, budget)
    build_technocracy_robot_factory_if_needed(land)

    local buildings = {
        economy = {
            priority = {},
            location = {}
        },
        science = {
            priority = {},
            location = {}
        },
        defense = {
            priority = {},
            location = {}
        },
        other = {
            priority = {},
            location = {}
        }
    }

    for k, v in pairs(buildings_data.economy) do
        buildings.economy.priority[v.id] = 1
        buildings.economy.location[v.id] = "safe"
        if v.id == "mint" then
            if game_data.lands[land].resources.gold == 0 then
                buildings.economy.priority[v.id] = 0
            else
                -- Prioritize mint if we have gold
                buildings.economy.priority[v.id] = 3
            end
        elseif v.id == "mine" then
            buildings.economy.location[v.id] = "gold"
            -- Mines are high priority on gold/uranium
            buildings.economy.priority[v.id] = 2
        end
        
        -- Boost economy priority if struggling
        if should_prioritize_economy(land) then
            buildings.economy.priority[v.id] = (buildings.economy.priority[v.id] or 1) * 2
        end
    end

    for k, v in pairs(buildings_data.science) do
        buildings.science.priority[v.id] = 1
        buildings.science.location[v.id] = "safe"
        
        -- Boost science if falling behind
        if should_prioritize_science(land) then
            buildings.science.priority[v.id] = 3
        end
    end

    for k, v in pairs(buildings_data.defense) do
        buildings.defense.priority[v.id] = 1
        buildings.defense.location[v.id] = "safe"
        if v.id == "robot_factory" or v.id == "drone_factory" then
            -- Only Technocracy can build these; for it the robot factory is the main army source.
            if game_data.lands[land].ideology == "technocracy" then
                buildings.defense.priority[v.id] = (v.id == "robot_factory") and 5 or 2
                buildings.defense.location[v.id] = (v.id == "robot_factory") and "safe" or "danger"
            else
                buildings.defense.priority[v.id] = 0
            end
        elseif v.id == "tower" or v.id == "fortress" or v.id == "bridgehead" or v.id == "hospital" then
            buildings.defense.priority[v.id] = 2
            buildings.defense.location[v.id] = "danger"
        elseif v.id == "beacon" then
            -- Only build beacons if we have coast
            local has_coast = #coast_provinces(land) > 0
            buildings.defense.priority[v.id] = has_coast and 2 or 0
            buildings.defense.location[v.id] = "coast"
        elseif v.id == "air_defense" then
            buildings.defense.priority[v.id] = 2
            buildings.defense.location[v.id] = "neutral"
        end
    end

    for k, v in pairs(buildings_data.other) do
        buildings.other.priority[v.id] = 1
        buildings.other.location[v.id] = "safe"
        if v.id == "port" then
            -- Only build ports if we have coast
            local has_coast = #coast_provinces(land) > 0
            buildings.other.priority[v.id] = has_coast and 1 or 0
            buildings.other.location[v.id] = "coast"
        elseif v.id == "nuclear_reactor" then
            if game_data.lands[land].resources.heavy_water == 0 then
                buildings.other.priority[v.id] = 0
            end
        elseif v.id == "aerodrome" then
            -- Prioritize aerodromes if we have enemies
            if #game_data.lands[land].enemies > 1 then
                buildings.other.priority[v.id] = 2
            end
        end
    end

    for k, v in pairs(buildings_data) do
        -- Skip categories without an AI build profile / budget (e.g. espionage,
        -- which the AI manages through its dedicated espionage logic).
        if buildings[k] and budget[k.."_buildings"] then
        local b = game_data.lands[land].money * budget[k.."_buildings"]
        -- print("Budget for: ", land, k, b)
        local building = lume.weightedchoice(buildings[k].priority)
        -- print("selected building:", building)

        local provinces = {}
        if buildings[k].location[building] == "safe" then
            provinces = safe_provinces(land)
        elseif buildings[k].location[building] == "neutral" then
            provinces = neutral_provinces(land)
        elseif buildings[k].location[building] == "danger" then
            provinces = danger_provinces(land)
        elseif buildings[k].location[building] == "coast" then
            provinces = coast_provinces(land)
        elseif buildings[k].location[building] == "gold" then
            provinces = gold_provinces(land)
        end
        -- pprint("Provinces list:", provinces)

        local province = #provinces ~= 0 and lume.randomchoice(provinces)
        if #provinces ~= 0 and
                (not game_data.provinces[province].b[building] or game_data.provinces[province].b[building] <
                        #get_building_data(building).lvl) and get_building_cost(land, building, game_data.provinces[province].b[building]) < b then
            -- print("Selected province:", land, province, building)
            if available_building(land, province, building) then
                -- pprint("Debug building", land, province, building)
                if game_data.provinces[province].b.mine == 4 and game_data.provinces[province].r.gold then
                    -- print("[AI] Ignore mine lvl 5 for gold")
                else
                    core.build(land, province, building)
                end
            end
            if #game_data.provinces[province].b > province_buildings_limit(province) then
                local building_for_destroy = lume.weightedchoice(game_data.provinces[province].b)
                core.destroy(land, province, building_for_destroy)
            end
        end
        end

    end
end

return M
