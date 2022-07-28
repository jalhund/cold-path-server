--Chat plugin
local M = {}

local api

local chat_message = function(text,type, just_for_host, client)
	local c = "white"
	if type == "error" then
		c = "red"
	elseif type == "system" then
		c = "grey"
	end
	-- print("Chat_message: ", text, type, just_for_host, client)
	api.call_function("chat_function", "<color="..c..">"..text.."</color>", just_for_host, client)
end

local HOST_IS_PLAYER = true

local function attribute_message(text,client)
	print("Attribute message is :", text, client)

	local client_civ = HOST_IS_PLAYER and game_data.player_land or ""
	local client_name = HOST_IS_PLAYER and settings.name or ""
    local custom_id = ""
	if client then
		client_civ = api.get_data("clients_data")[client].civilization
		client_name = api.get_data("clients_data")[client].name
        local cl_data = api.get_data("clients_data")[client]
        if cl_data.id then
            custom_id = "["..cl_data.id.."]"
        end
	end
	local c = game_data.lands[client_civ].color
	local res = "<color="..lume.round(c[1]/255, .01)..","..lume.round(c[2]/255, .01)..","..lume.round(c[3]/255, .01)..
	",1>|"..game_data.lands[client_civ].name..",lands|["..client_name.."]</color>"..custom_id..": "..text
	return res
end

function M.init(_api)
	api = _api
	api.register_function("chat_message", chat_message)
	api.register_function("attribute_message", attribute_message)
	HOST_IS_PLAYER = api.get_data("HOST_IS_PLAYER")
end

function M.on_player_registered(client)
	local cl_data = api.get_data("clients_data")[client]
	if cl_data then
		api.call_function("chat_message", api.get_data("clients_data")[client].name..
			" joined server(|"..game_data.lands[cl_data.civilization].name..",lands|)")
	end
end

function M.on_player_disconnected(client)
	api.call_function("chat_message", api.get_data("clients_data")[client].name.." leave server")
end

return M