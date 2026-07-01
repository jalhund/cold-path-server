--Player state: connected, ready, in_game, observer, waiting_game_data
--Server state: starting, next, in_game

local M = {}

local server_state = "starting"
local host_is_observer = false

local json = require "scripts.utils.json"
local lualzw = require "scripts.utils.lualzw"
local base64 = require "scripts.utils.base64"
local core = require "core.core"
local ai = require "core.ai.ai"
local ac = require "core.server.anticheat"

local timer_module = require "core.timer"
local timer_instance

local server_settings = require "server_settings"
local custom_map_storage = require "scripts.custom_map_storage"
local map_package = require "scripts.map_package"

local HOST_IS_PLAYER = false
local HOST_CIVILIZATION = nil
local host_is_ready = false

local tcp_server_require = require "defnet.tcp_server"
local tcp_server = nil

local plugin = require "core.server.plugins.plugins_manager"

local clients_data = {}
local clients_ready = {}

local preferred_civs = {} -- UUID: civilization

local function get_server_info()
	local t = deepcopy(server_settings.server_info)
	t.data.players = 0
	for k, v in pairs(clients_data) do
		if clients_data[k].state and clients_data[k].state == "in_game" then
			t.data.players = t.data.players + 1
		end
	end
	if HOST_IS_PLAYER then
		t.data.players = t.data.players + 1
	end
	t.data.size = lume.count(game_data.lands, function(x) return not x.defeated and x.name ~= "undeveloped_land" end)
	t.data.icon_url = server_settings.server_info.data.icon_url or ""
	return t
end

local function update_players_list()
	local t = {
		type = "update_players_list",
		data = {
			players_list = M.get_players_list()
		}
	}
	tcp_server.broadcast(to_json(t))
end

local function free_land(land)
	-- print(debug.traceback(), land)
	-- pprint("Game data land:", game_data.lands[land])
	if not M.is_player(land) and land ~= "Undeveloped_land" and not game_data.lands[land].defeated then
		return true
	end
end

local function find_free_land(uuid)
	if preferred_civs[uuid] and free_land(preferred_civs[uuid]) then
		return preferred_civs[uuid]
	end

	local free_lands = {}
	local full_free_lands = {}

	for k, v in pairs(game_data.lands) do
		if free_land(k) then
			table.insert(free_lands, k)
		end
		if free_land(k) and not get_key_for_value(preferred_civs, k) then
			table.insert(full_free_lands, k)
		end
	end

	if #full_free_lands > 0 then
		return lume.randomchoice(full_free_lands)
	elseif #free_lands > 0 then
		return lume.randomchoice(free_lands)
	else
		return nil
	end
end

local function check_name(name)
	if name == "" then
		return false
	end
    if name:match("%W") then
        return false
    end

	if HOST_IS_PLAYER and name == settings.name then
		return false
	end
	for k, v in pairs(clients_data) do
		if name == v.name then
			return false
		end
	end
	return true
end

local function check_uuid(uuid)
	if string.len(uuid) ~= 56 then
		return false
	end
	if HOST_IS_PLAYER and uuid == settings.uuid then
		return false
	end
	for k, v in pairs(clients_data) do
		if uuid == v.uuid then
			return false
		end
	end
	return true
end

local function check_version(version)
	local client_version, client_patch = version:match("(%d+)%.(%d+)")
	if tonumber(client_version) == server_settings.SERVER_VERSION then
		return true
	end
	return false
end

local function kick(client, kick_reason)
	if kick_reason then
		local kick_info = {
			type = "kick",
			data = {
				reason = kick_reason
			}
		}
		tcp_server.urgent_send(to_json(kick_info), client)
	end
	log("Kick client: ", client, " by reason: ", kick_reason)
	tcp_server.remove_client(client)
end

--local stat = require "scripts.sarah.statistics"

