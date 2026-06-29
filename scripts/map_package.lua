local M = {}

local json = require "scripts.utils.json"

local MAGIC = "CPMP"
local VERSION = 1
local PACKAGE_KIND = "cold_path_map"
local package_cache = {}

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

local function ensure_trailing_slash(path)
	local normalized = strip_trailing_slash(path)
	if normalized == "" then
		return ""
	end
	return normalized .. "/"
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
		if sys and sys.load_resource and (mode == nil or mode == "rb" or mode == "r") then
			local resource_path = normalize_path(path) or ""
			if resource_path:sub(1, 1) ~= "/" then
				resource_path = "/" .. resource_path
			end
			local ok, data = pcall(sys.load_resource, resource_path)
			if ok and data then
				return data
			end
		end
		return nil, "Error open file: " .. tostring(path)
	end

	local data = file:read("*a")
	file:close()
	return data
end

local function get_file_signature(path)
	if not lfs or not lfs.attributes then
		return nil
	end
	local normalized = normalize_path(path)
	local attributes = normalized and lfs.attributes(normalized) or nil
	if not attributes then
		return nil
	end
	return tostring(attributes.size or "") .. ":" .. tostring(attributes.modification or "")
end

local function write_file(path, data)
	local file = safe_open_file(path, "wb")
	if not file then
		return nil, "Error write file: " .. tostring(path)
	end

	file:write(data)
	file:close()
	return true
end

local function decode_u32(data, offset)
	local b1, b2, b3, b4 = string.byte(data, offset, offset + 3)
	if not b4 then
		return nil, nil, "Unexpected end of package header"
	end

	return (((b1 * 256) + b2) * 256 + b3) * 256 + b4, offset + 4
end

local function index_sections(manifest)
	local sections_by_id = {}
	for _, section in ipairs(manifest.sections or {}) do
		sections_by_id[section.id] = section
	end
	manifest.sections_by_id = sections_by_id
	return manifest
end

function M.is_package_path(path)
	local normalized = normalize_path(path) or ""
	return normalized:lower():match("%.map$") ~= nil
end

function M.is_package_bytes(data)
	return type(data) == "string" and data:sub(1, #MAGIC) == MAGIC
end

function M.read_package_bytes(data)
	if not M.is_package_bytes(data) then
		return nil, "Invalid map package magic"
	end

	local offset = #MAGIC + 1
	local version = string.byte(data, offset)
	if not version then
		return nil, "Invalid map package version"
	end
	offset = offset + 1

	local manifest_size, next_offset, err = decode_u32(data, offset)
	if not manifest_size then
		return nil, err
	end
	offset = next_offset

	local manifest_json = data:sub(offset, offset + manifest_size - 1)
	if #manifest_json ~= manifest_size then
		return nil, "Invalid map package manifest size"
	end
	offset = offset + manifest_size

	local ok, manifest = pcall(json.decode, manifest_json)
	if not ok or type(manifest) ~= "table" then
		return nil, "Invalid map package manifest"
	end

	if manifest.kind ~= PACKAGE_KIND then
		return nil, "Unsupported map package kind"
	end
	if manifest.version ~= version or version ~= VERSION then
		return nil, "Map package version mismatch"
	end

	manifest = index_sections(manifest)

	return {
		version = version,
		manifest = manifest,
		payload_offset = offset,
		bytes = data
	}
end

function M.read_package(path)
	local normalized_path = normalize_path(path) or path
	local signature = get_file_signature(normalized_path)
	local cacheable = signature ~= nil
	local cached = package_cache[normalized_path]
	if cacheable and cached and cached.signature == signature then
		return cached.package_data
	end

	local data, err = read_file(normalized_path, "rb")
	if not data then
		return nil, err
	end

	local package_data, package_err = M.read_package_bytes(data)
	if not package_data then
		return nil, package_err
	end

	package_data.path = normalized_path
	if cacheable then
		package_cache[normalized_path] = {
			signature = signature,
			package_data = package_data
		}
	end
	return package_data
end

function M.read_section(package_data, section_id)
	if type(package_data) ~= "table" or type(package_data.manifest) ~= "table" then
		return nil, nil, "Package data is required"
	end

	local section = package_data.manifest.sections_by_id and package_data.manifest.sections_by_id[section_id] or nil
	if not section then
		return nil, nil, "Missing section: " .. tostring(section_id)
	end

	local start_offset = package_data.payload_offset + section.offset
	local finish_offset = start_offset + section.size - 1
	local bytes = package_data.bytes:sub(start_offset, finish_offset)
	if #bytes ~= section.size then
		return nil, nil, "Invalid section size: " .. tostring(section_id)
	end

	return bytes, section
end

function M.read_section_bytes(path, section_id)
	local package_data, err = M.read_package(path)
	if not package_data then
		return nil, err
	end

	local bytes, _, section_err = M.read_section(package_data, section_id)
	if not bytes then
		return nil, section_err
	end

	return bytes
end

function M.read_json_section(path, section_id)
	local raw, err = M.read_section_bytes(path, section_id)
	if not raw then
		return nil, err
	end

	local ok, data = pcall(json.decode, raw)
	if not ok or type(data) ~= "table" then
		return nil, "Invalid JSON section: " .. tostring(section_id)
	end

	return data
end

function M.file_exists(path, mode)
	local file = safe_open_file(path, mode or "rb")
	if not file then
		return false
	end
	file:close()
	return true
end

function M.ensure_directory(path)
	local normalized = strip_trailing_slash(path)
	if normalized == "" then
		return true
	end

	local attributes = lfs.attributes(normalized)
	if attributes and attributes.mode == "directory" then
		return true
	end

	local parent = normalized:match("^(.*)/[^/]+$")
	if parent and parent ~= normalized then
		local ok, err = M.ensure_directory(parent)
		if not ok then
			return nil, err
		end
	end

	local ok, err = lfs.mkdir(normalized)
	if ok or lfs.attributes(normalized, "mode") == "directory" then
		return true
	end

	return nil, err or ("Error create directory: " .. tostring(normalized))
end

function M.find_map_package_path(root_path)
	local root = ensure_trailing_slash(root_path or "")
	local scan_root = root ~= "" and strip_trailing_slash(root) or "."
	local files = {}

	local attributes = lfs.attributes(scan_root)
	if not attributes or attributes.mode ~= "directory" then
		return nil
	end

	for entry in lfs.dir(scan_root) do
		if entry ~= "." and entry ~= ".." and entry:match("%.map$") then
			files[#files + 1] = entry
		end
	end

	if #files == 0 then
		return nil
	end

	table.sort(files, function(a, b)
		local a_name = a:lower()
		local b_name = b:lower()
		if a_name == "exported_map.map" then
			return true
		end
		if b_name == "exported_map.map" then
			return false
		end
		return a_name < b_name
	end)

	return root .. files[1]
end

function M.write_package_bytes(path, bytes)
	return write_file(path, bytes)
end

function M.normalize_path(path)
	return normalize_path(path)
end

function M.ensure_trailing_slash(path)
	return ensure_trailing_slash(path)
end

return M
