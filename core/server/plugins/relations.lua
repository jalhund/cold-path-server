-- relations - plugin for RP server
local M = {}

local relations = require "core.relations"

local api

local tracked_provinces = {}
local admin_selection = {}
local enabled_tracking = {} -- who write /track

local function set_prov1(client, args)
    if not tracked_provinces[client] then
        api.call_function("chat_message", "No tracked province. Try to click province before", "error", true, client)
    end
    if not admin_selection[client] then
        admin_selection[client] = {}
    end
    admin_selection[client].prov1 = tracked_provinces[client]
    api.call_function("chat_message", "Prov1: "..admin_selection[client].prov1, "system", true, client)
end

local function set_prov2(client, args)
    if not tracked_provinces[client] then
        api.call_function("chat_message", "No tracked province. Try to click province before", "error", true, client)
    end
    if not admin_selection[client] then
        admin_selection[client] = {}
    end
    admin_selection[client].prov2 = tracked_provinces[client]
    api.call_function("chat_message", "Prov2: "..admin_selection[client].prov2, "system", true, client)
end

local function register_peace(client, args)
    if not admin_selection[client] then
        api.call_function("chat_message", "Choose provinces using /p1 and /p2", "error", true, client)
        return
    end
    local province_1 = admin_selection[client].prov1
    local province_2 = admin_selection[client].prov2
    local civ_1 = game_data.provinces[province_1].o
    local civ_2 = game_data.provinces[province_2].o
    if not civ_1 then
        api.call_function("chat_message", "Wrong province! There is no owner (province_1)", "error", true, client)
        return
    end
    if not civ_2 then
        api.call_function("chat_message", "Wrong province! There is no owner (province_2)", "error", true, client)
        return
    end
    if relations.available_peace(civ_1, civ_2) then
        relations.register_peace(civ_1, civ_2)
        api.call_function("chat_message", "Successfully peace!", "success", true, client)
    else
        api.call_function("chat_message", "Error! Impossible to make peace. Civilizations: "..civ_1.." "..civ_2, "error", true, client)
    end
end

local function nopact(client, args)
    if not admin_selection[client] then
        api.call_function("chat_message", "Choose provinces using /p1 and /p2", "error", true, client)
        return
    end
    local province_1 = admin_selection[client].prov1
    local province_2 = admin_selection[client].prov2
    local civ_1 = game_data.provinces[province_1].o
    local civ_2 = game_data.provinces[province_2].o
    if not civ_1 then
        api.call_function("chat_message", "Wrong province! There is no owner (province_1)", "error", true, client)
        return
    end
    if not civ_2 then
        api.call_function("chat_message", "Wrong province! There is no owner (province_2)", "error", true, client)
        return
    end
    if relations.check_pact(civ_1, civ_2) then
        for k, v in pairs(game_data.pacts_data) do
            if v[1] == civ_1 and v[2] == civ_2 or v[1] == civ_2 and v[2] == civ_1 then
                game_data.pacts_data[k] = nil
                remove_from_table(civ_2, game_data.lands[civ_1].pacts)
                remove_from_table(civ_1, game_data.lands[civ_2].pacts)
                api.call_function("chat_message", "Successfully removing pact!", "success", true, client)
                break
            end
        end
    else
        api.call_function("chat_message", "Error! Impossible to remove pact. Civilizations: "..civ_1.." "..civ_2, "error", true, client)
    end
end

local function owner(client, args)
    if not admin_selection[client] then
        api.call_function("chat_message", "Choose provinces using /p1 and /p2", "error", true, client)
        return
    end
    local province_1 = admin_selection[client].prov1
    local province_2 = admin_selection[client].prov2
    local civ_1 = game_data.provinces[province_1].o
    local civ_2 = game_data.provinces[province_2].o
    if not civ_1 then
        api.call_function("chat_message", "Wrong province! There is no owner (province_1)", "error", true, client)
        return
    end
    if not civ_2 then
        api.call_function("chat_message", "Wrong province! There is no owner (province_2)", "error", true, client)
        return
    end
    if not game_data.provinces[province_2].water then
        game_data.provinces[province_2].o = civ_1
    else
        api.call_function("chat_message", "Error! This is water", "error", true, client)
    end
end

local function track(client, args)
    enabled_tracking[client] = not enabled_tracking[client]
    api.call_function("chat_message", "Set tracking: "..(enabled_tracking[client] and "true" or "false"), "system", true, client)
end


local function reciv(client, args)
    local cl = api.call_function("get_client_by_name", args[2])
    if cl then
        local client_uuid = api.get_data("clients_data")[client] and api.get_data("clients_data")[client].uuid
        local cl_uuid = api.get_data("clients_data")[cl].uuid

        local province = tracked_provinces[client]

        if province and game_data.provinces[province] then
            local t = api.get_data("preferred_civs")
            t[cl_uuid] = game_data.provinces[province].o
            api.call_function("chat_message", "Done!", "system", true, client)
        else
            api.call_function("chat_message", "Wrong province. Try to use /track to find error", "error", true, client)
        end
    else
        api.call_function("chat_message", "Wrong name", "error", true, client)
    end
end

function M.init(_api)
    api = _api

    tracked_provinces = {}
    admin_selection = {}
    enabled_tracking = {}

    api.register_command("/track", track)
    api.register_command("/p1", set_prov1)
    api.register_command("/p2", set_prov2)
    api.register_command("/peace", register_peace)
    api.register_command("/nopact", nopact)
    api.register_command("/ow", owner)
    api.register_command("/reciv", reciv)
end

function M.on_player_joined(client)
    local t = {
        type = "enable_selected_province_tracking",
        data = {}
    }
    api.send_data(to_json(t), client)
end

function M.on_data(data, ip, port, client)
    -- Detailed info for admins
    if data.type == "tracked_province" then
        if enabled_tracking[client] then
            local text = "Selected province: "..data.data.province
            if not admin_selection[client] then
                admin_selection[client] = {}
            end
            local prov1 = admin_selection[client].prov1
            local prov2 = admin_selection[client].prov2
            if admin_selection[client].prov1 then
                text = text.."  /p1: "..prov1.." | "..(game_data.provinces[prov1].o or "water")
            end
            if admin_selection[client].prov2 then
                text = text.."  /p2: "..prov2.." | "..(game_data.provinces[prov2].o or "water")
            end
            local t = {
                type = "server_text",
                data = {
                    text = text
                }
            }
            api.send_data(to_json(t), client)
        end
        tracked_provinces[client] = data.data.province
    end
end

return M