--local function print_send(table, client, k)
	 --stat.add("send_game_data", #to_json(table))
--end

local function splitByChunk(text, chunkSize)
    local s = {}
    for i=1, #text, chunkSize do
        s[#s+1] = text:sub(i,i+chunkSize - 1)
    end
    return s
end

local clients_game_data = {}

local function send_game_data(client, draw)
	local part_size = 768

	local origin_game_data = deepcopy(game_data)
	origin_game_data.player_land = clients_data[client].civilization

	clients_game_data[client] = {}

	-- Remove extra data
	for k, v in pairs(origin_game_data.lands) do
		if k ~= origin_game_data.player_land then
			v.opened_technology = {}
			v.opened_skills = {}
			v.bonuses = {}
		end
		v.ai.strategy.wish = {}
	end

	for k, v in pairs(origin_game_data.provinces) do
		if not v.water then
			origin_game_data.provinces[k].p = lume.round(v.p, 0.01)
			if v.o ~= origin_game_data.player_land then
				v.l_a = 0
			end
		end
	end

	for k, v in pairs(origin_game_data.provinces) do
		if not v.water then
			v.p = math.floor(v.p)
		end
	end

	-- analyze_table(origin_game_data.lands.Russia)

	local t_gd_start = socket.gettime()

	local t_json = socket.gettime()
	local json_data = to_json(origin_game_data)
	print(string.format("[MAP_PERF] server send_game_data: to_json %.1f ms (size=%d)",
		(socket.gettime() - t_json) * 1000, #json_data))

	local t_compress = socket.gettime()
	json_data = lualzw.compress(json_data)
	print(string.format("[MAP_PERF] server send_game_data: lualzw.compress %.1f ms (-> %d bytes)",
		(socket.gettime() - t_compress) * 1000, #json_data))

	local t_base64 = socket.gettime()
	json_data = base64.encode(json_data)
	print(string.format("[MAP_PERF] server send_game_data: base64.encode %.1f ms (-> %d bytes)",
		(socket.gettime() - t_base64) * 1000, #json_data))

	local st = splitByChunk(json_data, part_size)
	local n = #st

	-- For debug
	-- local md5 = require "scripts.utils.md5"
	-- print("Send game data hash is: ", md5.sumhexa(json_data))
	print(string.format("[MAP_PERF] server send_game_data: prep TOTAL %.1f ms (parts=%d, part_size=%d, total=%d)",
		(socket.gettime() - t_gd_start) * 1000, n, part_size, #json_data))

	local t = {
		type = "game_data_info",
		data = {
			total = n,
			hash = xxhash(json_data),
			draw = draw
		}
	}
	tcp_server.send(to_json(t), client)

	for i, v in ipairs(st) do
		 --print("Chunk size is: ", #v, #to_json({type = "game_data",data = v}))
		local t = {
			type = "game_data",
			data = v
		}
		-- print("data size send is:", #to_json(t))
		-- analyze_table(t.data)
		table.insert(clients_game_data[client], t)
		tcp_server.send(to_json(t), client)
	end
	-- stat.results("send_game_data")
	-- stat.remove_state("send_game_data")
end

local function get_custom_map_package_path()
	if type(custom_map_path) == "string" and map_package.is_package_path(custom_map_path) then
		return custom_map_path
	end
	if HOST_IS_PLAYER then
		return custom_map_storage.find_exported_map_path() or custom_map_storage.get_default_exported_map_path()
	end
	if type(game_data.map_name) == "string" and game_data.map_name ~= "" then
		local by_name = "maps/" .. game_data.map_name .. ".map"
		if map_package.file_exists(by_name, "rb") then
			return by_name
		end
	end
	if type(game_data.map) == "string" and game_data.map ~= "" then
		local by_id = "maps/" .. game_data.map .. ".map"
		if map_package.file_exists(by_id, "rb") then
			return by_id
		end
		return by_id
	end
end

local prepared_map_files
local custom_map_hash

local function prepare_map_files()
	local t_start = socket.gettime()
	local package_path = get_custom_map_package_path()
	if not package_path then
		print("file error: custom map package path not found")
		return
	end

	local t_read = socket.gettime()
	local package_data, err = map_package.read_package(package_path)
	if not package_data then
		print("file error:", package_path, err)
		return
	end
	print(string.format("[MAP_PERF] server prepare_map_files: read_package %.1f ms (path=%s)",
		(socket.gettime() - t_read) * 1000, tostring(package_path)))

	local t_compress = socket.gettime()
	local d = lualzw.compress(package_data.bytes)
	print(string.format("[MAP_PERF] server prepare_map_files: lualzw.compress %.1f ms (%d -> %d bytes)",
		(socket.gettime() - t_compress) * 1000, #package_data.bytes, #d))

	local luaxxhash = require "luaxxhash"
	local t_hash = socket.gettime()
	custom_map_hash = luaxxhash(d)
	print(string.format("[MAP_PERF] server prepare_map_files: luaxxhash %.1f ms",
		(socket.gettime() - t_hash) * 1000))

	local t_base64 = socket.gettime()
	prepared_map_files = base64.encode(d)
	print(string.format("[MAP_PERF] server prepare_map_files: base64.encode %.1f ms (-> %d bytes)",
		(socket.gettime() - t_base64) * 1000, #prepared_map_files))

	print(string.format("[MAP_PERF] server prepare_map_files: TOTAL %.1f ms",
		(socket.gettime() - t_start) * 1000))
end

local function send_map_data(client)
    local t_start = socket.gettime()
    print("send map data")

    local nt = {
        type = "map_data_hash",
        data = {
            hash = custom_map_hash
        }
    }
    tcp_server.send(to_json(nt),client)

    local t= {
        type = "map_data",
        data = ""
    }
    local client_has_map = find_in_table(tostring(custom_map_hash), clients_data[client].custom_maps)
    if not client_has_map then
        t.data = prepared_map_files
    end
    --pprint("clients maps: ", clients_data[client].custom_maps, custom_map_hash, find_in_table(custom_map_hash, clients_data[client].custom_maps))
    tcp_server.send(to_json(t),client)
    print(string.format("[MAP_PERF] server send_map_data: %.1f ms (hash=%s, already_has_map=%s, sent_bytes=%d)",
        (socket.gettime() - t_start) * 1000, tostring(custom_map_hash), tostring(client_has_map), #t.data))
end

local function send_game_files(client)
    local t = {
        type = "game_files",
        data = {
            scenario = original_game_data,
        }
    }
    if game_data.custom_map then
        t.data.map = prepared_map_files
    end
    tcp_server.send(to_json(t),client)
end

local function register_player(client, client_data, ip)
	local free_land = find_free_land(client_data.uuid)
	preferred_civs[client_data.uuid] = free_land
	local check_name = check_name(client_data.name)
	local check_uuid = check_uuid(client_data.uuid)
	local check_version = check_version(client_data.version)
	clients_data[client].uuid = client_data.uuid
	clients_data[client].unique_id = client_data.unique_id
	clients_data[client].name = client_data.name
	clients_data[client].ip = ip
	client_data.ip = ip
	clients_data[client].custom_maps = client_data.custom_maps

	local verification_result, info = plugin.verify_registration(client, client_data)
	if not free_land then
		kick(client, "No free places")
	elseif not check_name then
		kick(client, "The name is incorrect or a player with that name is already in the game")
	elseif not check_uuid then
		kick(client, "The UUID is incorrect or a player with that UUID is already in the game")
	elseif not check_version then
		kick(client, "Your game version is too old or new. Server version: "..server_settings.SERVER_VERSION)
	elseif not verification_result then
		kick(client, "You do not have a license or you are banned from this server\n"..(info or ""))
	else
		clients_data[client].civilization = free_land
		local t_register = socket.gettime()
		if game_data.custom_map then
		    print("custom map")
		    send_map_data(client)
		end
		send_game_data(client, true)
		print(string.format("[MAP_PERF] server register_player: send map+game data TOTAL %.1f ms (uuid=%s, custom_map=%s)",
			(socket.gettime() - t_register) * 1000, tostring(clients_data[client].uuid), tostring(game_data.custom_map)))
		clients_data[client].state = "in_game"
		local t = {
			type = "welcome",
			data = {
				players_list = M.get_players_list(),
				commands_list = plugin.commands_list(),
				game_values = game_values,
				buildings_data = buildings_data,
				technology_data = technology_data,
				skills_data = skills_data
			}
		}
        tcp_server.send(to_json(t),client)
		log("Registered player: ", clients_data[client].uuid, " ", clients_data[client].name, " ", clients_data[client].civilization)
		plugin.on_player_registered(client)
		update_players_list()
	end
end

local function next()
	server_state = "next"
	if HOST_IS_PLAYER then
		msg.post("error_message:/error_message", "show_wait_message", { name = "Waiting for civilizations",
		text = "Waiting for civilizations"})
		msg.post("game:/map_interface", "clear_before_next")
	end
	local next_function = function()
		tcp_server.broadcast(to_json({type = "start_next", data = {}}))
		if HOST_IS_PLAYER then
			save_system.save(game_data)
		end
		plugin.before_next()
		ai.handle()
		core.next()
		ai.late_handle()
		for k, v in pairs(clients_data) do
			if v.state and (v.state == "in_game" or v.state == "observer") then
				local t = {
					type = "next",
					data = {
						players_list = M.get_players_list(),
						time_to_turn = server_settings.time_to_turn
					}
				}
				-- local ok, err = pcall(function()
					-- pprint("TCP send data: ", t)
				send_game_data(k, true)
				tcp_server.send(to_json(t),k)
				-- end)
				-- if not ok then
					-- print("Error sendings data:", err)
				-- end
			end
		end
		-- Espionage: the notification queue has now been broadcast to every client;
		-- clear it so it is not re-sent next turn. When the host is a player, its own
		-- UI drains the shared queue instead (see hide_because_next).
		if not HOST_IS_PLAYER then
			game_data.espionage_notifications = {}
		end
		lume.clear(clients_ready)
		host_is_ready = false
		tcp_server.broadcast(to_json({type = "finish_next", data = {}}))
		if HOST_IS_PLAYER then
			msg.post("game:/controller#controller", "show_map_interface")
			msg.post("game:/map_interface", "hide_because_next", {
				timer_time = server_settings.time_to_turn
			})
			msg.post("game:/map_interface", "update_top_line")
			msg.post("map:/map#map_collection", "draw_all")
			msg.post("error_message:/error_message", "hide_wait_message", { name = "Waiting for civilizations",
			text = "Waiting for civilizations"})
		end
		if timer_instance then
			timer_instance:remove()
			timer_instance = nil
		end
		timer_instance = timer_module.after(server_settings.time_to_turn, next_timer)
		server_state = "in_game"
	end

	-- local inspect = require "scripts.utils.inspect"
	-- local file = io.open("game_data.dat", "w")
	-- file:write(inspect(game_data))
	-- file:close()

	-- local file = io.open("game_data.json", "w")
	-- file:write(to_json(game_data))
	-- file:close()

	-- so that a window with a request to wait for the next move is displayed in the game client
	if M.is_console() then
		next_function()
	else
		timer.delay(0.01, false, next_function)
	end
end

function next_timer()
	if server_state ~= "starting" and server_state ~= "next" then
		next()
	end
end

local function check_ready()
	local all_ready = true

	local not_ready_count = 0
	local not_ready_client

	if HOST_IS_PLAYER and not host_is_ready then
		all_ready = false
	end
	for k, v in pairs(clients_data) do
		if clients_data[k].state and clients_data[k].state == "in_game" then
			if not clients_ready[k] then
				not_ready_count = not_ready_count + 1
				not_ready_client = k
				all_ready = false
			end
		end
	end
	if all_ready then
		print("All players are ready. Start next turn")
		next()
	else
		if not_ready_count == 0 and not all_ready then
			msg.post("game:/map_interface", "add_event", { type = "ready",
			event_data = { subtype = "you_alone_are_not_ready", text = lang("you_alone_are_not_ready", "offers") } })
		elseif not_ready_count == 1 then
			t = {
				type = "you_alone_are_not_ready",
				data = {}
			}
			tcp_server.send(to_json(t),not_ready_client)
		end
	end
end

local function decode_data(data)
	local decoded_data = {
		data = ""
	}
	for i in string.gmatch(data, "[^`]+") do
		if decoded_data.type then
			decoded_data.data = decoded_data.data..i
		else
			decoded_data.type = i
		end
	end

	decoded_data.data = json.decode(decoded_data.data)

	return decoded_data
end

local function on_data(data, ip, port, client)
	local ok, err = pcall(function()
	local t
	if server_state == "starting" then
		return
	end
		-- log("On data: ", data, " from ", ip, ":", port)
		-- print("Decoding data:", data)
		data = decode_data(data)
		-- pprint("Decoded data:", data)
		if data.type == "get_server_info" then
			t = deepcopy(get_server_info())
			t.data.server_ip = data.data.server_ip
			tcp_server.urgent_send(to_json(t), client)
			kick(client, "no_message")
		elseif data.type == "ping" then
			t = {
				type = "pong",
				data = {}
			}
			tcp_server.send(to_json(t),client)
		elseif data.type == "introduce" then
			register_player(client, data.data, ip)
		end
		if clients_data[client] and clients_data[client].state and clients_data[client].state == "in_game" then
			plugin.on_data(data, ip, port, client)
			if data.type == "ready" then
				clients_ready[client] = true
				check_ready()
			elseif data.type == "cmd" then
				plugin.parse_command(data.data.cmd, client)
			elseif data.type == "in_game" then
				plugin.on_player_joined(client)
			elseif data.type == "get_game_files" then
	            send_game_files(client)
			elseif data.type == "add_chat_message" then
				M.add_chat_message(data.data.text, client)
			elseif data.type == "recruit" then
				-- TODO: change percent to amount. Not changed yet so as not to break version compatibility
				if not ac.verify_action("recruit", data.data.land, data.data.province,data.data.percent) then
					return
				end
				M.recruit(data.data.land, data.data.province,data.data.percent)
			elseif data.type == "move" then
				if not ac.verify_action("move", data.data.land, data.data.from, data.data.to, data.data.amount) then
					return
				end
				M.move(data.data.land, data.data.from, data.data.to, data.data.amount)
			elseif data.type == "dissolve" then
				if not ac.verify_action("dissolve", data.data.land, data.data.province,data.data.percent) then
					return false
				end
				M.dissolve(data.data.land, data.data.province,data.data.percent)
			elseif data.type == "shell" then
				if not ac.verify_action("shell", data.data.land, data.data.from, data.data.to, data.data.count) then
					return false
				end
				M.shell(data.data.land, data.data.from, data.data.to, data.data.count)
			elseif data.type == "air_attack" then
				if not ac.verify_action("air_attack", data.data.land, data.data.from, data.data.to) then
					return false
				end
				M.air_attack(data.data.land, data.data.from, data.data.to)
			elseif data.type == "select_technology" then
				if not ac.verify_action("select_technology", data.data.land, data.data.technology) then
					return false
				end
				M.select_technology(data.data.land, data.data.technology)
			elseif data.type == "open_skill" then
				if not ac.verify_action("open_skill", data.data.land, data.data.skill) then
					return false
				end
				core.open_skill(data.data.land, data.data.skill)
			elseif data.type == "set_tax" then
				if not ac.verify_action("set_tax", data.data.land, data.data.tax) then
					return false
				end
				core.set_tax(data.data.land, data.data.tax)
			elseif data.type == "set_counter_intelligence" then
				core.set_counter_intelligence(data.data.land, data.data.value)
			elseif data.type == "espionage" then
				core.espionage(data.data.land, data.data.op, data.data.target_province, data.data.chosen_building)
			elseif data.type == "set_ideology" then
				if not ac.verify_action("set_ideology", data.data.land, data.data.ideology) then
					return false
				end
				core.set_ideology(data.data.land, data.data.ideology)
			elseif data.type == "build" then
				if not ac.verify_action("build", data.data.land,data.data.province, data.data.building_id) then
					return false
				end
				core.build(data.data.land,data.data.province, data.data.building_id)
			elseif data.type == "destroy" then
				if not ac.verify_action("destroy", data.data.land,data.data.province, data.data.building_id) then
					return false
				end
				core.destroy(data.data.land,data.data.province, data.data.building_id)
			elseif data.type == "peace" then
				if not ac.verify_action("peace", clients_data[client].civilization, data.data.to) then
					return false
				end
				M.peace(clients_data[client].civilization, data.data.to)
			elseif data.type == "pact" then
				if not ac.verify_action("pact", clients_data[client].civilization, data.data.to) then
					return false
				end
				M.pact(clients_data[client].civilization, data.data.to)
			elseif data.type == "war" then
				if not ac.verify_action("war", clients_data[client].civilization, data.data.to) then
					return false
				end
				M.war(clients_data[client].civilization, data.data.to)
			elseif data.type == "alliance" then
				if not ac.verify_action("alliance", clients_data[client].civilization, data.data.to) then
					return false
				end
				M.alliance(clients_data[client].civilization, data.data.to)
			elseif data.type == "break_alliance" then
				if not ac.verify_action("break_alliance", clients_data[client].civilization, data.data.to) then
					return false
				end
				M.break_alliance(clients_data[client].civilization, data.data.to)
			elseif data.type == "chemical_weapon" then
				if not ac.verify_action("chemical_weapon", data.data.land, data.data.from, data.data.to) then
					return false
				end
				M.chemical_weapon(data.data.land, data.data.from, data.data.to)
			elseif data.type == "tank" then
				if not ac.verify_action("tank", data.data.land, data.data.from, data.data.to) then
					return false
				end
				M.tank(data.data.land, data.data.from, data.data.to)
			elseif data.type == "drone" then
				if not ac.verify_action("drone", data.data.land, data.data.from, data.data.to) then
					return false
				end
				M.drone(data.data.land, data.data.from, data.data.to)
			elseif data.type == "nuclear_weapon" then
				if not ac.verify_action("nuclear_weapon", data.data.land, data.data.province) then
					return false
				end
				M.nuclear_weapon(data.data.land, data.data.province)
			elseif data.type == "vassal" then
				if not ac.verify_action("vassal", clients_data[client].civilization, data.data.to) then
					return false
				end
				M.vassal(clients_data[client].civilization, data.data.to)
			elseif data.type == "revolt" then
				if not ac.verify_action("revolt", data.data.owner, data.data.vassal) then
					return false
				end
				M.revolt(data.data.owner, data.data.vassal)
			elseif data.type == "independence" then
				if not ac.verify_action("independence", data.data.owner, data.data.vassal) then
					return false
				end
				M.independence(data.data.owner, data.data.vassal)
			elseif data.type == "trade" then
				if not ac.verify_action("trade", clients_data[client].civilization, data.data.to, data.data.from_list, data.data.to_list) then
					return false
				end
				M.trade(clients_data[client].civilization, data.data.to, data.data.from_list, data.data.to_list)
			elseif data.type == "urge_allies" then
				if not ac.verify_action("urge_allies", data.data.land, data.data.enemy) then
					return false
				end
				M.urge_allies(data.data.land, data.data.enemy)
			elseif data.type == "support_revolt" then
				if not ac.verify_action("support_revolt", data.data.from, data.data.to, data.data.value) then
					return false
				end
				M.support_revolt(data.data.from, data.data.to, data.data.value)
			elseif data.type == "accept_offer" then
				if not ac.verify_action("accept_offer", data.data.land, data.data.offer_id) then
					return false
				end
				M.accept_offer(data.data.land, data.data.offer_id)
			elseif data.type == "change_country" then
				M.change_country(data.data.from, data.data.to, client)
			elseif data.type == "change_country_name" then
				M.change_country_name(data.data.land, data.data.new_name, client)
			elseif data.type == "change_country_color" then
				M.change_country_color(data.data.land, data.data.new_color, client)
			elseif data.type == "change_country_banner" then
				M.change_country_banner(data.data.land, data.data.new_banner, client)
			end
		end
	end)
	if not ok then
		log("error", "On data error: ", err)
		kick(client, "Server error: "..err)
	end
end

local function on_client_connected(ip, port, client)
	log("Client connected from " .. ip .. ":" .. port)
	clients_data[client] = {}
	clients_data[client].ip = ip
	clients_data[client].port = port
	clients_data[client].state = "connected"
	clients_game_data[client] = {}
end

local function on_client_disconnected(ip, port, client)
	if clients_data[client].state == "in_game" or clients_data[client].state == "observer" then
		plugin.on_player_disconnected(client)
		clients_data[client] = nil
		update_players_list()
		check_ready()
	end
	clients_data[client] = nil
	clients_game_data[client] = nil
end

function M.init()
end

function M.final()
	if tcp_server then
		print("Stopping tcp server")
		for k, v in pairs(clients_data) do
			tcp_server.urgent_send(to_json({type = "server_closed"}),k)
		end
		tcp_server.stop()
		server_is_off = true
	end
end

local last_time = 0
local cur_time = 0

function M.update()
	if tcp_server then
		tcp_server.update()
		if HOST_IS_PLAYER then
			udp_server.broadcast()
		end

		cur_time = socket.gettime()
		timer_module.update(cur_time - last_time)
		last_time = cur_time
	end
end

local function get_client(civ)
	for k, v in pairs(clients_data) do
		if v.civilization == civ then
			return k
		end
	end
end

function M.start(console)
	server_state = "starting"
	log("Start server. Console mode: ", console)
	clients_data = {}
	clients_ready = {}
	preferred_civs = {}
	if tcp_server then
		-- for k, v in pairs(clients_data) do
			-- tcp_server.urgent_send(to_json({type = "server_closed"}),k)
		-- end
		tcp_server.stop()
	end
	tcp_server = tcp_server_require.create(server_settings.server_info.data.server_port, on_data, on_client_connected, on_client_disconnected)
	tcp_server.start()
	if console then
		HOST_IS_PLAYER = false
		HOST_CIVILIZATION = nil
	else
		HOST_IS_PLAYER = true
		HOST_CIVILIZATION = game_data.player_land
	end
	log("Start plugin initialization")
	local plugin_api = {
		_is_player_host = HOST_IS_PLAYER,
		_chat_function = M.chat,
		_clients_d = clients_data,
		_clients_ready = clients_ready,
		_preferred_civs = preferred_civs,
		_kick_function = kick,
		_shutdown = M.final,
		_send = tcp_server.send,
		_set_server_state = function(new_state)
			server_state = new_state
		end,
		_start = M.start,
		_next = function() next() end
	}

	timer_module.clear()
	timer_instance = nil

	local logger = require "scripts.utils.logger"
	local log_config = require "core.server.server_data.log_config"

	logger.set_config(log_config)
	if console then
		logger.set_mode("standard")
	end

	ai.init(M.is_player)
	plugin.init(plugin_api)
	core.set_is_player_function(M.is_player)
	core.set_difficulty_list(ai.difficulty_list)
	core.set_game_end_callback(function(land, win)
		print("Server win callback: ", land, win)
		if win and not game_data.game_over then
			if HOST_IS_PLAYER then
				msg.post("/controller#controller", "show_finish_screen", {
					winner = land,
					win = land == HOST_CIVILIZATION
				})
			end
			local t = {
			type = "win",
				data = {
					land = land
				}
			}
			tcp_server.broadcast(to_json(t))
			game_data.game_over = true
			if not M.is_console() then
				for k, v in pairs(clients_data) do
					kick(k, "Game over")
				end
			end
			preferred_civs = {}
		else
			if HOST_IS_PLAYER then
				if HOST_CIVILIZATION == land then
					msg.post("game:/map_interface", "to_spectator_mode")
					msg.post("game:/map_interface", "clear_before_next")
					host_is_observer = true
					msg.post("/controller#controller", "show_finish_screen", {
						win = false
					})
				else
					msg.post("game:/map_interface_chat", "add_chat_message", {
						text = lang("civilization").." "..land_lang(land).." "..lang("has_ceased_to_exist", "chat_messages")
					})
				end
			end
			local t = {
			type = "lose",
				data = {
					land = land
				}
			}
			tcp_server.broadcast(to_json(t))
			local cl = get_client(land)
			if cl then
				clients_data[cl].state = "observer"
			end
		end
		plugin.game_over(land, win)
	end)
	core.set_update_land_data_callback(function(land1)
		local land_provinces = {}
		for k, v in pairs(game_data.provinces) do
			if v.o == land1 then
				land_provinces[k] = v
			end
		end
		local t = {
			type = "update_land_data",
			data = {
				land = land1,
				land_data = game_data.lands[land1],
				provinces = land_provinces
			}
		}
		-- it is not good,but fast fix for custom map. In custom map province id is number,not string
		if game_data.custom_map then
		    t.data.provinces = game_data.provinces
		end
		tcp_server.broadcast(to_json(t))
		if HOST_IS_PLAYER then
			msg.post("game:/map_interface", "update_top_line")
			msg.post("map:/map#map_collection", "draw_provinces")
			msg.post("map:/map#map_collection", "draw_provinces_text")
		end
	end)

	core.set_accept_offer_callback(function(offer)
		if HOST_IS_PLAYER then
			msg.post("game:/map_interface", "accepted_offer", {
				offer = offer
			})
		end
		local t = {
			type = "accept_offer_callback",
			data = {
				offer = offer,
			}
		}
		for k, v in pairs(clients_data) do
			if v.state == "in_game" then
				send_game_data(k)
				tcp_server.send(to_json(t), k)
			end
		end
	end)

	if timer_instance then
		timer_instance:remove()
		timer_instance = nil
	end
	timer_instance = timer_module.after(server_settings.time_to_turn, next_timer)
	
	if game_data.custom_map then
	    prepare_map_files()
	end
	server_state = "in_game"
end

function M.is_console()
	return not HOST_IS_PLAYER
end

function M.next()
	if not host_is_observer then
		host_is_ready = true
		check_ready()
	end
end

function M.is_voted()
	return host_is_ready
end

function M.is_player(civ)
	if HOST_IS_PLAYER and HOST_CIVILIZATION == civ then
		return true
	end
	for k, v in pairs(clients_data) do
		if v.civilization == civ then
			return true
		end
	end
	return false
end

function M.get_players_list()
	local players_list = {}
	local n = 1
	for k, v in pairs(game_data.lands) do
		if HOST_IS_PLAYER and HOST_CIVILIZATION == k then
			players_list[n] = {civilization = k,name = settings.name, host = true}
		end
		for key, val in pairs(clients_data) do
			if val.state and val.state == "in_game" and val.civilization == k then
				players_list[n] = {civilization = k, name = val.name}
			end
		end
		if not players_list[n] then
			players_list[n] = {civilization = k}
		end
		n = n + 1
	end
	return players_list
end

function M.in_game()
	
end

function M.chat(message_text, just_for_host, client)
	local t = {
		type = "added_chat_message",
		data = {
			text = message_text
		}
	}
	if client then
		tcp_server.send(to_json(t),client)
	end
	if not just_for_host then 
		tcp_server.broadcast(to_json(t))
	end
	if HOST_IS_PLAYER and not client then
		msg.post("game:/map_interface_chat", "add_chat_message", { text = message_text})
	end
	log("chat", message_text)
end

function M.add_chat_message(message_text, client)
	if validate_text(message_text) then
		return
	end
	if string.char(string.byte(message_text,1)) == "/" then
		plugin.parse_command(message_text)
	else
		if plugin.valid_message(message_text, client) then
			message_text = plugin.attribute_message(message_text, client)
			M.chat(message_text)
		end
	end
end

local function notify_allies(land, province, json_data)
	-- local relations = require "core.relations"
	-- local allies_list = {}
	-- log("Notifing allies: ", land, json_data)
	-- for k, v in pairs(clients_data) do
		-- if v.state and v.state == "in_game" and (
			-- relations.check_alliance(land, v.civilization) or
			-- relations.check_vassal(land, v.civilization) or
			-- relations.check_vassal(v.civilization, land) or
			-- land == v.civilization) then
				-- table.insert(allies_list, k)
		-- end
	-- end
	if HOST_IS_PLAYER then
		if land == HOST_CIVILIZATION then
			msg.post("map:/map#map_collection", "draw_provinces_text", { province = province})
		end
	end
	-- for k, v in pairs(allies_list) do
		-- tcp_server.send(json_data, v)
	-- end
end

function M.recruit(land, province, percent)
	core.recruit(land, province, percent)
	local t = {
		type = "update_province_data",
		data = {
			province = province,
			province_data = game_data.provinces[province]
		}
	}
	notify_allies(land, province, to_json(t))
end

function M.move(land,from,to,amount)
	core.move(land, from, to, amount)
	local t = {
		type = "update_province_data",
		data = {
			province = from,
			province_data = game_data.provinces[from]
		}
	}
	notify_allies(land, from, to_json(t))
end

function M.dissolve(land, province, percent)
	core.dissolve(land, province, percent)
	local t = {
		type = "update_province_data",
		data = {
			province = province,
			province_data = game_data.provinces[province]
		}
	}
	notify_allies(land, from, to_json(t))
end

function M.shell(land, from, to, count)
	core.shell(land, from, to, count)
	if HOST_IS_PLAYER and land == HOST_CIVILIZATION then
		msg.post("game:/map_interface", "update_top_line")
	end
end

function M.air_attack(land, from, to)
	core.air_attack(land, from, to)
end

function M.tank(land, from, to)
	core.tank(land, from, to)
	if HOST_IS_PLAYER and land == HOST_CIVILIZATION then
		msg.post("game:/map_interface", "update_top_line")
	end
end

function M.drone(land, from, to)
	core.drone(land, from, to)
	if HOST_IS_PLAYER and land == HOST_CIVILIZATION then
		msg.post("game:/map_interface", "update_top_line")
	end
end

function M.open_skill(land, skill)
	core.open_skill(land, skill)
	if HOST_IS_PLAYER and land == HOST_CIVILIZATION then
		msg.post("game:/skills", "init_skills")
	end
end

function M.select_technology(land, technology)
	game_data.lands[land].selected_technology = technology
end

function M.set_tax(land, tax)
	core.set_tax(land, tax)
end

function M.set_counter_intelligence(land, value)
	core.set_counter_intelligence(land, value)
end

function M.espionage(land, op, target_province, chosen_building)
	return core.espionage(land, op, target_province, chosen_building)
end

function M.set_ideology(land, ideology)
	core.set_ideology(land, ideology)
end

function M.build(land, province, building_id)
	core.build(land, province, building_id)
	if HOST_IS_PLAYER and land == HOST_CIVILIZATION then
		msg.post("map:/map#map_collection", "draw_buildings", { province = province})
		msg.post("game:/map_interface", "update_top_line")
	end
end

function M.destroy(land, province, building_id)
	core.destroy(land, province, building_id)
	if HOST_IS_PLAYER and land == HOST_CIVILIZATION then
		msg.post("map:/map#map_collection", "draw_buildings", { province = province})
		msg.post("game:/map_interface", "update_top_line")
	end
end

function M.peace(from, to)
	core.peace(from, to)
end

function M.pact(from, to)
	core.pact(from, to)
end

function M.war(from, to)
	core.war(from, to)
end

function M.alliance(from, to)
	core.alliance(from, to)
end

function M.break_alliance(from, to)
	core.break_alliance(from, to)
end

function M.chemical_weapon(land, from, to)
	core.chemical_weapon(land, from, to)
	if HOST_IS_PLAYER and land == HOST_CIVILIZATION then
		msg.post("game:/map_interface", "update_top_line")
	end
end

function M.nuclear_weapon(land, province)
	core.nuclear_weapon(land, province)
	if HOST_IS_PLAYER and land == HOST_CIVILIZATION then
		msg.post("game:/map_interface", "update_top_line")
	end
end

function M.vassal(land1, land2)
	core.vassal(land1, land2)
end

function M.revolt(owner, vassal)
	core.revolt(owner, vassal)
end

function M.independence(owner, vassal)
	core.independence(owner, vassal)
end

function M.trade(from, to, from_list, to_list)
	core.trade(from, to, from_list, to_list)
end

function M.urge_allies(land, enemy)
	core.urge_allies(land, enemy)
end

function M.support_revolt(from, to, value)
	core.support_revolt(from, to, value)
	if HOST_IS_PLAYER and land == HOST_CIVILIZATION then
		msg.post("game:/map_interface", "update_top_line")
	end
end

function M.accept_offer(land, offer_id)
	core.accept_offer(offer_id, accept_offer_callback)
end

function M.change_country(from, to, client)
	-- Проверяем, что страна существует и свободна 
	-- (т.е. ни один игрок её не занимает)
	local client_data = clients_data[client]
	
	-- Проверяем, что клиент зарегистрирован и находится в игре
	if not client_data or client_data.state ~= "in_game" then
		return
	end
	
	-- Проверяем, что отправитель запроса - тот же игрок, который отправляет запрос
	if client_data.civilization ~= from then
		return
	end
	
	-- Проверяем, что целевая страна существует
	if not game_data.lands[to] then
		return
	end
	
	-- Проверяем, что целевая страна не занята другим игроком
	local is_occupied = false
	for k, v in pairs(clients_data) do
		if v.civilization == to then
			is_occupied = true
			break
		end
	end
	
	if HOST_IS_PLAYER and HOST_CIVILIZATION == to then
		is_occupied = true
	end
	
	if is_occupied then
		-- Страна уже занята, отправляем сообщение об ошибке
		M.chat("Невозможно сменить страну: " .. land_lang(to) .. " уже занята другим игроком.", true, client)
		return
	end
	
	-- Меняем страну игрока
	client_data.civilization = to
	
	-- Отправляем сообщение в чат всем игрокам
	M.chat(client_data.name .. " сменил страну на " .. land_lang(to) .. ".")
	
	-- Обновляем список игроков
	update_players_list()
	
	-- Отправляем игроку сообщение о необходимости перезагрузить интерфейс
	local t = {
		type = "civilization_changed",
		data = {
			new_civilization = to
		}
	}
	tcp_server.send(to_json(t), client)
end

function M.change_country_name(land, name, client)
	local client_data = clients_data[client]

	-- Проверяем что клиент зарегистрирован и находится в игре
	if client_data and client_data.state ~= "in_game" then
		return
	end

	if client_data.civilization ~= land then
		return
	end

	if not game_data.lands[land] then
		return
	end

	-- Изменяем название страны игрока
	game_data.lands[land].name = name

	update_players_list()

	-- Отправляем игроку сообщение о необходимости перезагрузить интерфейс
	local t = {
		type = "civilization_name_changed",
		data = {}
	}

	tcp_server.send(to_json(t), client)
end

function M.change_country_color(land, color, client)
	local client_data = clients_data[client]

	-- Проверяем что клиент зарегистрирован и находится в игре
	if client_data and client_data.state ~= "in_game" then
		return
	end

	if client_data.civilization ~= land then
		return
	end

	if not game_data.lands[land] then
		return
	end

	-- Изменяем название страны игрока
	game_data.lands[land].color = color

	update_players_list()

	-- Отправляем игроку сообщение о необходимости перезагрузить интерфейс
	local t = {
		type = "civilization_color_changed",
		data = {}
	}

	tcp_server.send(to_json(t), client)
end

function M.change_country_banner(land, banner, client)
	local client_data = clients_data[client]

	-- Проверяем что клиент зарегистрирован и находится в игре
	if client_data and client_data.state ~= "in_game" then
		return
	end

	if client_data.civilization ~= land then
		return
	end

	if not game_data.lands[land] then
		return
	end

	-- Изменяем флаг страны игрока
	game_data.lands[land].banner = banner

	update_players_list()

	-- Отправляем игроку сообщение о необходимости перезагрузить интерфейс
	local t = {
		type = "civilization_banner_changed",
		data = {}
	}

	tcp_server.send(to_json(t), client)
end

return M
