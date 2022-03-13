--System plugin: kick/players functions

local M = {}

local civilization_reset_cooldown = 30

local api

local function help(client, args)
	local cmd_list = {}
	for k, v in pairs(api.get_data("commands_list")) do
		table.insert(cmd_list, k)
	end
	local cmd_list_text = join(cmd_list, "\n  ", 1)
	api.call_function("chat_message", "Server commands: \n  "..cmd_list_text, "system", true)
end

local function kick(client, args)
	local cl = api.call_function("get_client_by_name", args[2])
	local reason = join(args, " ", 3)
	if reason == "" then
		reason = "Unknown reason"
	end
	if cl then
		api.call_function("kick_function", cl, reason)
		api.call_function("chat_message", args[2].." kicked by host for a reason: "..reason, "system")
	else
		api.call_function("chat_message", "Unknown name", "error", true, client)
	end
end

local function players_list(client, args)
	api.call_function("chat_message", "Players: ", "system", true, client)
	for k, v in pairs(api.get_data("clients_data")) do
		if v.state == "in_game" then
			api.call_function("chat_message", "  "..v.name..
				(api.get_data("clients_ready") and api.get_data("clients_ready")[k] and " - ready" or ""), "system", true, client)
		end
	end
end

local function private_message(client, args)
	local player = args[2]
	local message_text = join(args, " ", 3)
	local cl = api.call_function("get_client_by_name", player)
	if cl or api.get_data("HOST_IS_PLAYER") and player == settings.name then
		local attributed_message = api.call_function("attribute_message",message_text, client)
		api.call_function("chat_function", "<color=1.0,0.8,0.2,1>[PM]</color>"..attributed_message, true, client)
		api.call_function("chat_function", "<color=1.0,0.8,0.2,1>[PM]</color>"..attributed_message, true, cl)
	else
		api.call_function("chat_message", "Unknown name", "error", true, client)
	end
end

local reset_time = {}

local function reset_civilization(client)
	if client then
		local client_uuid = api.get_data("clients_data")[client].uuid
		local t = api.get_data("preferred_civs")
		local l = socket.gettime() - (reset_time[client_uuid] or 0) - civilization_reset_cooldown
		if l < 0 then
			api.call_function("chat_message", "You cannot reset countries as often. Please wait "..
					(math.floor(l) * -1).." seconds ", "error", true, client)
			return
		end
		if t[client_uuid] then
			t[client_uuid] = nil
			reset_time[client_uuid] = socket.gettime()
			api.call_function("kick_function", client, "You are untied from your country. Join server and you will be given a random country from the list")
		else
			api.call_function("chat_message", "You are not tied to any country", "system", true, client)
		end
	else
		api.call_function("chat_message", "You are the host, you cannot change the country", "system", true)
	end
end

local function set_color(client, args)
	if client then
		local r, g, b = tonumber(args[2]), tonumber(args[3]), tonumber(args[4])
		if r and r >= 0 and r < 256 and g and g >= 0 and g < 256 and b and b >= 0 and b < 256 then
			if r < 20 and g < 20 and b < 20 then
				api.call_function("chat_message", "Can't set black (x, y and z < 20)", "system", true, client)
			else
				api.call_function("chat_message", "Color changed successfully", "system", true, client)
				game_data.lands[api.get_data("clients_data")[client].civilization].color = {r, g, b}
			end
		else
			api.call_function("chat_message", "Wrong format. Example: /setcolor 255 0 0", "system", true, client)
		end
	else
		api.call_function("chat_message", "You are the host, you cannot change the color", "system", true, client)
	end
end

local selected_provinces = {}

local function select(client, args)
	if client and args[2] then
		local client_uuid = api.get_data("clients_data")[client].uuid
		if game_data.custom_map then
		    args[2] = tonumber(args[2])
		end
		selected_provinces[client_uuid] = args[2]
		api.call_function("chat_message", "Selected!", "system", true, client)
	elseif not client and api.get_data("HOST_IS_PLAYER") then
		selected_provinces[settings.uuid] = selected_province
		api.call_function("chat_message", "Selected!", "system", true, client)
	end
end

local function set_civ(client, args)
	local cl = api.call_function("get_client_by_name", args[2])
	if cl then
		local client_uuid = api.get_data("clients_data")[client] and api.get_data("clients_data")[client].uuid
		local cl_uuid = api.get_data("clients_data")[cl].uuid

		local province = selected_provinces[client_uuid] or api.get_data("HOST_IS_PLAYER") and selected_provinces[settings.uuid]

		if province and game_data.provinces[province] then
			local t = api.get_data("preferred_civs")
			t[cl_uuid] = game_data.provinces[province].o
			api.call_function("chat_message", "Done!", "system", true, client)
		else
			api.call_function("chat_message", "Wrong province. Try type /select before using", "error", true, client)
		end
	else
		api.call_function("chat_message", "Wrong name", "error", true, client)
	end
end

local function get_client_by_name(name)
	local c = 0
	local cl
	for k, v in pairs(api.get_data("clients_data")) do
		if v.name and name then
			-- print("Check: ", v.name, name, string.find(v.name, name))
			if v.name == name and v.state == "in_game" then
				return k
			elseif string.find(v.name, name) == 1  and v.state == "in_game" then
				c = c + 1
				cl = k
			end
		end
	end

	if c == 1 then
		return cl
	end

	return false
end

function M.init(_api)
	api = _api
	reset_time = {}

	api.register_command("/help", help)
	api.register_command("/kick", kick)
	api.register_function("kick", kick)
	api.register_command("/players", players_list)
	api.register_command("/m", private_message)
	api.register_command("/rc", reset_civilization)
	api.register_command("/setcolor", set_color)
	api.register_command("/select", select)
	api.register_command("/setciv", set_civ)
	api.register_function("get_client_by_name", get_client_by_name)
end

return M