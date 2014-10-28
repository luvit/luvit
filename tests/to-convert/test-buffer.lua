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

local os = require("os")

if (os.type() == "win32") then
  print("buffer is broken on win32, need to not ffi into malloc")
  return
end

require("helper")
local Buffer = require('buffer').Buffer

local buf = Buffer:new(4)

buf[1] = 0xFB
buf[2] = 0x04
buf[3] = 0x23
buf[4] = 0x42

assert(buf:readUInt8(1) == 0xFB)
assert(buf:readUInt8(2) == 0x04)
assert(buf:readUInt8(3) == 0x23)
assert(buf:readUInt8(4) == 0x42)
assert(buf:readInt8(1) == -0x05)
assert(buf:readInt8(2) == 0x04)
assert(buf:readInt8(3) == 0x23)
assert(buf:readInt8(4) == 0x42)
assert(buf:readUInt16BE(1) == 0xFB04)
assert(buf:readUInt16LE(1) == 0x04FB)
assert(buf:readUInt16BE(2) == 0x0423)
assert(buf:readUInt16LE(2) == 0x2304)
assert(buf:readUInt16BE(3) == 0x2342)
assert(buf:readUInt16LE(3) == 0x4223)
assert(buf:readUInt32BE(1) == 0xFB042342)
assert(buf:readUInt32LE(1) == 0x422304FB)
assert(buf:readInt32BE(1) == -0x04FBDCBE)
assert(buf:readInt32LE(1) == 0x422304FB)

local buf2 = Buffer:new('abcd')
assert(tostring(buf2) == 'abcd')
assert(buf2:toString(1, 2) == 'ab')
assert(buf2:toString(2, 3) == 'bc')
assert(buf2:toString(3) == 'cd')
assert(buf2:toString() == 'abcd')
