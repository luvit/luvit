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

local table = require('table')
local Object = require('core').Object
local bit = require('bit')
local cbuffer = require("cbuffer")

local buffer = {}

local Buffer = Object:extend()
buffer.Buffer = Buffer

function Buffer:initialize(length)
  self.cbuf = cbuffer.new(length)
end

function Buffer.meta:__ipairs()
  local index = 0
  return function (...)
    if index < self.length then
      index = index + 1
      return index, self[index]
    end
  end
end

function Buffer.meta:__tostring()
  return self.cbuf:toString()
end

function Buffer.meta:__concat(other)
  return tostring(self) .. tostring(other)
end

function Buffer.meta:__index(key)
  if type(key) == "number" then
    return self.cbuf[key]
  elseif key == "length" then
    -- X:TODO bring this into cbuffer or make it obsolete
    return #self.cbuf
  end
  return Buffer[key]
end

function Buffer.meta:__newindex(key, value)
  if type(key) == "number" then
    self.cbuf[key] = value
    return
  end
  rawset(self, key, value)
end

-- Allow usage of length operator(#)
function Buffer.meta:__len()
  return #self.cbuf
end

-- Allow copying direct copying into buffer
function Buffer:copy(i, bufOrString) --X:TODO Support length
  if type(bufOrString) ~= "string" then
    bufOrString = tostring(bufOrString)
  end
  self.cbuf[i] = bufOrString
end

-- Returns buffer contents up until first instance of bufOrString
-- Very useful for binary protocols
function Buffer:upuntil(bufOrString, i)
  error("Not supported with of cbuffers yet!")
end

function Buffer:inspect()
  local parts = {}
  for i = 1, tonumber(#self.cbuf) do
    parts[i] = bit.tohex(self.cbuf[i], 2)
  end
  return "<Buffer " .. table.concat(parts, " ") .. ">"
end

local function compliment8(value)
  return value < 0x80 and value or -0x100 + value
end

function Buffer:readUInt8(offset)
  return self[offset]
end

function Buffer:readInt8(offset)
  return compliment8(self[offset])
end

local function compliment16(value)
  return value < 0x8000 and value or -0x10000 + value
end

function Buffer:readUInt16LE(offset)
  return bit.lshift(self[offset + 1], 8) +
                    self[offset]
end

function Buffer:readUInt16BE(offset)
  return bit.lshift(self[offset], 8) +
                    self[offset + 1]
end

function Buffer:readInt16LE(offset)
  return compliment16(self:readUInt16LE(offset))
end

function Buffer:readInt16BE(offset)
  return compliment16(self:readUInt16BE(offset))
end

function Buffer:readUInt32LE(offset)
  return self[offset + 3] * 0x1000000 +
         bit.lshift(self[offset + 2], 16) +
         bit.lshift(self[offset + 1], 8) +
                    self[offset]
end

function Buffer:readUInt32BE(offset)
  return self[offset] * 0x1000000 +
         bit.lshift(self[offset + 1], 16) +
         bit.lshift(self[offset + 2], 8) +
                    self[offset + 3]
end

function Buffer:readInt32LE(offset)
  return bit.tobit(self:readUInt32LE(offset))
end

function Buffer:readInt32BE(offset)
  return bit.tobit(self:readUInt32BE(offset))
end

function Buffer:toString(i, j)
  return self.cbuf:toString(i, j)
end

return buffer
