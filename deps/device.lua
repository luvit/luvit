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

exports.name = "luvit/device"
exports.version = "1.1.2"
exports.dependencies = {
  "luvit/timer@1.0.0",
  "luvit/utils@1.0.0",
  "luvit/core@1.0.2",
  "luvit/stream@1.1.0",
}
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/device.lua"
exports.description = "Node-style device IO module for luvit"
exports.tags = {"luvit", "device", "stream"}

local uv = require('uv')
local timer = require('timer')
local utils = require('utils')
local Emitter = require('core').Emitter

--[[ Device ]]--
local Device = Emitter:extend()
function Device:initialize(devname,flags)
  
  if type(devname)=='userdata' then
    self._handle = devname
    assert(self._handle,'invalid handle')
  else
    self.flags = flags and flags or 'r+'
    self.devname = devname
    self._handle, self.err = uv.new_device(devname, self.flags)
    assert(self._handle,'open device fail:'..(self.err and self.err or ''))
  end
  
  self._fd = uv.fileno(self._handle)
  self:on('finish', utils.bind(self._onDeviceFinish, self))
end

function Device:_onDeviceFinish()
  return self:destroy()
end

function Device:setTimeout(msecs, callback)
  if msecs > 0 then
    timer.enroll(self, msecs)
    timer.active(self)
    if callback then self:once('timeout', callback) end
  elseif msecs == 0 then
    timer.unenroll(self)
  end
end

function Device:write(data, callback)
  if not self._handle then return end
  timer.active(self)
  uv.write(self._handle, data, function(err)
    timer.active(self)
    if callback then callback(err) end
  end)
end

function Device:read(onData)
  local onRead
  timer.active(self)

  function onRead(err, data)
    timer.active(self)
    if err then
      self:emit('error',err)
    elseif data then
      onData(self,data)
    else
      self:emit('end')
    end
  end
  self.onRead = onRead
  uv.read_start(self._handle, onRead)
end

function Device:ioctl(cmd, ...)

end

function Device:pause()
  if not self._handle then return end
  uv.read_stop(self._handle)
end

function Device:resume()
  if not self._handle then return end
  if not self.onRead then return end

  uv.read_start(self._handle, self.onRead)
end

function Device:open(callback)
  assert(type(callback)=='function')
  timer.active(self)
  assert(self._handle)
  
  local ret, err = pcall(callback,self)
  if not ret then
    return self:destroy(err)
  end
  return self
end

function Device:destroy(exception, callback)
  callback = callback or function() end
  if self.destroyed == true or self._handle == nil then
    return callback()
  end

  timer.unenroll(self)
  self.destroyed = true
  self.readable = false
  self.writable = false

  if uv.is_closing(self._handle) then
    timer.setImmediate(callback)
  else
    uv.close(self._handle, callback)
  end

  if exception then
    process.nextTick(function()
      self:emit('error', exception)
    end)
  end
end

-- Exports

exports.Device = Device

exports.openDevice = function(devname, callback)
  local dev

  dev = Device:new(devname)
  dev:open(callback)
  return dev
end

exports.open = exports.openDevice
