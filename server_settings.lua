local t = {
	server_info = {
		type = "server_info",
		data = {
			--Server name
			name = "[EN] [Standard] Official server #1",
			--Will be automatically changed
			players = 1,
			--Will be automatically filled
			server_ip = "",
			--Port through which the server will be available
			server_port = 5555,
			--Will be automatically changed
			size = 10
		}
	},
	--[[ This is the first number of the game version.
	Example: game version is 5.3, server version is 5, because
	client-server compatibility is determined by this number.
	Do not touch in order to allow players to join. Update the server.--]]
	SERVER_VERSION = 20,
	-- Maximum amount of time per turn. Seconds
	time_to_turn = 180,
	verify_uuid = true,
    minimum_played_time = 5*60, -- time in seconds that player must play in singleplayer mode to join this multiplayer server
	plugin = {
		welcome = [[Welcome to Official Server #1!
We ask you to be friendly towards other players.
If you have questions or want to chat about this game, feel free to join our server on Discord (Settings - Links)]],
		difficulty = "standard"
	}
}
return t
