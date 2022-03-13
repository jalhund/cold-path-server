local M = {}

local ai_data = require "core.ai.ai_data"
local core = require "core.core"
local army_functions = require "core.army_functions"
local ai_utils = require "core.ai.ai_utils"

M.recruit_cost_modifier = 0.15
M.maintenance_cost_modifier = 0.15
M.discontent_pay_off = 30
M.discontent_disperse = 35
M.discontent_independence = 40

-- impossible difficulty: attack provinces with smaller armies
local function select_target_province(list)
    local t = {}
    local max_army = 0
    for k, v in pairs(list) do
        local damage_bonus = 1/army_functions.calc_provincial_defense(v)
        t[v] = army_functions.get_army(v) / damage_bonus + 1
        if t[v] > max_army then
            max_army = t[v]
        end
    end
    -- reverse
    for k, v in pairs(list) do
        t[v] = max_army - t[v] + 1

        -- Quick fix. In fact, we need to find a place where the army goes into negative value, but this is difficult. TODO
        if t[v] < 0 then
            t[v] = 0
        end
    end
    return lume.weightedchoice(t)
end

function M.move_army(land)
    local t = {}
    for k, v in pairs(game_data.lands[land].enemies) do
        t[v] = ai_utils.available_for_attack(land, v)
    end

    for key, val in pairs(game_data.lands[land].enemies) do
        if t[val] and val ~= "Undeveloped_land" or (lume.random() < ai_data.chance_conquer_undeveloped_land
                and is_neighbour(land, val)) then
            for k, v in pairs(game_data.provinces) do
                local a = army_functions.get_army(k, land)

                if a > 0 then
                    local path = get_path_to_specific_enemy_province(k, land, val, select_target_province)
                    if path and path[#path - 1] then
                        local amount = math.floor(a * lume.random(ai_data.min_move_army_percent, ai_data.max_move_army_percent))
                        if amount > 0 then
                            a = a - amount
                            core.move(land, k, path[#path-1], amount)
                        end
                    end
                end
            end
        end
    end
end

return M