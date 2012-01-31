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

local Table = require('table')
local String = require('string')
local Object = require('object')
local FFI = require('ffi')
FFI.cdef([[
  void *malloc (size_t __size);
  void free (void *__ptr);
]])

local Buffer = Object:extend()

function Buffer.prototype:initialize(length)
  if type(length) == "number" then
    self.length = length
    self.ctype = FFI.gc(FFI.cast("unsigned char*", FFI.C.malloc(length)), FFI.C.free)
  elseif type(length) == "string" then
    local string = length
    self.length = #string
    self.ctype = FFI.cast("unsigned char*", string)
  else
    error("Input must be a string or number")
  end
end

function Buffer.meta:__tostring()
  return FFI.string(self.ctype)
end

function Buffer.meta:__concat(other)
  return tostring(self) .. tostring(other)
end

function Buffer.meta:__index(key)
  if type(key) == "number" then
    if key < 1 or key > self.length then error("Index out of bounds") end
    return self.ctype[key - 1]
  end
  return Buffer.prototype[key]
end

function Buffer.meta:__newindex(key, value)
  if type(key) == "number" then
    if key < 1 or key > self.length then error("Index out of bounds") end
    self.ctype[key - 1] = value
    return
  end
  rawset(self, key, value)
end

function Buffer.prototype:inspect()
  local parts = {}
  for i = 1, tonumber(self.length) do
    parts[i] = String.format("%X", self[i])
  end
  return "<Buffer " .. Table.concat(parts, " ") .. ">"
end

return Buffer
