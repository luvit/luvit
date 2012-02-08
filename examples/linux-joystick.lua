local Bit = require('bit')
local FS = require('fs')
local Emitter = require('core').Emitter
local Buffer = require('buffer').Buffer
local timer = require('timer')

-- http://www.mjmwired.net/kernel/Documentation/input/joystick-api.txt
function parse(buffer)
  local event = {
    time   = buffer:readUInt32LE(1),
    number = buffer:readUInt8(8),
    value  = buffer:readUInt16LE(5),
  }
  local type = buffer:readUInt8(7)
  if Bit.band(type, 0x80) > 0 then event.init = true end
  if Bit.band(type, 0x01) > 0 then event.type = "button" end
  if Bit.band(type, 0x02) > 0 then event.type = "axis" end
  return event
end

-- Expose as a nice Lua API
local Joystick = Emitter:extend()

function Joystick:initialize(id)
  self:wrap("onOpen")
  self:wrap("onRead")
  self.id = id
  FS.open("/dev/input/js" .. id, "r", "0644", self.onOpen)
end


function Joystick:onOpen(fd)
  debug("fd", fd)
  self.fd = fd
  self:startRead()
end

function Joystick:startRead()
  FS.read(self.fd, nil, 8, self.onRead)
end

function Joystick:onRead(chunk)
  local event = parse(Buffer:new(chunk))
  event.id = self.id
  self:emit(event.type, event)
  if self.fd then self:startRead() end
end

function Joystick:close(callback)
  local fd = self.fd
  self.fd = nil
  FS.close(fd, callback)
end

--------------------------------------------------------------------------------

-- Sample usage
local js = Joystick:new(0)
js:on('button', p);
js:on('axis', p);
js:on('error', function (err)
  debug("Error", err)
end)


-- Close after 5 seconds
--require('timer'):set_timeout(5000, function ()
--  js:close()
--end);

