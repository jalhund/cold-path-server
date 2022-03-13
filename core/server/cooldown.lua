-- To prevent too frequent connections to the server
local M = {}

local t = {}

local interval = 0.4

function M.connect(ip)
    if socket.gettime() - (t[ip] or socket.gettime() + interval + 1) > interval then
        t[ip] = socket.gettime()
        return true
    else
        t[ip] = socket.gettime()
        return false
    end
end

return M