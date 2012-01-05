--
-- querystring helpers
--

local String = require('string')
local find = String.find
local gsub = String.gsub
local char = String.char
local byte = String.byte
local format = String.format
local match = String.match
local gmatch = String.gmatch

local function urldecode(str)
  str = gsub(str, '+', ' ')
  str = gsub(str, '%%(%x%x)', function(h)
    return char(tonumber(h, 16))
  end)
  str = gsub(str, '\r\n', '\n')
  return str
end

local function urlencode(str)
  if str then
    str = gsub(str, '\n', '\r\n')
    str = gsub(str, '([^%w ])', function(c)
      return format('%%%02X', byte(c))
    end)
    str = gsub(str, ' ', '+')
  end
  return str
end

--
-- parse querystring into table. urldecode tokens
--
local function parse(str, sep, eq)
  if not sep then sep = '&' end
  if not eq then eq = '=' end
  local vars = {}
  for pair in gmatch(tostring(str), '[^' .. sep .. ']+') do
    if not find(pair, eq) then
      vars[urldecode(pair)] = ''
    else
      local key, value = match(pair, '([^' .. eq .. ']*)' .. eq .. '(.*)')
      if key then
        vars[urldecode(key)] = urldecode(value)
      end
    end
  end
  return vars
end

-- module
return {
  urlencode = urlencode,
  urldecode = urldecode,
  parse = parse,
}
