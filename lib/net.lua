local dns = require('dns')
local UV = require('uv')
local tcp = require('tcp')
local timer = require('timer')
local utils = require('utils')
local Stream = require('stream')

local Net = {}

local Socket = { }
utils.inherits(Socket, Stream)

function Socket.prototype:_connect(ip, port, addressType)
  if port then
    self.remotePort = port
  end
  self.remoteAddress = address

  if addressType == 4 then
    self._handle:connect(ip, port)
  elseif addressType == 6 then
    self._handle:connect6(ip, port)
  end
end

function Socket.prototype:setTimeout(msecs, callback)
  callback = callback or function() end
  self._connectTimer:start(msecs, 0, function(status)
    self._connectTimer:close()
    callback()
  end)
end

function Socket.prototype:close()
  if self._handle then
    self._handle:close()
  end
end

function Socket.prototype:write(data, callback)
  self.bytesWritten = self.bytesWritten + #data
  self._handle:write(data)
end

function Socket.prototype:connect(port, host, callback)
  if not self._handle then
    self._handle = tcp.new()
  end

  self._handle:on('connect', function()
    timer.clear_timer(self._connectTimer)
    self._handle:read_start()
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
    timer.clear_timer(self._connectTimer)
    callback(err)
  end)

  dns.lookup(host, function(err, ip, addressType)
    if err then
      timer.clear_timer(self._connectTimer)
      callback(err)
      return
    end
    self:_connect(ip, port, addressType)
  end)

  return self
end

Socket.new = function()
  local sock = Socket.new_obj()
  sock._connectTimer = timer.new()
  sock.bytesWritten = 0
  sock.bytesRead = 0
  return sock
end

Net.Socket = Socket

Net.createConnection = function(port, ... --[[ [host], [cb] --]])
  local args = {...}
  local host
  local callback
  local s

  -- future proof
  host = args[1]
  callback = args[2]

  s = Socket.new()
  return s:connect(port, host, callback)
end

Net.create = Net.createConnection

return Net
