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


function M.build(land, budget)
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
            end
        elseif v.id == "mine" then
            buildings.economy.location[v.id] = "gold"
        end
    end

    for k, v in pairs(buildings_data.science) do
        buildings.science.priority[v.id] = 1
        buildings.science.location[v.id] = "safe"
    end

    for k, v in pairs(buildings_data.defense) do
        buildings.defense.priority[v.id] = 1
        buildings.defense.location[v.id] = "safe"
        if v.id == "tower" or v.id == "fortress" or v.id == "bridgehead" or v.id == "hospital" then
            buildings.defense.priority[v.id] = 2
            buildings.defense.location[v.id] = "danger"
        elseif v.id == "beacon" then
            buildings.defense.priority[v.id] = 2
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
            buildings.other.priority[v.id] = 1
            buildings.other.location[v.id] = "coast"
        elseif v.id == "nuclear_reactor" then
            if game_data.lands[land].resources.heavy_water == 0 then
                buildings.other.priority[v.id] = 0
            end
        end
    end

    for k, v in pairs(buildings_data) do
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
                core.build(land, province, building)
            end
            if #game_data.provinces[province].b > province_buildings_limit(province) then
                local building_for_destroy = lume.weightedchoice(game_data.provinces[province].b)
                core.destroy(land, province, building_for_destroy)
            end
        end

    end
end

return M