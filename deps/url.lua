--[[

Copyright 2015 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]
--[[lit-meta
  name = "luvit/url"
  version = "2.0.0"
  dependencies = {
    "luvit/querystring@2.0.0",
  }
  license = "Apache 2"
  homepage = "https://github.com/luvit/luvit/blob/master/deps/url.lua"
  description = "Node-style url codec for luvit"
  tags = {"luvit", "url", "codec"}
]]

local querystring = require('querystring')

local URL = {}

local function encodeAuth(str)
  if str then
    str = string.gsub(str, '\n', '\r\n')
    str = string.gsub(str, '([^%w:!-.~\'()*])', function(c)
      return string.format('%%%02X', string.byte(c))
    end)
  end
  return str
end

-- add the prefix if it doesnt already exist
local function conditionallyPrefix(str, prefix)
  if str and str ~= "" and string.sub(str, 1, #prefix) ~= prefix then
    str = prefix .. str
  end
  return str
end

-- add the suffix if it doesnt already exist
local function conditionallySuffix(str, suffix)
  if str and str ~= "" and string.sub(str, -(#suffix)) ~= suffix then
    str = str .. suffix
  end
  return str
end

local function parse(url, parseQueryString)
  local href = url
  local chunk, protocol = url:match("^(([a-z0-9+]+)://)")
  url = url:sub((chunk and #chunk or 0) + 1)

  local auth
  chunk, auth = url:match('(([0-9a-zA-Z]+:?[0-9a-zA-Z]+)@)')
  url = url:sub((chunk and #chunk or 0) + 1)

  local host
  local hostname
  local port
  if protocol then
    host = url:match("^([%a%.%d-]+:?%d*)")
    if host then
      hostname = host:match("^([^:/]+)")
      port = host:match(":(%d+)$")
    end
  url = url:sub((host and #host or 0) + 1)
  end

  local path
  local pathname
  local search
  local query
  local hash
  hash = url:match("(#.*)$")
  url = url:sub(1, (#url - (hash and #hash or 0)))

  if url ~= '' then
    path = url
    local temp
    temp = url:match("^[^?]*")
    if temp ~= '' then
      pathname = temp
    end
    temp = url:sub((pathname and #pathname or 0) + 1)
    if temp ~= '' then
      search = temp
    end
    if search then
    temp = search:sub(2)
      if temp ~= '' then
        query = temp
      end
    end
  end

  if parseQueryString then
    query = querystring.parse(query)
  end

  local parsed = {
    protocol = protocol,
    host = host,
    hostname = hostname,
    port = port,
    path = path or '/',
    pathname = pathname or '/',
    search = search,
    query = query,
    auth = auth,
    hash = hash
  }
  parsed.href = URL.format(parsed)

  return parsed
end

local function format(parsed)
  local auth = parsed.auth or ""
  if auth ~= "" then
    auth = encodeAuth(auth)
    auth = auth .. '@'
  end

  local protocol = parsed.protocol or ""
  local pathname = parsed.pathname or ""
  local hash = parsed.hash or ""
  local host = false
  local query = ""
  local port = parsed.port

  if parsed.host and parsed.host ~= "" then
    host = auth .. parsed.host
  elseif parsed.hostname and parsed.hostname ~= "" then
    host = auth .. parsed.hostname
    if port then
      host = host .. ':' .. port
    end
  end

  if parsed.query and type(parsed.query) == "table" then
    query = querystring.stringify(parsed.query)
  end

  local search = parsed.search or (query ~= "" and ('?' .. query)) or ""

  protocol = conditionallySuffix(protocol, ':')

  -- urlencode # and ? characters only
  pathname = string.gsub(pathname, '([?#])', function(c)
    return string.format('%%%02X', byte(c))
  end)

  -- add slashes
  if host then
    host = '//' .. host
    pathname = conditionallyPrefix(pathname, '/')
  else
    host = ""
  end

  search = string.gsub(search, '#', '%23')
  hash = conditionallyPrefix(hash, '#')
  search = conditionallyPrefix(search, '?')

  return protocol .. host .. pathname .. search .. hash
end

URL.parse = parse
URL.format = format

return URL
