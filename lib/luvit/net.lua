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

local dns = require('dns')
local Tcp = require('uv').Tcp
local Timer = require('uv').Timer
local timer = require('timer')
local utils = require('utils')
local Emitter = require('core').Emitter
local Stream = require('uv').Stream

local net = {}

--[[ Socket ]]--

local Socket = Stream:extend()

function Socket:_connect(address, port, addressType)
  if port then
    self.remotePort = port
  end
  self.remoteAddress = address

  if addressType == 4 then
    self._handle:connect(address, port)
  elseif addressType == 6 then
    self._handle:connect6(address, port)
  end
end

function Socket:setTimeout(msecs, callback)
  callback = callback or function() end
  if not self._connectTimer then
    self._connectTimer = Timer:new()
  end

  self._connectTimer:start(msecs, 0, function(status)
    self._connectTimer:close()
    callback()
  end)
end

function Socket:close()
  if self._handle then
    self._handle:close()
  end
  if self._connectTimer then
    timer.clearTimer(self._connectTimer)
    self._connectTimer = nil
  end
end

function Socket:pipe(destination)
  self._handle:pipe(destination)
end

function Socket:write(data, callback)
  self.bytesWritten = self.bytesWritten + #data
  return self:_write(data, callback)
end

function Socket:_write(data, callback)
  self._pendingWriteRequests = self._pendingWriteRequests + 1
  self._handle:write(data, function(err)
    self._pendingWriteRequests = self._pendingWriteRequests - 1
    if self._pendingWriteRequests == 0 then
      self:emit('drain');
    end
    if callback then
      callback(err)
    end
  end)
  return self._handle:writeQueueSize() == 0
end

function Socket:pause()
  self._handle:readStop()
end

function Socket:resume()
  self._handle:readStart()
end

function Socket:connect(port, host, callback)
  self._handle:on('connect', function()
    if self._connectTimer then
      timer.clearTimer(self._connectTimer)
      self._connectTimer = nil
    end
    self._handle:readStart()
    callback()
  end)

  self._handle:on('end', function()
    self:emit('end')
  end)

  self._handle:on('data', function(data)
    self.bytesRead = self.bytesRead + #data
    self:emit('data', data)
  end)

  self._handle:on('error', function(err)
    self:emit('error', err)
  end)

  dns.lookup(host, function(err, ip, addressType)
    if err then
      callback(err)
      return
    end
    self:_connect(ip, port, addressType)
  end)

  return self
end

function Socket:initialize(handle)
  self._connectTimer = Timer:new()
  self._handle = handle or Tcp:new()
  self._pendingWriteRequests = 0
  self.bytesWritten = 0
  self.bytesRead = 0
end

--[[ Server ]]--

local Server = Stream:extend()

function Server:listen(port, ... --[[ ip, callback --]] )
  local args = {...}
  local ip
  local callback

  if not self._handle then
    self._handle = Tcp:new()
  end

  -- Future proof
  if type(args[1]) == 'function' then
    callback = args[1]
  else
    ip = args[1]
    callback = args[2]
  end
  ip = ip or '0.0.0.0'

  self._handle:bind(ip, port)
  self._handle:on('listening', callback)
  self._handle:on('error', function(err)
    return self:emit("error", err)
  end)
  self._handle:listen(function(err)
    if (err) then
      timer.setTimeout(0, function()
        self:emit("error", err)
      end)
      return
    end
    local client = Tcp:new()
    self._handle:accept(client)
    local sock = Socket:new(client)
    sock:resume()
    self:emit('connection', sock)
  end)
end

function Server:close()
  if self._connectTimer then
    timer.clearTimer(self._connectTimer)
    self._connectTimer = nil
  end
  self._handle:close()
end

function Server:initialize(...)
  local args = {...}
  local options
  local connectionCallback

  if #args == 1 then
    connectionCallback = args[1]
  elseif #args == 2 then
    options = args[1]
    connectionCallback = args[2]
  end

  self:on('connection', connectionCallback)
end

-- Exports

net.Server = Server

net.Socket = Socket

net.createConnection = function(port, ... --[[ host, cb --]])
  local args = {...}
  local host
  local callback
  local s

  -- future proof
  host = args[1]
  callback = args[2]

  s = Socket:new()
  return s:connect(port, host, callback)
end

net.create = net.createConnection

net.createServer = function(connectionCallback)
  local s = Server:new(connectionCallback)
  return s
end

return net
