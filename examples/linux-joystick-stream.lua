local fs = require('fs')
local Buffer = require('buffer').Buffer

-- https://www.kernel.org/doc/Documentation/input/joystick-api.txt
local function parse(buffer)
  local event = {
    time   = buffer:readUInt32LE(1),
    number = buffer:readUInt8(8),
    value  = buffer:readUInt16LE(5),
  }
  local type = buffer:readUInt8(7)
  if bit.band(type, 0x80) > 0 then event.init = true end
  if bit.band(type, 0x01) > 0 then event.type = "button" end
  if bit.band(type, 0x02) > 0 then event.type = "axis" end
  return event
end

local readStream = fs.createReadStream("/dev/input/js0", { chunkSize = 8 })

readStream:on("data", function (chunk)
  p(parse(Buffer:new(chunk)))
end)

readStream:on("error", error)

coroutine.yield()
