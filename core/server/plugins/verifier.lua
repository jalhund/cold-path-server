-- verifier - plugin for license verification
local M = {}

local server_settings = require "server_settings"

local https = {
	request = function()
	end
}

if server_settings.verify_uuid then
	https = require "scripts.utils.https"
end

local api

local verification_mode = "kick" -- ignore, log, kick

local verification_server_ip
local verification_server_port

local pass_data = {}

local function pass(client, args)
	local player = args[2]
	if player then
		local prev_player = pass_data[api.get_data("clients_data")[client].uuid]
		local prev_client = api.call_function("get_client_by_name", prev_player)
		if prev_client then
			api.call_function("kick_function", prev_client, "Premium player allowed another player to join")
		end
		if client and api.get_data("clients_data")[client] and api.get_data("clients_data")[client].uuid then
			pass_data[api.get_data("clients_data")[client].uuid] = player
		end
		api.call_function("chat_message", "You have allowed player "..player.." to join the server", "system", true, client)
	end
end

function M.init(_api)
	pass_data = {}
	local file = io.open("verification_server", "r")
	if file then
		local s = file:read("*a")
		local ip, port = s:match("(%S+):(%S+)")
		if ip and port then
			verification_server_ip = ip
			verification_server_port = tonumber(port)
		end
		file:close()
	end
	api = _api
	api.register_command("/pass", pass)
	if api.get_data("HOST_IS_PLAYER") then
		verification_mode = "ignore"
	end
end

function M.verify_registration(client, client_data)
	local license = true
	pprint("Verify client data:", client_data)
	if client_data.device == "Android" then
		-- pprint("Client login data:", client_data.login_data)
		if client_data.login_data and client_data.login_data.package_name then
			local url = "https://"..verification_server_ip..":"..verification_server_port.."/verify/"..client_data.uuid.."/v".."/v"
			local body, code, headers, status = https.request(url)
			if status and code == 400 then
				license = false
			end
			if status and code == 201 then
				client_data.premium = true
				api.call_function("set_permissions_group", client, "premium")
			end
			if client_data.login_data.package_name ~= "com.DenisMakhortov.ColdPath" or not client_data.login_data.installed_from_market then
				-- license = false
			end
		else
			license = false
		end
	elseif client_data.device == "Windows" then
		license = true
	end
	if lume.match(pass_data, function(x) return x == client_data.name end) then
		license = true
	end

	if verification_mode == "ignore" then
		return true
	elseif verification_mode == "log" then
		if not license then
			api.call_function("chat_message", "Player "..client_data.name.." joined from the unofficial version of the game", "system")
		end
		return true
	elseif verification_mode == "kick" then
		return license
	end
end

return M