local buffer = require('buffer')
local hasFfi = pcall(require, 'ffi')

local Buffer = buffer.Buffer

local function startlapse(title)
  title = title or 'benchmark'
  local d1 = os.clock()
  return function ()
    print(title .. ': ' .. os.clock() - d1)
  end
end

print('Buffer library benchmarks using ' .. (hasFfi and 'FFI' or 'Lua tables'))

local endlapse = startlapse('Creating 10e5 16-byte buffers')
for _ = 1, 10e5 do
  local _ = Buffer:new(16)
end
endlapse()

endlapse = startlapse('Creating 10e5 128-byte buffers')
for _ = 1, 10e5 do
  local _ = Buffer:new(128)
end
endlapse()

endlapse = startlapse('Creating 10e5 16-byte buffers with content')
for _ = 1, 10e5 do
  local _ = Buffer:new('abcdefghijklmnop')
end
endlapse()

endlapse = startlapse('Creating 10e5 128-byte buffers with content')
for _ = 1, 10e5 do
  local _ = Buffer:new('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut e')
end
endlapse()

endlapse = startlapse('Creating and calling toString on 10e5 16-byte buffers')
for _ = 1, 10e5 do
  local _ = Buffer:new('abcdefghijklmnop'):toString()
end
endlapse()

endlapse = startlapse('Creating and calling toString on 10e5 128-byte buffers')
for _ = 1, 10e5 do
  local _ = Buffer:new('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut e'):toString()
end
endlapse()


do
  local buf = Buffer:new(16)
  endlapse = startlapse('Write operations with 10e6 iteration')
  for _ = 1, 10e6 do
    buf:writeUInt8(1, 0xFB)
    buf:writeUInt8(2, 0x04)
    buf:writeUInt8(3, 0x23)
    buf:writeUInt8(4, 0x42)
    buf:writeInt8(1, -0x05)
    buf:writeInt8(2, 0x04)
    buf:writeInt8(3, 0x23)
    buf:writeInt8(4, 0x42)
    buf:writeUInt16BE(1, 0xFB04)
    buf:writeUInt16LE(1, 0x04FB)
    buf:writeUInt16BE(2, 0x0423)
    buf:writeUInt16LE(2, 0x2304)
    buf:writeUInt16BE(3, 0x2342)
    buf:writeUInt16LE(3, 0x4223)
    buf:writeUInt32BE(1, 0xFB042342)
    buf:writeUInt32LE(1, 0x422304FB)
    buf:writeInt32BE(1, -0x04FBDCBE)
    buf:writeInt32LE(1, 0x422304FB)
  end
  endlapse()

  endlapse = startlapse('Read operations with 10e8 iteration')
  for _ = 1, 10e8 do
    buf:readUInt8(1)
    buf:readUInt8(2)
    buf:readUInt8(3)
    buf:readUInt8(4)
    buf:readInt8(1)
    buf:readInt8(2)
    buf:readInt8(3)
    buf:readInt8(4)
    buf:readUInt16BE(1)
    buf:readUInt16LE(1)
    buf:readUInt16BE(2)
    buf:readUInt16LE(2)
    buf:readUInt16BE(3)
    buf:readUInt16LE(3)
    buf:readUInt32BE(1)
    buf:readUInt32LE(1)
    buf:readInt32BE(1)
    buf:readInt32LE(1)
  end
  endlapse()
end
