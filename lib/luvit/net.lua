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

local native = require('uv_native')
local dns = require('dns')
local Tcp = require('uv').Tcp
local Timer = require('uv').Timer
local timer = require('timer')
local utils = require('utils')
local Emitter = require('core').Emitter
local iStream = require('core').iStream
local table = require('table')

local net = {}

--[[ Socket ]]--

local Socket = iStream:extend()

function Socket:_connect(address, port, addressType)
  if self.destroyed then
    return
  end
  if port then
    self.remotePort = port
  end
  self.remoteAddress = address

  local connectionReq = nil
  if addressType == 4 then
    connectionReq = self._handle:connect(address, port)
  elseif addressType == 6 then
    connectionReq = self._handle:connect6(address, port)
  end

  -- connect only returns an error or nothing
  if (connectionReq ~= nil) then
    self:destroy()
  end
end

function Socket:_onTimeoutReal()
  self:emit('timeout')
end

function Socket:address()
  if self._handle then
    return self._handle:getpeername()
  end
  return nil
end

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

function Socket:write(data, callback)
  if self.destroyed then
    return
  end
  self.bytesWritten = self.bytesWritten + #data

  if self._connecting == true then
    self._connectQueueSize = self._connectQueueSize + #data 
    if self._connectQueue then
      table.insert(self._connectQueue, {data, callback})
    else
      self._connectQueue = { {data, callback} }
    end
    return false
  end

  return self:_write(data, callback)
end

function Socket:_write(data, callback)
  timer.active(self)
  self._pendingWriteRequests = self._pendingWriteRequests + 1
  self._handle:write(data, function(err)
    if err then
      self:emit('error', err);
      return
    end
    timer.active(self)
    self._pendingWriteRequests = self._pendingWriteRequests - 1
    if self._pendingWriteRequests == 0 then
      self:emit('drain');
    end
    if callback then
      callback()
    end
  end)
  return self._handle:writeQueueSize() == 0
end

function Socket:shutdown(callback)
  if self.destroyed == true then
    return
  end

  self._handle:shutdown(callback)
end

function Socket:nodelay(enable)
  self._handle:nodelay(enable)
end

function Socket:keepalive(enable, delay)
  self._handle:keepalive(enable, delay)
end

function Socket:pause()
  self._handle:readStop()
end

function Socket:resume()
  self._handle:readStart()
end

function Socket:isConnected()
  return self._connected
end

function Socket:_initEmitters()
  self._handle:once('close', function()
    self:destroy()
  end)

  self._handle:on('timeout', function()
    self:emit('timeout')
  end)

  self._handle:on('connect', function()
    self._connected = true
    self:emit('connect')
  end)

  self._handle:once('end', function()
    self:emit('end')
    self:done()
  end)

  self._handle:on('data', function(data)
    timer.active(self)
    self.bytesRead = self.bytesRead + #data
    self:emit('data', data)
  end)

  self._handle:on('error', function(err)
    self:destroy(err)
  end)
end

function Socket:done()
  self.writable = false

  self:shutdown(function()
    self:destroy()
  end)
end

function Socket:connect(...)
  local args = {...}
  local options = {}
  local callback

  if type(args[1]) == 'table' then
    -- connect(options, [cb])
    options = args[1]
    callback = args[2]
  else
    -- connect(port, [host], [cb])
    options.port = args[1]
    if type(args[2]) == 'string' then
      options.host = args[2];
      callback = args[3]
    else
      callback = args[2]
    end
  end

  if not options.host then
    options.host = '0.0.0.0'
  end

  timer.active(self)
  self._connecting = true

  self._handle:on('connect', function()
    self._connecting = false

    if self._connectQueue then
      for i=1, #self._connectQueue do
        self:_write(self._connectQueue[i][1], self._connectQueue[i][2])
      end
      self._connectQueue = nil
    end

    if self._paused then
      self._paused = false
      self:pause()
    end

    self._handle:readStart()
    if callback then
      callback()
    end
  end)

  dns.lookup(options.host, function(err, ip, addressType)
    if err then
      process.nextTick(function()
        self:emit('error', err)
        self:destroy()
      end)
    else
      timer.active(self)
      self:_connect(ip, options.port, addressType)
    end
  end)

  return self
end

function Socket:destroy(exception)
  if self.destroyed == true then
    return
  end

  self.destroyed = true

  timer.unenroll(self)
  self.readable = false
  self.writable = false

  if self._handle then
    self._handle:close()
    self._handle = nil
  end
  process.nextTick(function()
    if (exception) then
      self:emit('error', exception)
    end
    self:emit('close')
  end)
end

function Socket:initialize(handle)
  self._onTimeout = utils.bind(Socket._onTimeoutReal, self)
  self._handle = handle or Tcp:new()
  self._pendingWriteRequests = 0
  self._connected = false
  self._connecting = false
  self._connectQueueSize = 0
  self.bytesWritten = 0
  self.bytesRead = 0
  self.readable = true
  self.writable = true
  self.destroyed = false

  self:_initEmitters()
end

--[[ Server ]]--

local Server = Emitter:extend()
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
    sock:on('end', function()
      sock:destroy()
    end)
    sock:resume()
    self:emit('connection', sock)
    sock:emit('connect')
  end)

  return self
end

function Server:_emitClosedIfDrained()
  timer.setTimeout(0, function()
    self:emit('close')
  end)
end

function Server:address()
  if self._handle then
    return self._handle:getsockname()
  end
  return nil
end

function Server:close(callback)
  if not self._handle then
    error('Not running')
  end
  if callback then
    self:once('close', callback)
  end
  if self._handle then
    self._handle:close()
    self._handle = nil
  end
  self:_emitClosedIfDrained()
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
  local options
  local callback
  local s

  -- future proof
  if type(port) == 'table' then
    options = port
    port = options.port
    host = options.host
    callback = args[1]
  else
    host = args[1]
    callback = args[2]
  end

  s = Socket:new()
  return s:connect(port, host, callback)
end

net.create = net.createConnection

net.createServer = function(connectionCallback)
  return Server:new(connectionCallback)
end

net.isIP = function(ip)
  return native.dnsIsIp(ip)
end

net.isIPv4 = function(ip)
  return native.dnsIsIpV4(ip)
end

net.isIPv6 = function(ip)
  return native.dnsIsIpV6(ip)
end

return net
