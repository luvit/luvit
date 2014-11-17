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
local timer = require('timer')
local utils = require('utils')
local table = require('table')
local core = require('core')
local Emitter = core.Emitter
local iStream = core.iStream

local net = {}

--[[ Socket ]]--

local Socket = iStream:extend()

function Socket:bind(ip, port)
  uv.tcp_bind(self._handle, ip, tonumber(port))
end

function Socket:_onTimeoutReal()
  self:emit('timeout')
end

function Socket:address()
  return uv.tcp_getpeername(self._handle)
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
  uv.write(self._handle, data, function(err)
    if err then
      return self:emit('error', err);
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
  return uv.tcp_write_queue_size(self._handle) == 0
end

function Socket:shutdown(callback)
  if self.destroyed == true then
    return
  end
  
  if uv.is_closing(self._handle) then
    return callback()
  end

  uv.shutdown(self._handle, callback)
end

function Socket:nodelay(enable)
  uv.tcp_nodelay(self._handle, enable)
end

function Socket:keepalive(enable, delay)
  uv.tcp_keepalive(self._handle, enable, delay)
end

function Socket:pause()
  uv.read_stop(self._handle)
end

function Socket:resume()
  self:setConnected(true)
  uv.read_start(self._handle, function(err, data)
    if err then
      return self:emit('error', err)
    end
    timer.active(self)
    if data == nil then
      return self:destroy()
    end
    self:emit('data', data)
  end)
end

function Socket:isConnected()
  return self._connected
end

function Socket:setConnected(status)
  self._connected = status
  return status
end

function Socket:done()
  self.writable = false

  self:shutdown(function()
    self:destroy(function()
      self:emit('close')
    end)
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

  callback = callback or function() end

  if not options.host then
    options.host = '0.0.0.0'
  end

  timer.active(self)
  self._connecting = true

  uv.getaddrinfo(options.host, options.port, { socktype = "STREAM" }, function(err, res)
    timer.active(self)
    if err then
      return callback(err)
    end
    if not self._handle then
      return
    end
    timer.active(self)
    uv.tcp_connect(self._handle, res[1].addr, res[1].port, function(err)
      timer.active(self)
      if err then
        return callback(err)
      end

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
      else
        self:resume()
      end

      if callback then
        callback()
      end
    end)
  end)

  return self
end

function Socket:destroy(exception, callback)
  callback = callback or function() end
  if self.destroyed == true or self._handle == nil then
    return callback()
  end
  self.destroyed = true

  timer.unenroll(self)
  self.readable = false
  self.writable = false

  if self._handle then
    self:setConnected(false)

    if uv.is_closing(self._handle) then
      return callback(exception)
    end

    uv.close(self._handle)
    self._handle = nil
    if (exception) then
      self:emit('error', exception)
    end
  end
end

function Socket:listen(queueSize)
  queueSize = queueSize or 128
  uv.listen(self._handle, queueSize, function()
    local client = uv.new_tcp()
    uv.accept(self._handle, client)
    client = Socket:new(client)
    client:resume()
    self:emit('connection', client)
  end)
end

function Socket:getsockname()
  return uv.tcp_getsockname(self._handle)
end

function Socket:initialize(handle)
  self._onTimeout = utils.bind(Socket._onTimeoutReal, self)
  self._handle = handle or uv.new_tcp()
  self._pendingWriteRequests = 0
  self._connected = false
  self._connecting = false
  self._connectQueueSize = 0
  self.readable = true
  self.writable = true
  self.destroyed = false
end

--[[ Server ]]--

local Server = Emitter:extend()
function Server:listen(port, ... --[[ ip, callback --]] )
  local args = {...}
  local ip
  local callback

  -- Future proof
  if type(args[1]) == 'function' then
    callback = args[1]
  else
    ip = args[1]
    callback = args[2]
  end

  ip = ip or '0.0.0.0'

  self._handle:bind(ip, port)
  self._handle:listen()
  self._handle:on('connection', function(client)
    self.connectionCallback(client)
  end)

  if callback then
    timer.setTimeout(0, callback)
  end

  return self
end

function Server:address()
  if self._handle then
    return self._handle:getsockname()
  end
  return nil
end

function Server:close(callback)
  self._handle:destroy(nil, callback)
end

function Server:initialize(...)
  local args = {...}
  local options

  if #args == 1 then
    options = {}
    self.connectionCallback = args[1]
  elseif #args == 2 then
    options = args[1]
    self.connectionCallback = args[2]
  end

  if options.handle then
    self._handle = options.handle
  end

  if not self._handle then
    self._handle = Socket:new()
  end
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

net.createServer = function(...)
  return Server:new(...)
end

return net
