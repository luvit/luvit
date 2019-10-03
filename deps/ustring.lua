--[[

Copyright 2014-2015 The Luvit Authors. All Rights Reserved.

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
  name = "luvit/ustring"
  version = "2.0.2"
  homepage = "https://github.com/luvit/luvit/blob/master/deps/ustring.lua"
  description = "A light-weight UTF-8 module in pure lua(jit)."
  tags = {"ustring", "utf8", "utf-8", "unicode"}
  license = "Apache 2"
]]

local ustring = {}
local _meta = {}

local tostring = tostring
local rshift = bit.rshift
local lshift = bit.lshift
local bor = bit.bor
local band = bit.band

local str_sub = string.sub
local str_byte = string.byte
local str_char = string.char
local str_gsub = string.gsub
local str_find = string.find
local str_format = string.format
local str_gmatch = string.gmatch
local str_match = string.match
local str_lower = string.lower
local str_upper = string.upper

local function chlen(byte)
  if rshift(byte, 7) == 0x00 then
    return 1
  elseif rshift(byte, 5) == 0x06 then
    return 2
  elseif rshift(byte, 4) == 0x0E then
    return 3
  elseif rshift(byte, 3) == 0x1E then
    return 4
  else
    -- RFC 3629 (2003.11) says UTF-8 don't have characters larger than 4 bytes.
    -- They will not be processed although they may be appeared in some old systems.
    return 0
  end
end
ustring.chlen = chlen

function ustring.new(str, allowInvaild)
  str = str and tostring(str) or ""
  local ustr = {}
  local index = 1
  local append = 0
  for i = 1, #str do
    repeat
      local char = str_sub(str,i,i)
      local byte = str_byte(char)
      if append ~= 0 then
        if not allowInvaild and rshift(byte, 6) ~= 0x02 then
          error("Invaild UTF-8 sequence at " .. i)
        end
        ustr[index] = ustr[index] .. char
        append = append - 1
        if append == 0 then
          index = index + 1
        end
        break
      end
      local charLen = chlen(byte)
      if not allowInvaild and charLen == 0 then
        error("Invaild UTF-8 sequence at " .. tostring(i) .. ", byte:" .. tostring(byte))
      end
      ustr[index] = char
      if charLen == 1 then
        index = index + 1
      end
      append = append + charLen - 1
    until true
  end
  setmetatable(ustr, _meta)
  return ustr
end

function ustring.copy(ustr)
  local u = ustring.new()
  for i = 1, #ustr do
    u[i] = ustr[i]
  end
  return u
end

