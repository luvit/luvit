local dns = require('dns')
local UV = require('uv')
local tcp = require('tcp')
local timer = require('timer')
local utils = require('utils')
local Emitter = require('emitter')

local Net = {}

--[[ Server ]]--

local Server = { }
utils.inherits(Server, Emitter)

function Server.prototype:listen(port, ... --[[ ip, callback --]] )
  local args = {...}
  local ip
  local callback

  if not self._handle then
    self._handle = tcp.new()
  end

  -- Future proof
  if type(args[1]) == 'function' then
    ip = '0.0.0.0'
    callback = args[1]
  else
    ip = args[1]
    callback = args[2] or function() end
  end

  self._handle:bind(ip, port)
  self._handle:on('listening', callback)
  self._handle:on('error', function(err)
    return self:emit("error", err)
  end)
  self._handle:listen(function(err)
    if (err) then
      return self:emit("error", err)
    end
    local client = tcp.new()
    self._handle:accept(client)
    client:read_start()
    self:emit('connection', client)
  end)
end

Server.new = function(...)
  local args = {...}
  local options
  local clientCallback

  if #args == 1 then
    clientCallback = args[1]
  elseif #args == 2 then
    options = args[1]
    clientCallback = args[2]
  end

  local server = Server.new_obj()
  server:on('connection', clientCallback)
  return server
end

--[[ Socket ]]--

local Socket = { }
utils.inherits(Socket, Emitter)

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

function Socket.prototype:pipe(destination)
  self._handle:pipe(destination)
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
    self:close()
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

Net.Server = Server

Net.Socket = Socket

Net.createConnection = function(port, ... --[[ host, cb --]])
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

Net.createServer = function(clientCallback)
  local s = Server.new(clientCallback)
  return s
end

return Net
