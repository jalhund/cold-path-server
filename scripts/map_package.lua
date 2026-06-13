local M = {}

local json = require "scripts.utils.json"

local MAGIC = "CPMP"
local VERSION = 1
local PACKAGE_KIND = "cold_path_map"

local function normalize_path(path)
	if not path then
		return nil
	end
	return string.gsub(path, "\\", "/")
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
	local data, err = read_file(path, "rb")
	if not data then
		return nil, err
	end

	local package_data, package_err = M.read_package_bytes(data)
	if not package_data then
		return nil, package_err
	end

	package_data.path = path
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

function M.normalize_path(path)
	return normalize_path(path)
end

return M
