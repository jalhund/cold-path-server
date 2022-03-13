-- defeated - Civilization does not exist
local M = {}

local fill_resources = require "scripts.utils.fill_resources"

local min_population = 20000
local max_population = 60000

M.water_provinces = {
	europe = {
		"adriatic_sea",
		"aegean_sea",
		"algerian_basin",
		"antalya_basin",
		"balearic_sea",
		"baltic_sea",
		"barents_sea",
		"black_sea_east",
		"black_sea_north",
		"black_sea_west",
		"celtic_sea",
		"denmark_strait",
		"english_channel",
		"greenland_sea",
		"gulf_of_bothnia",
		"gulf_of_finland",
		"gulf_of_riga",
		"hellenic_trench",
		"herodotus_basin",
		"iberian_basin",
		"iceland_basin",
		"ionian_sea",
		"kattegat",
		"ligure_sea",
		"mirtoan_sea",
		"north_sea",
		"norwegian_sea",
		"rockall_basin",
		"sardino_balearic_plain",
		"sea_of_azov",
		"sea_of_crete",
		"sea_of_marmara",
		"strait_of_sicilia",
		"tagus_basin",
		"tyrrhenian_sea",
		"west_european_basin",
		"western_basin",
		"white_sea"
	},
	america = {
		"antofagasta_water",
		"atlantic_water",
		"baffin_west_water",
		"bahamas_water",
		"barbados_water",
		"belem_water",
		"bermuda",
		"bylot_west_water",
		"caribbean_sea",
		"cayman_water",
		"center_atlantic_water",
		"center_pacific_ocean",
		"chukchi_sea",
		"devil_water",
		"east_pacific_ocean",
		"east_south_pacific_ocean",
		"east_southern_pacific_ocean",
		"falkland_water",
		"gulf_of_alaska",
		"gulf_of_california",
		"gulf_of_mexico",
		"gulf_of_saint_lawrence",
		"hudson_bay",
		"labrador_sea",
		"melville_water",
		"montevideo_water",
		"north_alaska_water",
		"north_iceland_water",
		"north_labrador_sea",
		"north_pacific_ocean",
		"northwest_passage",
		"panama_water",
		"paulatuk_water",
		"piura_water",
		"prince_of_wales_water",
		"ringnes_water",
		"rio_de_janeiro_water",
		"salvador_water",
		"san_julian_water",
		"san_salvador_water",
		"south_atlantic_water",
		"south_georgia_water",
		"south_labrador_sea",
		"south_pacific_ocean",
		"southern_atlantic_water",
		"temuco_water",
		"tortel_water",
		"turks_and_caicos_water",
		"west_atlantic_water",
		"west_california_water",
		"west_mexico_water"
	},
	lp_16 = {
		"2",
		"3",
		"4",
		"5",
		"6",
		"8",
		"14",
		"49",
		"74",
		"81",
		"94",
		"102",
		"130",
		"165",
		"174",
		"187",
		"191",
		"203",
		"213",
		"220",
		"241",
		"266",
		"273",
		"286",
		"293",
	},
	pvp = {
	  	"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"10",
		"11",
		"12",
		"13",
		"14",
		"37",
		"38",
		"55",
		"68",
		"69",
		"118",
		"125",
		"126",
		"139",
		"142",
		"157",
		"158",
		"164",
		"165",
		"169",
		"170",
		"191",
		"192",
		"199",
		"200",
		"217",
		"218",
		"219",
		"233",
		"234",
		"235",
		"236",
		"237",
		"238",
		"246",
		"247",
		"248",
		"249",
		"250",
		"251",
		"252",
		"253",
		"254",
		"255",
		"256",
		"257",
		"262",
		"263",
		"275",
		"276",
		"277",
		"278",
		"279",
		"280",
		"283",
		"302",
		"303",
		"314",
		"315",
		"318",
		"319",
		"342",
		"345",
		"360",
		"373",
		"374",
		"390",
		"391",
		"407",
		"444",
		"445",
		"466",
		"467",
		"468",
		"481",
		"482",
		"485",
		"486",
		"489",
		"490",
		"491",
	}
}

local land_types = {
	"noble",
	"practical",
	"aggressive"
}

local causes_of_warming = {
	"core",
	"solar",
	"greenhouse",
}

