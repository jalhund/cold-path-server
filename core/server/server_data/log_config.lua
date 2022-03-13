-- Detailed description of the config in the logger module

local t = {
	standard = {
		show = true,
	},
	chat = {
		show = true,
		file = true
	},
	plugin = {
		show = true,
		-- file = true,
	},
	players = {
		show = true,
		file = true
	},
	error = {
		show = true,
		file = true,
		export_game_data = true,
		traceback = true
	}
}

return t