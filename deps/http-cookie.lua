exports.name = "zhaozg/http-cookie"
exports.version = "0.1.2"
exports.homepage = "https://github.com/zhaozg/luvit/blob/extend/deps/http-cookie.lua"
exports.description = "An adapter for build and parse http cookies."
exports.tags = {"http", "cookie", "adapter"}
exports.license = "MIT"
exports.author = { name = "zhaozg" }

local insert = table.insert
local concat = table.concat

local format = string.format
local gmatch = string.gmatch
local sub    = string.sub
local gsub   = string.gsub
local find   = string.find
local char	 = string.char

local function decode(str)
	local str = gsub(str, "+", " ")

	return (gsub(str, "%%(%x%x)", function(c)
			return char(tonumber(c, 16))
	end))
end

local function encode(str)
	return (gsub(str, "([^A-Za-z0-9%_%.%-%~])", function(v)
			return upper(format("%%%02x", byte(v)))
	end))
end

-- identity function
local function identity(val)
	return val
end

-- trim and remove double quotes
local function clean(str)
	  local s = gsub(str, "^%s*(.-)%s*$", "%1")

	  if sub(s, 1, 1) == '"' then
		  s = sub(s, 2, -2)
	  end

	  return s
end

-- given a unix timestamp, return a utc string
local function to_utc_string(time)
	return os.date("%a, %d %b %Y %H:%I:%S GMT", time)
end

local CODEX = {
	{"max_age", "Max-Age=%d", identity},
	{"domain", "Domain=%s", identity},
	{"path", "Path=%s", identity},
	{"expires", "Expires=%s", to_utc_string},
	{"http_only", "HttpOnly", identity},
	{"secure", "Secure", identity},
}

local function build(dict, options)
	options = options or {}

	local res = {}

	for k, v in pairs(dict) do
		insert(res, format("%s=%s", k, encode(v)))
	end

	for _, tuple in ipairs(CODEX) do
		local key, template, fn = unpack(tuple)
		local val = options[key]

		if val then
			insert(res, format(template, fn(val)))
		end
	end

	return concat(res, "; ")
end

local function parse(data)
	local res = {}

	for pair in gmatch(data, "[^;]+") do
		local eq = find(pair, "=")

		if eq then
			local key = clean(sub(pair, 1, eq-1))
			local val = clean(sub(pair, eq+1))

			if not res[key] then
				res[key] = decode(val)
			end
		end
	end

	return res
end

exports.build = build
exports.parse = parse
