local M = {}

local map_package = require "scripts.map_package"

local function get_debug_root()
	return map_package.ensure_trailing_slash(debug_game_mode_file_path or "")
end

local function get_debug_path(relative_path)
	local path = map_package.normalize_path(relative_path or "")
	return get_debug_root() .. string.gsub(path, "^/+", "")
end

function M.get_game_file_path(relative_path)
	return get_debug_path(relative_path)
end

function M.find_exported_map_path()
	return map_package.find_map_package_path(get_debug_root())
end

function M.get_default_exported_map_path()
	return get_debug_root() .. "exported_map.map"
end

function M.load_exported_map_info()
	local path = M.find_exported_map_path()
	if not path then
		return nil, "Custom map package not found"
	end
	local data, err = map_package.read_json_section(path, "map_info")
	if not data then
		return nil, err
	end
	return data, path
end

function M.load_exported_scenario()
	local path = M.find_exported_map_path()
	if not path then
		return nil, "Custom map package not found"
	end
	local data, err = map_package.read_json_section(path, "generated_scenario")
	if not data then
		return nil, err
	end
	return data, path
end

function M.get_multiplayer_root()
	return get_debug_root() .. "multiplayer_maps/"
end

function M.ensure_multiplayer_root()
	return map_package.ensure_directory(M.get_multiplayer_root())
end

function M.build_multiplayer_map_path(map_hash)
	return M.get_multiplayer_root() .. tostring(map_hash) .. ".map"
end

function M.list_multiplayer_map_hashes()
	local root = M.get_multiplayer_root()
	local hashes = {}
	local attributes = lfs.attributes(map_package.normalize_path(root))
	if not attributes or attributes.mode ~= "directory" then
		return hashes
	end

	for entry in lfs.dir(map_package.normalize_path(root)) do
		if entry ~= "." and entry ~= ".." then
			local stem = entry:match("^(.*)%.map$")
			if stem then
				hashes[#hashes + 1] = stem
			end
		end
	end

	table.sort(hashes)
	return hashes
end

return M
