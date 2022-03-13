local M = {}

--Per 100 provinces
local resources_chance = {
	gold = 40,
	uranium = 12,
}

-- Technology requirments:
local resources_requirments = {
	gold = {
		nil, "metallurgy_1", "metallurgy_2", "metallurgy_3"
	},
	uranium = {
		"uranium"
	}
}

--The larger the quantity, the less common
local resources_count_limits = {
	gold = {
		min = 2000,
		max = 29000
	},
	uranium = {
		min = 12,
		max = 70
	}
}

--types of count
local count_types = 16

local function generate_counts(table)
	local t = {}
	for i = 1, count_types do
		t[i] = math.random(i/count_types * (table.max - table.min)) + table.min
	end
	return t
end

local function fill_province(province, resource, resource_counts)
	if lume.random(0,100) < resources_chance[resource] then
		province.r[resource] = {
			count = lume.randomchoice(resource_counts),
			requirment = lume.randomchoice(resources_requirments[resource])
		}
	end
end

function M.fill(provinces)
	local gold_counts = generate_counts(resources_count_limits.gold)
	local uranium_counts = generate_counts(resources_count_limits.uranium)
	-- pprint("generated count for gold and uranium: ", gold_counts, uranium_counts)
	for k, v in pairs(provinces) do
		v.r = {}
		fill_province(v, "uranium", uranium_counts)
		if not v.r.uranium then
			fill_province(v, "gold", gold_counts)
		end
	end
end

return M