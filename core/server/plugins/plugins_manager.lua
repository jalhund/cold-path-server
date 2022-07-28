local M = {}

-- Standard function description:
-- chat_function(message_text, just_for_host, client)
-- kick_function(client, reason)

local plugins_list = {
	system = {
		data = require "core.server.plugins.system",
		order = 3
	},
	permissions = {
		data = require "core.server.plugins.permissions",
		order = 4
	},
	chat = {
		data = require "core.server.plugins.chat",
		order = 5
	},
	--afk = {
	--	data = require "core.server.plugins.afk",
	--	order = 6
	--},
	--verifier = {
		--data = require "core.server.plugins.verifier",
		--order = 6
	--},
	essentials = {
	 	--data = require "core.server.plugins.essentials",
	 	order = 6
	 },
	--game_switch = {
		--data = require "core.server.plugins.game_switch",
		--order = 6
	--},
	--debug = {
		--data = require "core.server.plugins.debug",
		--order = 6
	--},
}

local plugins_data = {}
local plugins_function = {}
local commands_list = {}

local function call_function(function_id, ...)
	log("plugin", "Called function: ", function_id)
	local arg = {...}
	if plugins_function[function_id] then
		local res
		local ok, err = pcall(function()
			res = plugins_function[function_id](unpack(arg))
		end)
		if err then
			log("plugin", "Error calling function: ", function_id, err)
		else
			return res
		end
	else
		log("plugin", "No function found: ", function_id)
	end
end

local function register_function(function_id, func)
	log("plugin", "Function registered: ", function_id)
	if not plugins_function[function_id] then
		plugins_function[function_id] = func
	else
		log("plugin", "Function already exists", function_id)
	end
end

local function register_command(command, func)
	log("plugin", "Command registered: ", command)
	if not commands_list[command] then
		commands_list[command] = func
	else
		log("plugin", "Command already exists: ", command)
	end
end

local function set_data(data_id, value)
	log("plugin", "Set data: ", data_id, value)
	plugins_data[data_id] = value
end

local function get_data(data_id)
	log("plugin", "Get data: ", data_id)
	return plugins_data[data_id]
end

local function remove_data(data_id)
	log("plugin", "Remove data: ", data_id)
	plugins_data[data_id] = nil
end

local function load_custom_plugins()
    local p = io.popen('find "core/server/plugins/" -type f -name "*.lua"')
    for file in p:lines() do
        local path = string.sub(file,1,-5)
        path = string.gsub(path,"/",".")
        local _, id = string.match(file, "(%S+)/(%S+).lua")
        print(path,id)
        if id ~= "plugins_manager" then
            if not plugins_list[id] then
                plugins_list[id] = {
                    order = 10,
                    data = require(path)
                }
            end
            if not plugins_list[id].data then
                plugins_list[id].data = require(path)
            end
        end
    end
end

function M.init(plugins_api)
	plugins_data = {
		HOST_IS_PLAYER = plugins_api._is_player_host,
		clients_data = plugins_api._clients_d,
		clients_ready = plugins_api._clients_ready,
		preferred_civs = plugins_api._preferred_civs,
		commands_list = commands_list
	}
	plugins_function = {
		chat_function = plugins_api._chat_function,
		kick_function = plugins_api._kick_function,
		shutdown = plugins_api._shutdown
	}
	log("plugin", "Plugins initialization started")

	local api = {
		call_function = call_function,
		register_function = register_function,
		register_command = register_command,
		set_data = set_data,
		get_data = get_data,
		remove_data = remove_data,
		parse_command = M.parse_command,
		send_data = plugins_api._send,
		set_server_state = plugins_api._set_server_state,
		start = plugins_api._start,
		next_turn = plugins_api._next,
	}

    if not plugins_data.HOST_IS_PLAYER then
        load_custom_plugins()
    end
    
	for k, v in spairs(plugins_list, function(t,a,b)
		return plugins_list[a].order < plugins_list[b].order
	end) do
		log("plugin", "  Init:", k)
		if plugins_list[k].data.init then
			plugins_list[k].data.init(api)
		end
	end
end

function M.verify_registration(client, client_data)
	local a = true
	local info = ""
	for k, v in pairs(plugins_list) do
		if plugins_list[k].data.verify_registration then
			local res, res_info = plugins_list[k].data.verify_registration(client, client_data)
			if not res then
				a = false
				info = res_info
			end
		end
	end
	return a, info
end

function M.on_player_registered(client)
	local client_data = get_data("clients_data")[client]
	log("plugin", "Player registered: ", client_data.uuid, client_data.name, client_data.civilization)
	for k, v in pairs(plugins_list) do
		if plugins_list[k].data.on_player_registered then
			plugins_list[k].data.on_player_registered(client)
		end
	end
end

function M.on_player_joined(client)
	local client_data = get_data("clients_data")[client]
	log("players", "Player joined: ", client_data.name, client_data.civilization)
	log("players", "Player data: ", client_data.uuid, client_data.unique_id, client_data.ip)
	for k, v in pairs(plugins_list) do
		if plugins_list[k].data.on_player_joined then
			plugins_list[k].data.on_player_joined(client)
		end
	end
end

function M.on_player_disconnected(client)
	local client_data = get_data("clients_data")[client]
	log("players", "Player disconnected: ", client_data.name, client_data.civilization)
	for k, v in pairs(plugins_list) do
		if plugins_list[k].data.on_player_disconnected then
			plugins_list[k].data.on_player_disconnected(client)
		end
	end
end

function M.on_data(data, ip, port, client)
	for k, v in pairs(plugins_list) do
		if plugins_list[k].data.on_data then
			plugins_list[k].data.on_data(data, ip, port, client)
		end
	end
end

function M.before_next()
	for k, v in pairs(plugins_list) do
		if plugins_list[k].data.before_next then
			plugins_list[k].data.before_next()
		end
	end
end

function M.game_over(land, win)
	for k, v in pairs(plugins_list) do
		if plugins_list[k].data.game_over then
			plugins_list[k].data.game_over(land, win)
		end
	end
end

function M.attribute_message(text, client)
	-- print("Plugins manager attrib: ", text, client)
	return plugins_function.attribute_message(text, client)
end

function M.valid_message(text, client)
	for k, v in pairs(plugins_list) do
		if plugins_list[k].data.valid_message then
			return plugins_list[k].data.valid_message(text, client)
		end
	end
	return true
end

function M.parse_command(cmd, client)
	cmd = lume.split(cmd)
	local command_found = false
	for k, v in pairs(commands_list) do
		if k == cmd[1] then
			if not client or plugins_function.check_command_permission(client, cmd[1]) then
                local client_data = get_data("clients_data")[client]
                log("players", "Player "..client_data.name.." use command: "..cmd[1].." "..(cmd[2] or "").." "..(cmd[3] or ""))
				commands_list[k](client, cmd)
			else
				plugins_function.chat_message("You do not have permission to do this", "error", true, client)
			end
			command_found = true
		end
	end
	if not command_found then
		plugins_function.chat_message("Unknown command", "error", true, client)
	end
end

function M.commands_list(client)
	local cmd_list = {}
	for k, v in pairs(commands_list) do
		table.insert(cmd_list, k)
	end
	return cmd_list
end

return M