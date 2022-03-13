local M = {}

local relations = require "core.relations"

M.blocked_recruit = true
M.blocked_diplomacy = true
M.only_move = true

local function clear_war_data(land)
	if game_data.lands[land].enemies then
		for i = #game_data.lands[land].enemies, 1, -1 do
			remove_from_table(land, game_data.lands[game_data.lands[land].enemies[i]].enemies)
			table.remove(game_data.lands[land].enemies, i)
		end
	end
end

function M.blocked_civilization(id)
	return id ~= "Civilization"
end

function M.init()
	if game_data.step == 0 then
		game_data.lost_state = 1
		for k, v in pairs(game_data.provinces) do
			if not v.water and v.o == game_data.player_land then
				v.p = 0
				v.a[game_data.player_land] = 10000
			end
		end
		table.insert(game_data.lands[game_data.player_land].bonuses, {"army_attack", 6.5})
		table.insert(game_data.lands[game_data.player_land].bonuses, {"army_defense", 11})
		table.insert(game_data.lands.Rebels.bonuses, {"army_attack", 6.5})
		table.insert(game_data.lands.Rebels.bonuses, {"army_defense", 11})
		for k, v in pairs(game_data.lands) do
			if k ~= game_data.player_land and k ~= "Undeveloped_land" then
				relations.register_war(game_data.player_land, k)
				v.bonuses = {}
				v.opened_technology = {}
			end
		end
	end
end

local states = {
	[1] = function()
		if game_data.provinces["44"].o == game_data.player_land then
			table.insert(game_data.old_offers, {
				#game_data.old_offers + 1, "lost_messages", "system", game_data.player_land, "conquered_proton"
			})
			game_data.lost_state = game_data.lost_state + 1
		end
	end,
	[2] = function()
		if game_data.lands.Civilization.resources.uranium >= 25 then
			table.insert(game_data.old_offers, {
				#game_data.old_offers + 1, "lost_messages", "system", game_data.player_land, "uranium_mined"
			})
			game_data.lands.Civilization.resources.uranium = game_data.lands.Civilization.resources.uranium - 25
			game_data.lost_state = game_data.lost_state + 1
		end
	end,
	[3] = function()
		if game_data.provinces["44"].o == game_data.player_land then
			table.insert(game_data.old_offers, {
				#game_data.old_offers + 1, "lost_messages", "system", game_data.player_land, "conquered_proton2"
			})
			game_data.lost_state = game_data.lost_state + 1
		end
	end,
	[4] = function()
		if game_data.step > 20 then
			table.insert(game_data.old_offers, {
				#game_data.old_offers + 1, "lost_messages", "system", game_data.player_land, "wait1"
			})
			game_data.lost_state = game_data.lost_state + 1
		end
	end,
	[5] = function()
		game_data.lost_state = game_data.lost_state + 1
	end,
	[6] = function()
		game_data.lost_state = game_data.lost_state + 1
	end,
	[7] = function()
		table.insert(game_data.old_offers, {
			#game_data.old_offers + 1, "lost_messages", "system", game_data.player_land, "wait2"
		})
		local p
		for _, v in rpairs(get_adjacency("44")) do
			for _, val in rpairs(get_adjacency(v)) do
				if not game_data.provinces[val].water and val ~= "44" then
					p = val
				end
			end
		end
		game_data.provinces[p].o = "Rebels"
		game_data.lands.Rebels.defeated = false
		local rebels_count = math.floor(lume.random(game_data.lands.Civilization.army*0.25,
				game_data.lands.Civilization.army*0.5))
		local n = 0
		for k, v in rpairs(game_data.provinces) do
			if v.a.Civilization and v.a.Civilization > 0 then
				local l = v.a.Civilization
				if l > rebels_count - n then
					l = rebels_count - n
				end
				n = n + l
				v.a.Civilization = v.a.Civilization - l
				if n == rebels_count then
					break
				end
			end
		end
		game_data.provinces[p].a = {
			Rebels = rebels_count
		}
		game_data.lost_state = game_data.lost_state + 1
	end,
	[8] = function()
		game_data.lost_state = game_data.lost_state + 1
	end,
	[9] = function()
		game_data.lost_state = game_data.lost_state + 1
	end,
	[10] = function()
		if game_data.lands.Rebels.defeated then
			table.insert(game_data.old_offers, {
				#game_data.old_offers + 1, "lost_messages", "system", game_data.player_land, "wait3"
			})
			game_data.lost_state = game_data.lost_state + 1
		end
	end,
	[11] = function()
		game_data.lost_state = game_data.lost_state + 1
	end,
	[12] = function()
		game_data.lost_state = game_data.lost_state + 1
	end,
	[13] = function()
		table.insert(game_data.old_offers, {
			#game_data.old_offers + 1, "lost_messages", "system", game_data.player_land, "wait4"
		})
		game_data.lost_state = game_data.lost_state + 1
	end,
	[14] = function()
		game_data.lost_state = game_data.lost_state + 1
	end,
	[15] = function()
		game_data.lost_state = game_data.lost_state + 1
	end,
	[16] = function()
		table.insert(game_data.old_offers, {
			#game_data.old_offers + 1, "lost_messages", "system", game_data.player_land, "wait5"
		})
		game_data.lost_state = game_data.lost_state + 1
	end,
	[17] = function(game_end_callback)
		game_end_callback(game_data.player_land, true, true)
	end
}

function M.calc(game_end_callback)
	for k, v in pairs(game_data.provinces) do
		if not v.water and (v.o == game_data.player_land or v.o == "Rebels") then
			v.p = 0
		end
	end
	game_data.lands[game_data.player_land].money = 100000
	game_data.lands.Rebels.money = 100000

	local steps = {
		[0] = "intro",
		[1] = "intro2",
		[2] = "intro3",
		--[5] = "wait1",
		--[6] = "wait2",
		--[7] = "wait3",
		--[8] = "wait4",
		--[9] = "wait5",
	}
	if steps[game_data.step] then
		for k, v in pairs(game_data.lands) do
			if k ~= "Undeveloped_land" and not v.defeated then
				table.insert(game_data.old_offers, {
					#game_data.old_offers + 1, "lost_messages", "system", k, steps[game_data.step]
				})
			end
		end
	end

	if not game_data.lands.Rebels.defeated then
		clear_war_data("Rebels")
		for k, v in pairs(game_data.provinces) do
			if not v.water and v.o == "Rebels" then
				for key, val in pairs(get_adjacency(k)) do
					if not game_data.provinces[val].water then
						table.insert(game_data.lands.Rebels.enemies, game_data.provinces[val].o)
						table.insert(game_data.lands[game_data.provinces[val].o].enemies, "Rebels")
					end
				end
			end
		end
		if not find_in_table("Rebels", game_data.lands[game_data.player_land].enemies) then
			table.insert(game_data.lands.Rebels.enemies, game_data.player_land)
			table.insert(game_data.lands[game_data.player_land].enemies, "Rebels")
		end
	end

	if states[game_data.lost_state] then
		states[game_data.lost_state](game_end_callback)
	end
end

return M