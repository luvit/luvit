--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

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

local uv = require('uv')
local Emitter = require('core').Emitter
local timer = require('timer')

exports.name = "luvit/dgram"
exports.version = "0.1.1"

local function start_listening(self)
  uv.udp_recv_start(self._handle, function(err, msg, rinfo, flags)
    timer.active(self)
    if err then
      self:emit('error', err)
    else
      if msg then
        self:emit('message', msg, rinfo, flags)
      end
    end
  end)
end

local function stop_listening(self)
  return uv.udp_recv_stop(self._handle)
end

local Socket = Emitter:extend()
function Socket:initialize(type, callback)
  self._handle = uv.new_udp()
  if callback then
    self:on('message', callback)
  end
end

Socket.recvStart = start_listening

Socket.recvStop = stop_listening

function Socket:setTimeout(msecs, callback)
  if msecs > 0 then
    timer.enroll(self, msecs)
    timer.active(self)
    if callback then
      self:once('timeout', callback)
    end
  elseif msecs == 0 then
    timer.unenroll(self)
  end
end

function Socket:send(data, port, host, callback)
  timer.active(self)
  uv.udp_send(self._handle, data, host, port, callback)
end

function Socket:bind(port, host, options)
  uv.udp_bind(self._handle, host, port, options)
  self:recvStart()
end

function Socket:close(callback)
  timer.unenroll(self)
  if not self._handle then
    return
  end
  self:recvStop()
  uv.close(self._handle, callback)
  self._handle = nil
end

function Socket:address()
  return uv.udp_getsockname(self._handle)
end

function Socket:setBroadcast(status)
  uv.udp_set_broadcast(self._handle, status)
end

function Socket:setTTL(ttl)
  uv.udp_set_ttl(self._handle, ttl)
end

local function createSocket(type, callback)
  return Socket:new(type, callback)
end

exports.Socket = Socket
exports.createSocket = createSocket
