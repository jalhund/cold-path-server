local M = {}

local inspect = require "scripts.utils.inspect"

local mode = "standard" -- ignore, silent, standard (ignore - print nothing, silent - do not write to file)

local config = {
    -- Standard config
    standard = {
        -- Print messages
        show = true,
        -- Save messages to standalone file
        file = false,
        -- Save game data to file
        export_game_data = false,
        -- Print traceback
        traceback = false
    }
}

function M.set_mode(new_mode)
    mode = new_mode
end

function M.set_config(new_config)
    if new_config then
        config = new_config
        if not config.standard then
            config.standard = {
                show = true
            }
        end
    end
end

function M.log(...)
    if mode == "ignore" then
        return
    end
    local arg = {...}
    local message_type = "standard"
    if type(arg[1]) == "string" and config[arg[1]] then
        message_type = arg[1]
        table.remove(arg, 1)
    end
    local short_src = debug.getinfo(2).short_src
    local line = debug.getinfo(2).currentline
    if config[message_type].show then
        local text = "["..message_type.."]: "..short_src..":"..line
        for i, v in ipairs(arg) do
            text = text.." "..inspect(v)
        end

        if config[message_type].traceback then
            text = text..debug.traceback()
        end
        print(text)
    end
    if config[message_type].file and mode == "standard" then
        local file = io.open(message_type..".dat", "a")
        if file then
            local text = "["..os.date("%c").."] |"..short_src..":"..line.."|"
            for i, v in ipairs(arg) do
                text = text.." "..inspect(v)
            end

            if config[message_type].traceback then
                text = text.."\n"..debug.traceback()
            end
            file:write(text.."\n")
            file:close()
        else
            print("File creation error: ", message_type)
        end
    end
    if config[message_type].export_game_data and mode == "standard" then
        local file = io.open("game_data.json", "w")
        if file then
            file:write(to_json_without_break(game_data))
            file:close()
        else
            print("Game data file creation error: ", message_type)
        end
    end
end

return M