local M = {}

local validate_scenario = require "scripts.validate_scenario"
local timer_module = require "core.timer"

local api

local call_function
local register_command
local set_server_state
local get_data
local start

local scenarios = {
	europe = {
		millenium = require "scripts.scenarios.europe.millenium",
		wwi = require "scripts.scenarios.europe.wwi",
		great_northern_war = require "scripts.scenarios.europe.great_northern_war",
		crimean_war = require "scripts.scenarios.europe.crimean_war",
		modern_world = require "scripts.scenarios.europe.modern_world",
	},
	america = {
		modern_world = require "scripts.scenarios.america.modern_world"
	}
}



local next_map
local next_scenario

local function set_map(client, args)
	if scenarios[args[2]] then
		next_map = args[2]
		api.call_function("chat_message", api.get_data("clients_data")[client].name.." set next map to "..args[2], "system")
	else
		api.call_function("chat_message", "Unknown map", "error", true, client)
	end
end

local function set_scenario(client, args)
	if scenarios[args[2]] and scenarios[args[2]][args[3]] then
		next_map = args[2]
		next_scenario = args[3]
		api.call_function("chat_message", api.get_data("clients_data")[client].name.." set next map to "..args[2].." and next scenario to "..args[3], "system")
	else
		api.call_function("chat_message", "Unknown map or scenario", "error", true, client)
	end
end

local function show_scenarios_list(client, args)
	local text = ""
	for k, v in pairs(scenarios) do
		text = text..k..": "
		for key, val in pairs(v) do
			text = text..key.." "
		end
		text = text.."\n"
	end
	api.call_function("chat_message", text, "system", true, client)
end

local function next_game(client, args)
	M.game_over("Undeveloped_land", true)
end

-- Why not true or false? I want to make it clear that ignoring a vote and voting against are not the same thing
local player_votes = {
	-- value can be: "y", "n"
	-- uuid: "y"
}

local current_vote
local time_to_vote = 480
local voting_end_time

local function current_vote_result()
	local n = count_elements_in_table(api.get_data("clients_data"))
	local needed = math.floor(n/2) + 1
	if needed < 3 then
		needed = 3
	end
	local l = 0
	for k, v in pairs(player_votes) do
		if v == "y" then
			l = l + 1
		elseif v == "n" then
			l = l - 1
		end
	end
	return l, needed
end

local function check_vote()
	local l, needed = current_vote_result()
	if l >= needed then
		api.call_function("chat_message", "Vote passed! Start new game...", "system")
		next_game()
	end
end

local function show_current_vote_result()
	local l, needed = current_vote_result()
	api.call_function("chat_message", "Voted to start a new game: "..l.."/"..needed, "system")
	api.call_function("chat_message", "Time left for voting: : "..math.floor(voting_end_time - socket.gettime()).." seconds", "system")
end

local function vote(client, args)
	local uuid = api.get_data("clients_data")[client].uuid
	if not current_vote then
		api.call_function("chat_message", "Voting has not started yet", "error", true, client)
		return
	end
	if uuid and args[2] then
		if player_votes[uuid] then
			api.call_function("chat_message", "You have already voted", "error", true, client)
			return
		end
		if args[2] == "y" then
			player_votes[uuid] = "y"
			api.call_function("chat_message", "Player "..api.get_data("clients_data")[client].name.. " voted to start a new game ", "system")
			show_current_vote_result()
			check_vote()
		elseif args[2] == "n" then
			player_votes[uuid] = "n"
			api.call_function("chat_message", "Player "..api.get_data("clients_data")[client].name.. " Voted against starting a new game ", "system")
			show_current_vote_result()
			check_vote()
		end
	else
		api.call_function("chat_message", "Vote error. How to vote? If you want to start new game, write /vote y. "..
		"If you want to continue this game, write /vote n or ignore", "error", true, client)
	end
end

local function start_vote(client, args)
	local name = api.get_data("clients_data")[client].name
	if current_vote then
		api.call_function("chat_message", "Voting has already started ", "error", true, client)
	else
		current_vote = timer_module.after(time_to_vote, function()
			api.call_function("chat_message", "Vote passed!", "system")
			check_vote()
			current_vote = nil
			player_votes = {}
		end)
		voting_end_time = socket.gettime() + time_to_vote
		api.call_function("chat_message", "Player "..name.." started voting to start a new game.\nType /vote y to vote for start new game"..
			"\nType /vote n if you want continue this game", "system")
		vote(client, {"", "y"})
	end
end

function M.init(_api)
	api = _api
	current_vote = nil
	player_votes = {}

	api.register_command("/setscenario", set_scenario)
	api.register_command("/setmap", set_map)
	api.register_command("/nextgame", next_game)
	api.register_command("/scenarios", show_scenarios_list)
	api.register_command("/vote", vote)
	api.register_command("/rtr", start_vote)
end

function M.on_player_disconnected(client)
	if player_votes[client] then
		player_votes[client] = nil
		show_current_vote_result()
	end
end

function M.game_over(land, win)
	if win then 
		print("Game over: ", land, win)

		print("Check next map")
		if not next_map then
			local maps = {}
			for k, v in pairs(scenarios) do
				table.insert(maps, k)
			end
			next_map = lume.randomchoice(maps)
		end

		print("Check next scenario")
		if not next_scenario then
			local scenarios_list = {}
			for k, v in pairs(scenarios[next_map]) do
				table.insert(scenarios_list, k)
			end
			next_scenario = lume.randomchoice(scenarios_list)
		end

		print("Game data deepcopy")
		original_game_data = scenarios[next_map][next_scenario]
		game_data = deepcopy(original_game_data)
		modify_game_data(game_data.id)
		print("next map to nil")
		next_map = nil
		print("next scenario to nil")
		next_scenario = nil
		print("validate game data", game_data.id)
		validate_scenario.validate(game_data)
		print("load adjacency")
		if game_data.custom_map then
            load_adjacency(true, "maps/"..game_data.map.."/adjacency.dat")
        else
            load_adjacency()
        end

		api.start(true)
	end
end

return M