function ustring.index2uindex(ustr, rawindex, initrawindex, initindex)
  -- convert a raw index into the index of a UTF-8
  -- return `nil` if uindex is invaild
  -- the last 2 arguments are optional and used for better performance (only if rawindex isn't negative)
  if rawindex < 0 then
    local index = 1
    repeat
      local uchar = ustr[index]
      if uchar == nil then return nil end
      local len = #uchar
      index = index + 1
      rawindex = rawindex + len
    until rawindex >= 0
    return -(index - 1)
  else
    rawindex = rawindex - (initrawindex or 1) + 1
    local index = (initindex or 1)
    repeat
      local uchar = ustr[index]
      if uchar == nil then return nil end
      local len = #uchar
      index = index + 1
      rawindex = rawindex - len
    until rawindex <= 0
    return index - 1
  end
end

function ustring.uindex2index(ustr, uindex, initrawindex, inituindex)
  -- convert the index of a UIF-8 char into a raw index
  -- return `nil` if rawindex is invaild
  -- the last 2 arguments are optional and used for better performance (only if uindex isn't negative)
  uindex = uindex or 1
  local ulen = #ustr
  if uindex < 0 then
    local index = 0
    for i = ulen,ulen + uindex + 1,-1 do
      index = index + #ustr[i]
    end
    return -index
  else
    local index = (inituindex or 1)
    inituindex = inituindex or 1
    for i = inituindex,uindex - 1 do
      index = index + #ustr[i]
    end
    return index
  end
end

--[[
RFC 3629
Char. number range  |        UTF-8 octet sequence
   (hexadecimal)    |              (binary)
--------------------+---------------------------------------------
0000 0000-0000 007F | 0xxxxxxx
0000 0080-0000 07FF | 110xxxxx 10xxxxxx
0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx
0001 0000-0010 FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
]]

local function bin(str)
  return tonumber(str, 2)
end

local codec = {
  {0x00000000, 0x0000007F, bin('00000000'), bin('01111111')},
  {0x00000080, 0x000007FF, bin('11000000'), bin('00011111')},
  {0x00000800, 0x0000FFFF, bin('11100000'), bin('00001111')},
  {0x00010000, 0x0010FFFF, bin('11110000'), bin('00000111')},
}

local mask = {bin('10000000'), bin('00111111')}

local function range(n)
  for i, v in ipairs(codec) do
    if v[1] <= n and n <= v[2] then
      return i
    end
  end
  error('value out of range: ' .. n)
end

local function utf8char(n)
  local i = range(n)
  if i == 1 then
    return str_char(n)
  else
    local buf = {}
    for b = i, 2, -1 do
      local byte = band(n, mask[2])
      byte = bor(mask[1], byte)
      buf[b] = str_char(byte)
      n = rshift(n, 6)
    end
    n = bor(codec[i][3], n)
    buf[1] = str_char(n)
    return table.concat(buf)
  end
end

function ustring.char(...)
  local ustr = {}
  for i = 1, select('#', ...) do
    ustr[i] = utf8char(select(i, ...))
  end
  return setmetatable(ustr, _meta)
end

local function utf8codepoint(str)
  local n = #str
  if n == 1 then
    return str_byte(str)
  else
    local byte = str_byte(str)
    local ret = band(byte, codec[n][4])
    for i = 2, n do
      ret = lshift(ret, 6)
      byte = str_byte(str, i, i)
      byte = band(byte, mask[2])
      ret = bor(ret, byte)
    end
    return ret
  end
end

function ustring.codepoint(ustr, i, j)
  i = i or 1
  j = j or i
  local ret = {}
  local len = #ustr
  if i < 0 then i = len + i + 1 end
  if j < 0 then j = len + j + 1 end
  for ii = i, math.min(j, len) do
    ret[#ret + 1] = utf8codepoint(ustr[ii])
  end
  return unpack(ret)
end

ustring.len = _G.rawlen or function(ustr) return #ustr end

function ustring.gsub(ustr, pattern, repl, n)
  return ustring.new(str_gsub(tostring(ustr), tostring(pattern), tostring(repl), n))
end

function ustring.sub(ustr, i, j)
  local u = ustring.new()
  j = j or -1
  local len = #ustr
  if i < 0 then i = len + i + 1 end
  if j < 0 then j = len + j + 1 end
  for ii = i, math.min(j, len) do
    u[#u + 1] = ustr[ii]
  end
  return u
end

function ustring.find(ustr, pattern, init, plain)
  local first, last = str_find(tostring(ustr), tostring(pattern), ustring.uindex2index(ustr, init), plain)
  if first == nil then return nil end
  local ufirst = ustring.index2uindex(ustr, first)
  local ulast = ustring.index2uindex(ustr, last, first, ufirst)
  return ufirst, ulast
end

function ustring.format(formatstring, ...)
  return ustring.new(str_format(tostring(formatstring), ...))
end

function ustring.gmatch(ustr, pattern)
  return str_gmatch(tostring(ustr), pattern)
end

function ustring.match(ustr, pattern, init)
  return str_match(tostring(ustr), tostring(pattern), ustring.uindex2index(ustr, init))
end

function ustring.lower(ustr)
  local u = ustring.copy(ustr)
  for i = 1, #u do
    u[i] = str_lower(u[i])
  end
  return u
end

function ustring.upper(ustr)
  local u = ustring.copy(ustr)
  for i = 1, #u do
    u[i] = str_upper(u[i])
  end
  return u
end

function ustring.rep(ustr, n)
  local u = ustring.new()
  for i = 1, n do
    for ii = 1, #ustr do
      u[#u + 1] = ustr[ii]
    end
  end
  return u
end

function ustring.reverse(ustr)
  local u = ustring.copy(ustr)
  local len = #ustr
  for i = 1, len do
    u[i] = ustr[len - i + 1]
  end
  return u
end

_meta.__index = ustring

function _meta.__eq(ustr1, ustr2)
  local len1 = #ustr1
  local len2 = #ustr2
  if len1 ~= len2 then return false end
  for i = 1, len1 do
    if ustr1[i] ~= ustr2[i] then return false end
  end
  return true
end

function _meta.__tostring(self)
  return tostring(table.concat(self))
end

function _meta.__concat(ustr1,ustr2)
  local u = ustring.copy(ustr1)
  for i = 1, #ustr2 do
    u[#u + 1] = ustr2[i]
  end
  return u
end

_meta.__len = ustring.len

return ustring
