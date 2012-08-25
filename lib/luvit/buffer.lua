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
local ffi = require('ffi')
ffi.cdef([[
  void *malloc (size_t __size);
  void free (void *__ptr);
  char *memmem (const void *__haystack, size_t __haystack_len, const void *__needle, size_t __needle_len);
]])

NULL = ffi.cast("void *", nil)

local buffer = {}

local Buffer = Object:extend()
buffer.Buffer = Buffer

function Buffer:initialize(length)
  local instant_append = nil
  if type(length) == "string" then
    instant_append = length
    length = #instant_append
  elseif type(length) ~= "number" then
    error("Input must be a string or number")
  end

  self.length = length
  -- X:MEMO~2012.08.25@kristate we malloc for all instances
  -- to ensure strings are kept in memory for the entire duration
  self.ctype = ffi.gc(ffi.cast("unsigned char*", ffi.C.malloc(length)), ffi.C.free)
  if instant_append then
    self:copy(1, instant_append)
  end

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
  -- X:MEMO~2012.08.25@kristate Explicitly set the length for ffi.string
  -- If not explicitly set, ffi falls-back to strlen, which will trip on NULL bytes
  return ffi.string(self.ctype, self.length)
end

function Buffer.meta:__concat(other)
  return tostring(self) .. tostring(other)
end

function Buffer.meta:__index(key)
  if type(key) == "number" then
    if key < 1 or key > self.length then error("Index out of bounds") end
    return self.ctype[key - 1]
  end
  return Buffer[key]
end

function Buffer.meta:__newindex(key, value)
  if type(key) == "number" then
    if key < 1 or key > self.length then error("Index out of bounds") end
    self.ctype[key - 1] = value
    return
  end
  rawset(self, key, value)
end

-- X:MEMO~2012.08.25@kristate Allow usage of length operator(#)
function Buffer.meta:__len()
  return self.length
end

-- X:MEMO~2012.08.25@kristate Allow copying direct copying into buffer via ffi.copy
function Buffer:copy(i, bufOrString, length)
  local offset = i and i - 1 or 0
  if type(bufOrString) == "string" then
    if not length then
      length = #bufOrString
    else
      assert(length <= #bufOrString)
    end
    assert(length <= self.length + offset)
    local bufOrString_ctype = ffi.cast("unsigned char*", bufOrString)
    ffi.copy(self.ctype+offset, bufOrString_ctype, length)
    return length
  elseif bufOrString.readUInt8 then -- luvit's buffer
    if not length then
      length = bufOrString.length
    else
      assert(length <= #bufOrString)
    end
    assert(length <= self.length + offset)
    ffi.copy(self.ctype+offset, bufOrString.ctype, length)
    return length
  end

  error("Buffer:copy: argument must be a buffer or a string" )
end

-- X:MEMO~2012.08.25@kristate returns buffer contents up until first instance of bufOrString
-- Very useful for binary protocols
function Buffer:upuntil(bufOrString, i)
  local offset = i and i - 1 or 0
  local bufOrString_ctype = ffi.cast("unsigned char*", bufOrString)
  local found = ffi.C.memmem(self.ctype + offset, self.length - offset, bufOrString_ctype, #bufOrString)
  if found == NULL then
    return self:toString(i)
  end
  return ffi.string(self.ctype + offset, found - self.ctype - offset)
end

function Buffer:inspect()
  local parts = {}
  for i = 1, tonumber(self.length) do
    parts[i] = bit.tohex(self[i], 2)
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
  local offset = i and i - 1 or 0
  return ffi.string(self.ctype + offset, (j or self.length) - offset)
end

return buffer
