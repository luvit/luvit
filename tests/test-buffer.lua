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

local buf2 = Buffer:new('abcdefghij')
assert(tostring(buf2) == 'abcdefghij')
assert(buf2:toString(1, 2) == 'ab')
assert(buf2:toString(2, 3) == 'bc')
assert(buf2:toString(3) == 'cdefghij')
assert(buf2:toString() == 'abcdefghij')

-- test Buffer:upUntil
assert(buf2:upUntil("") == '')
assert(buf2:upUntil("d") == 'abc')
assert(buf2:upUntil("d", 4) == '')
assert(buf2:upUntil("d", 5) == 'efghij')

-- test Buffer.isBuffer
assert(Buffer.isBuffer(buf2) == true)
assert(Buffer.isBuffer("buf") == false)

-- test Buffer.length
assert(buf2.length == 10)

-- test Buffer:inspect
assert(buf:inspect() == "<Buffer FB 04 23 42 >")

-- test Buffer.meta:__concat
local concat_buf = buf .. buf2
assert( concat_buf:inspect() == "<Buffer FB 04 23 42 61 62 63 64 65 66 67 68 69 6A >")

-- test Buffer.fill
concat_buf:fill("", 4, 4)
assert( concat_buf:inspect() == "<Buffer FB 04 23 00 61 62 63 64 65 66 67 68 69 6A >")
concat_buf:fill("", 4, 8)
assert( concat_buf:inspect() == "<Buffer FB 04 23 00 00 00 00 00 65 66 67 68 69 6A >")
concat_buf:fill(0x05, 4, 8)
assert( concat_buf:inspect() == "<Buffer FB 04 23 05 05 05 05 05 65 66 67 68 69 6A >")
concat_buf:fill(0x42, 1)
assert( concat_buf:inspect() == "<Buffer 42 42 42 42 42 42 42 42 42 42 42 42 42 42 >")
concat_buf:fill("\0", 1)
assert( concat_buf:inspect() == "<Buffer 00 00 00 00 00 00 00 00 00 00 00 00 00 00 >")

-- test bitwise write
local writebuf = Buffer:new(4)
writebuf:writeUInt8(0xFB, 1)
writebuf:writeUInt8(0x04, 2)
writebuf:writeUInt8(0x23, 3)
writebuf:writeUInt8(0x42, 4)
writebuf:writeInt8(-0x05, 1)
writebuf:writeInt8(0x04, 2)
writebuf:writeInt8(0x23, 3)
writebuf:writeInt8(0x42, 4)
writebuf:writeUInt16BE(0xFB04, 1)
writebuf:writeUInt16LE(0x04FB, 1)
writebuf:writeUInt16BE(0x0423, 2)
writebuf:writeUInt16LE(0x2304, 2)
writebuf:writeUInt16BE(0x2342, 3)
writebuf:writeUInt16LE(0x4223, 3)
writebuf:writeUInt32BE(0xFB042342, 1)
writebuf:writeUInt32LE(0x422304FB, 1)
writebuf:writeInt32BE(-0x04FBDCBE, 1)
writebuf:writeInt32LE(0x422304FB, 1)
assert( writebuf:inspect() == "<Buffer FB 04 23 42 >")