function M.validate(t)
	if M.water_provinces[t.map] then
		for k, v in pairs(M.water_provinces[t.map]) do
			t.provinces[v] = {
				water = true
			}
		end
	end

	if t.id == "consequences" then
		t.cause_of_warming = lume.randomchoice(causes_of_warming)
	end

	if not t.difficulty then
		t.difficulty = "standard"
	end

	t.step = 0
	t.queue = {}
	t.fog_of_war = "standard"
	t.current_moves = {}
	-- t.previous_moves = {}
	t.current_shell = {}
	t.previous_shell = {}
	t.current_tank = {}
	t.previous_tank = {}
	t.current_planes = {}
	t.previous_planes = {
		-- {
		-- 	"kiev", "bryansk", "success", "lipetsk", "Russia"
		-- }
	}
	t.current_chemical = {}
	t.previous_chemical = {
		-- {
		-- 	"kiev", "bryansk", "Russia"
		-- }
	}
	t.current_explosions = {}
	t.previous_explosions = {
		-- {
		-- 	type, province, from
		-- }
	}

	t.used_shell = {}
	t.used_tank = {}
	t.used_chemical = {}
	t.used_explosions = {}
	t.used_planes = {}

	if not t.pacts_data then
		t.pacts_data = {}
	end
	t.old_offers = {}
	t.new_offers = {
		-- {
		-- 	1, "peace", "England", "Russia"
		-- },
		-- {
		-- 	2, "pact", "England", "Russia"
		-- },
		-- {
		-- 	3, "war", "England", "Russia"
		-- }
	}
	t.accepted_offers = {}

	t.trade = {
		-- {
		-- 	"per_turn", "England", "Russia", 256
		-- }
	}

	t.nuclear_reactors_cooling = {
		-- moscow = 12
	}

	t.consequence_data = {}

	t.dissolved_army_for_gold = {}

	for k, v in pairs(t.lands) do
		v.ideology = "republic"
		v.changed_ideology = -50
		v.declared_war = nil
		v.war_weariness = 0
		v.army = 0
		v.population = 0
		v.num_of_provinces = 0
		v.money = v.money or 0
		v.economy = {
			income = {
				population = 0,
				technology = 0,
				skills = 0,
				buildings = 0,
				trade = 0,
				vassality = 0
			},
			expense = {
				army = 0,
				buildings = 0,
				trade = 0,
				vassality = 0
			},
			inflation = 0,
			income_total = 0,
			expense_total = 0,
			balance = 0,
		}
		v.science_per_turn = {
			base = 0,
			buildings = 0,
			technology = 0,
			skills = 0
		}
		v.total_science_per_turn = 0
		v.science = 0
		v.skills = 0
		v.movement_points = 0
		v.total_movement_points = 0
		v.tax = 0.1
		v.selected_technology = nil
		v.bonuses = {
			{"building_megarefrigerator"},
			{"building_machine_a"},
			{"building_machine_b"},
			{"building_machine_c"},
		}
		v.opened_technology = {}
		if k ~= "Undeveloped_land" and t.technology_lvl and t.technology_lvl ~= 0 then
			for key, val in pairs(technology_data) do
				local lvl, n = key:match("t_(%d+)_(%d)")
				-- print("lvl: ", k, lvl, n, t.technology_lvl)
				if tonumber(lvl) <= t.technology_lvl then
					table.insert(v.opened_technology, key)
					for key_, val_ in pairs(val.bonuses) do
						if not val_[2] then
							val_[2] = 0
						end
						val_[3] = "technology"
						table.insert(v.bonuses, val_)
					end
				end
			end
		end
		v.opened_skills = {}
		if not v.allies then
			v.allies = {}
		end
		if not v.pacts then
			v.pacts = {}
		end
		if not v.enemies then
			v.enemies = {}
		end
		if not find_in_table("Undeveloped_land", v.enemies) then
			table.insert(v.enemies, "Undeveloped_land")
		end
		v.betrayals_list = {}
		-- v.history = {
		-- 	money = {},
		-- 	income = {},
		-- 	expense = {},
		-- 	total_science_per_turn = {},
		-- 	army = {},
		-- 	resources = {}
		-- }
		v.resources = {
			gold = 0,
			uranium = 0,
			heavy_water = 0,
			weapons = 0,
			chemical_weapon = 0,
			tank = 0
		}
		v.ai = {
			strategy = {
				strategy_type = "development",
				target = nil,
				wish = {},
				turns = 0,
			},
			land_type = lume.randomchoice(land_types),
		}
		v.last_attacked = k
		v.stability = 100

		-- { land, money, step }
		v.rebellion_support = {}
		-- { action, step }
		v.actions_taken = {}
	end

	for k, v in pairs(t.lands) do
		table.insert(game_data.lands.Undeveloped_land.enemies, k)
	end

	-- a - army, o - owner, l_a - recruited_army, b - buildings, p - population, t_o = true owner, s - stability
	for k, v in pairs(t.provinces) do
		v.a = {}
		if not v.water then
			v.a[v.o] = 0 --math.floor(lume.random(10, 200))
			v.l_a = 0
			if not v.b then
				v.b = {
					-- megarefrigerator = 1
					-- machine_a = 1,
					-- machine_b = 1,
					-- machine_c = 1
					-- mine = lvl
				}
			end
			-- v.t_o = v.o
			if v.o == "Undeveloped_land" then
				v.p = 0
				v.a.Undeveloped_land = 500
			else
				v.p = math.floor(lume.random(min_population, max_population))
			end
		end
	end

	fill_resources.fill(t.provinces)

end

return M