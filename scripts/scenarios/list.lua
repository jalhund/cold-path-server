local t = {
	europe = {
		millenium = {
			order = 1,
			data = require "scripts.scenarios.europe.millenium"
		},
		great_northern_war = {
			order = 2,
			data = require "scripts.scenarios.europe.great_northern_war"
		},
		crimean_war = {
			order = 3,
			data = require "scripts.scenarios.europe.crimean_war",
		},
		wwi = {
			order = 4,
			data = require "scripts.scenarios.europe.wwi",
		},
		modern_world = {
			order = 5,
			data = require "scripts.scenarios.europe.modern_world",
		},
		consequences = {
			order = 6,
			data = require "scripts.scenarios.europe.consequences",
		},
		anarchy = {
			order = 7,
			data = require "scripts.scenarios.europe.anarchy",
		},
		-- millenium_copy = {
		-- 	require "scripts.scenarios.europe.millenium_copy",
		-- },
	},
	america = {
		modern_world = {
			order = 1,
			data = require "scripts.scenarios.america.modern_world"
		},
	},
	lp_16 = {
		lost = {
			order = 1,
			data = require "scripts.scenarios.lp_16.lost"
		},
	},
	pvp = {
		pvp_20 = {
			order = 1,
			data = require "scripts.scenarios.pvp.pvp_20"
		},
		pvp_20_with_watcher = {
			order = 2,
			data = require "scripts.scenarios.pvp.pvp_20_with_watcher"
		},
	}
}

return t