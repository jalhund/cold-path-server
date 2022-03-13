-- Essentials - standard console server plugin
local M = {}

local server_settings = require "server_settings"

local api

local admins_file_path = "admins.dat"
local banned_file_path = "banned.dat"
local banned_ip_file_path = "banned_ip.dat"

local muted = {}

local function clear_old_records(file_path)
	local t = {}
	for line in io.lines(file_path) do
		local b = lume.split(line)
		t[b[1]] = b
	end
	local file = io.open(file_path, "w")
	if file then
		for k, v in pairs(t) do
			if tonumber(v[2]) > socket.gettime() then
				file:write(k.." "..join(v, " ", 2).."\n")
			end
		end
		file:close()
	end
end

local function check_ban(uuid, ip, unique_id)
	clear_old_records(banned_file_path)
	clear_old_records(banned_ip_file_path)
	for line in io.lines(banned_file_path) do
		local b = lume.split(line)
		if uuid == b[1] or (unique_id ~= "" and b[1] == unique_id) then
			local reason = ""
			if b[3] then
				reason = join(b, " ", 3)
			end
			return b[2], reason
		end
	end
	for line in io.lines(banned_ip_file_path) do
		local b = lume.split(line)
		if ip == b[1] then
			local reason = ""
			if b[3] then
				reason = join(b, " ", 3)
			end
			return b[2], reason
		end
	end
	return false
end

local function check_admin(uuid)
	for line in io.lines(admins_file_path) do
		if line == uuid then
			return true
		end
	end
	return false
end

local function ban(client, args)
	local t = tonumber(args[3])
	local cl = api.call_function("get_client_by_name", args[2])
	if cl then
		if not t then
			t = 365*24 -- 1 year
		else
			table.remove(args, 3)
		end

		local ban_time = socket.gettime() + t*60*60
		api.call_function("chat_message", args[2].." banned by admin for "..t.." hours", "system")

		local reason = ""
		if args[3] then
			reason = join(args, " ", 3)
		end

		local banned_file = io.open(banned_file_path, "a")
		banned_file:write(api.get_data("clients_data")[cl].uuid.." "..ban_time.." "..reason.."\n")
		if api.get_data("clients_data")[cl].unique_id and api.get_data("clients_data")[cl].unique_id ~= "" then
			banned_file:write(api.get_data("clients_data")[cl].unique_id.." "..ban_time.." "..reason.."\n")
		end
		api.call_function("kick", cl, args)
		banned_file:close()
	else
		api.call_function("chat_message", "Unknown name", "error", true, client)
	end
end

local function banip(client, args)
	local t = tonumber(args[3])
	local cl = api.call_function("get_client_by_name", args[2])
	if cl then
		if not t then
			t = 7*24 -- week
		else
			table.remove(args, 3)
		end

		local reason = ""
		if args[3] then
			reason = join(args, " ", 3)
		end

		local ban_time = socket.gettime() + t*60*60
		local banned_file = io.open(banned_ip_file_path, "a")
		banned_file:write(api.get_data("clients_data")[cl].ip.." "..ban_time.." "..reason.."\n")
		banned_file:close()
		table.insert(args, 3, t)
		ban(client, args)
	else
		api.call_function("chat_message", "Unknown name", "error", true, client)
	end
end

local function shutdown(client, args)
	api.call_function("shutdown")
end

local function set_difficulty(client, args)
	local t = {
		"easy", "standard", "hard", "impossible"
	}
	if args[2] then
		if find_in_table(args[2], t) then
			game_data.difficulty = args[2]
			api.call_function("chat_message", "Difficulty changed successfully ", "system", true, client)
		end
	else
		api.call_function("chat_message", "Please write difficulty. Example: /setdifficulty easy", "error", true, client)
	end
end

local function mute(client, args)
	local cl = api.call_function("get_client_by_name", args[2])
	if cl then
		table.insert(muted, api.get_data("clients_data")[cl].uuid)
		api.call_function("chat_message", "Player "..args[2].." is muted ", "system")
	else
		api.call_function("chat_message", "Unknown name", "error", true, client)
	end
end

local function unmute(client, args)
	local cl = api.call_function("get_client_by_name", args[2])
	if cl then
		remove_from_table(api.get_data("clients_data")[cl].uuid, muted)
		api.call_function("chat_message", "Player "..args[2].." is no longer muted ", "system")
	else
		api.call_function("chat_message", "Unknown name", "error", true, client)
	end
end

local function sudo(client, args)
	local cl = api.call_function("get_client_by_name", args[2])
	if cl then
		api.parse_command(join(args," ", 3), cl)
		api.call_function("chat_message", "Command completed successfully", "system")
	else
		api.call_function("chat_message", "Unknown name", "error", true, client)
	end
end

local function forcenext()
    api.next_turn()
end

function M.init(_api)
	api = _api
	api.register_command("/shutdown", shutdown)
	api.register_command("/ban", ban)
	api.register_command("/banip", banip)
	api.register_command("/setdifficulty", set_difficulty)
	api.register_command("/mute", mute)
	api.register_command("/unmute", unmute)
	api.register_command("/sudo", sudo)
	api.register_command("/forcenext", forcenext)
	game_data.difficulty = server_settings.plugin.difficulty or "standard"
end

function M.verify_registration(client, client_data)
	local timestamp, reason = check_ban(client_data.uuid, client_data.ip, client_data.unique_id)
	if timestamp then
		return false, "You are banned until: "..os.date("%c", timestamp).."\nReason: "..reason
	end
	return true
end

function M.on_player_registered(client)
	local cl_data = api.get_data("clients_data")[client]
	if check_admin(cl_data.uuid) then
		api.call_function("set_permissions_group", client, "admin")
	end
end

function M.on_player_joined(client)
	if server_settings.plugin.welcome ~= "" then
		local t = {
			type = "server_event",
			data = {
				text = server_settings.plugin.welcome
			}
		}
		api.send_data(to_json(t), client)
	end
end

function M.valid_message(text, client)
	return not client or not find_in_table(api.get_data("clients_data")[client].uuid, muted)
end

return M