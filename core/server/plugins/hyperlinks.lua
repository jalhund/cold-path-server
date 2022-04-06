-- hyperlinks
local M = {}

local timer_module = require "core.timer"

local api

-- List of hyperlinks. Format
-- <unique string>: <link>
local list = {
    discord = "https://discord.gg/CrCXVkV",
    vk = "https://vk.com/coldpathgame",
    guides_en = "https://book.denismakhortov.com/",
    guides_ru = "https://book.denismakhortov.com/v/ru/",
}

-- Messages displayed in chat
local messages = {
    "Join to official Discord server. There are active community and a lot of useful information. </color><color=lightblue><a=discord>Click here to join</a></color>",
    "Join to official russian VK group to view all game news. </color><color=lightblue><a=vk>Click here to join</a></color>",
    "Book of Cold Path is collection of detailed guides and useful information about game. </color><color=lightblue><a=guides_en>Click here</a></color> to open EN version. </color><color=lightblue><a=guides_ru>Click here</a></color> to open RU version",
}

local function send_message()
    api.call_function("chat_message", lume.randomchoice(messages))
end

function M.init(_api)
	api = _api
end

local is_first = true

function M.on_player_joined(client)
    -- Because this function does not work in init function. Why???
    if is_first then
        timer_module.every(10, send_message)
        is_first = false
    end
	local t = {
        type = "hyperlinks",
        data = {
            list = list
        }
    }
    api.send_data(to_json(t), client)
end

return M