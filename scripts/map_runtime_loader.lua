local M = {}

local json = require "scripts.utils.json"
local map_package = require "scripts.map_package"
local custom_map_storage = require "scripts.custom_map_storage"

local BUILTIN_ADJACENCY_PATHS = {
	europe = "assets/adjacency_map_europe.dat",
	america = "assets/adjacency_map_america.dat",
	lp_16 = "assets/adjacency_map_lp_16.dat",
	pvp = "assets/adjacency_map_pvp.dat",
	europeamerica = "assets/adjacency_map_europeamerica.dat",
	europe_remastered = "assets/adjacency_map_europe_remastered.dat"
}

local function normalize_path(path)
	if not path then
		return nil
	end
	local normalized = string.gsub(path, "\\", "/")
	return normalized
end

local function strip_trailing_slash(path)
	local normalized = normalize_path(path) or ""
	if normalized == "" or normalized == "/" then
		return normalized
	end
	local stripped = string.gsub(normalized, "/+$", "")
	return stripped
end

local function join_path(...)
	local parts = { ... }
	local result = ""

	for _, part in ipairs(parts) do
		if part and part ~= "" then
			local normalized = normalize_path(part)
			if result == "" then
				result = normalized
			else
				result = strip_trailing_slash(result) .. "/" .. string.gsub(normalized, "^/+", "")
			end
		end
	end

	return result
end

local function safe_open_file(path, mode)
	local file = io.open(path, mode)
	if file then
		return file
	end

	local normalized = string.gsub(path, "/", "\\")
	file = io.open(normalized, mode)
	if file then
		return file
	end

	normalized = string.gsub(path, "\\", "/")
	return io.open(normalized, mode)
end

local function read_file(path, mode)
	local file = safe_open_file(path, mode or "rb")
	if not file then
		return nil, "Error open file: " .. tostring(path)
	end

	local data = file:read("*a")
	file:close()
	return data
end

local function read_bundled_resource(path)
	local ok, data_or_err = pcall(sys.load_resource, "/" .. tostring(path))
	if not ok or not data_or_err then
		return nil, data_or_err or ("Cannot load resource: " .. tostring(path))
	end
	return data_or_err
end

function M.read_section_bytes(root_path, section_id)
	if type(root_path) ~= "string" or root_path == "" then
		return nil, "Map root path is missing"
	end

	if not map_package.is_package_path(root_path) then
		return nil, "Only .map packages are supported: " .. tostring(root_path)
	end

	return map_package.read_section_bytes(root_path, section_id)
end

function M.read_json_section(root_path, section_id)
	local raw, err = M.read_section_bytes(root_path, section_id)
	if not raw then
		return nil, err
	end

	local ok, data = pcall(json.decode, raw)
	if not ok or type(data) ~= "table" then
		return nil, "Invalid JSON section: " .. tostring(section_id)
	end

	return data
end

function M.load_runtime_adjacency_text(options)
	local resolved_options = options or {}
	local game_map = resolved_options.game_map
	local debug_mode = resolved_options.debug_mode
	local console_mode = resolved_options.console_mode
	local custom_map_enabled = resolved_options.custom_map_enabled
	local custom_path = resolved_options.custom_path

	local bundled_path = BUILTIN_ADJACENCY_PATHS[game_map]
	if bundled_path then
		if console_mode or debug_mode then
			local data, err = read_file(bundled_path, "rb")
			return data, err, bundled_path
		end

		local data, err = read_bundled_resource(bundled_path)
		return data, err, bundled_path
	end

	local map_root = custom_path
	if (not map_root or map_root == "") and custom_map_enabled and type(custom_map_path) == "string" then
		map_root = custom_map_path
	end
	if (not map_root or map_root == "") and console_mode and type(game_map) == "string" and game_map ~= "" then
		map_root = custom_map_storage.get_game_file_path(join_path("maps", game_map .. ".map"))
	end

	if map_root and map_root ~= "" then
		local data, err = M.read_section_bytes(map_root, "adjacency")
		local display_path = tostring(map_root)
		if map_package.is_package_path(display_path) then
			display_path = display_path .. "#adjacency"
		end
		return data, err, display_path
	end

	return nil, "Custom map adjacency path is missing"
end

return M
