socket = require "socket"
ssl = require "ssl"

network = require "core.server.server"

-- This is here for fewer code changes when converting in-game server to console
save_system = {}
udp_server = {}

require "core.global_functions"
game_values = require "core.game_values"
buildings_data = require "scripts.buildings_data"
skills_data = require "scripts.skills_data"
technology_data = require "scripts.technology_data"

local inspect = require "scripts.utils.inspect"
xxhash = require "luaxxhash"

json = require "scripts.utils.json"
lume = require "scripts.utils.lume"

local logger = require "scripts.utils.logger"
log = logger.log

function sleep(n)  -- seconds
  local t0 = socket.gettime()
  while socket.gettime() - t0 <= n do end
end

function to_json_without_break(t)
	return json.encode(t)
end

function debug_log(...)
	local arg = {...}
	local file = io.open("log", "a")
	if file then
		file:write("["..os.date("%c").."] ")
		for i, v in ipairs(arg) do
			print("debug_log: "..inspect(v))
			file:write(inspect(v).." ")
		end
		file:write("\n")
		file:close()
	end
end

function to_json(t)
	if t.type == "game_data" then
		return t.type.."`"..t.data.."\n"
	elseif t.type then
		return t.type.."`"..json.encode(t.data).."\n"
	else
		return json.encode(t).."\n"
	end
	-- pprint("Table to json:", t)
	-- return json.encode(t).."\n"
end

function pprint(...)
	local arg = {...}
	for k, v in pairs(arg) do
		print(inspect(v))
	end
end

function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end