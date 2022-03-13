-- debug plugin
-- TODO: finish debug plugin
local M = {}

local api

local function set_st(client, args)
    local t = {
        type = "server_text",
        data = {
            text = join(args, " ", 2)
        }
    }
    api.send_data(to_json(t), client)
end

function M.init(_api)
	api = _api
	-- Example of using server_text
	--api.register_command("/set_st", set_st)
end

function M.on_player_joined(client)
	local t = {
        type = "enable_selected_province_tracking",
        data = {}
    }
    -- turn on to enable selected province tracking
    --api.send_data(to_json(t), client)
end

function M.on_data(data, ip, port, client)
	if data.type == "tracked_province" then
		local t = {
            type = "server_text",
            data = {
                text = "Selected province: "..data.data.province
            }
        }
        api.send_data(to_json(t), client)
	end
end

return M