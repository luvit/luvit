--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

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


-- querystring helpers
local querystring = {}

local table = require('table')
local string = require('string')
local find = string.find
local gsub = string.gsub
local char = string.char
local byte = string.byte
local format = string.format
local match = string.match
local gmatch = string.gmatch

function querystring.urldecode(str)
  str = gsub(str, '+', ' ')
  str = gsub(str, '%%(%x%x)', function(h)
    return char(tonumber(h, 16))
  end)
  str = gsub(str, '\r\n', '\n')
  return str
end
querystring.urldecodecomponent = querystring.urldecode

function querystring.urlencode(str)
  if str then
    str = gsub(str, '\n', '\r\n')
    str = gsub(str, '([^%w ])', function(c)
      return format('%%%02X', byte(c))
    end)
    str = gsub(str, ' ', '+')
  end
  return str
end

function querystring.urlencodecomponent(str)
  if str then
    str = gsub(str, '\n', '\r\n')
    str = gsub(str, '([^%w])', function(c)
      return format('%%%02X', byte(c))
    end)
  end
  return str
end

-- parse querystring into table. urldecode tokens
function querystring.parse(str, sep, eq)
  if not sep then sep = '&' end
  if not eq then eq = '=' end
  local vars = {}
  for pair in gmatch(tostring(str), '[^' .. sep .. ']+') do
    if not find(pair, eq) then
      vars[querystring.urldecode(pair)] = ''
    else
      local key, value = match(pair, '([^' .. eq .. ']*)' .. eq .. '(.*)')
      if key then
        vars[querystring.urldecode(key)] = querystring.urldecode(value)
      end
    end
  end
  return vars
end

-- Create a querystring from the given table.
function querystring.stringify(params, sep, eq)
  if not params then
    return ''
  end

  sep = sep or '&'
  eq = eq or '='
  local ret = {}
  local vtype = nil -- string
  local count = 0
  local skey = nil -- string

  for key, val in pairs(params) do
    vtype = type(val)
    skey = querystring.urlencodecomponent(key, sep, eq)

    -- only use numeric keys for table values
    if 'table' == vtype then
      for i, v in ipairs(val) do
        count = count + 1
        table.insert(ret, table.concat({skey, querystring.urlencodecomponent(v, sep, eq)}, eq))
      end

      if 0 == count then
        table.insert(ret, table.concat({skey, ''}, eq))
      end

      count = 0
    else
      if 'string' ~= vtype then
        val = tostring(val)
      end

      val = querystring.urlencodecomponent(val)
      table.insert(ret, table.concat({skey, val}, eq))
    end
  end

  if 0 == #ret then
    return ''
  end

  return table.concat(ret, sep)
end

-- module
return querystring
