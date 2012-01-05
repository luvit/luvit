local dns = require('dns')
local UV = require('uv')
local tcp = require('tcp')
local timer = require('timer')
local utils = require('utils')
local stream = require('stream')

local Net = {}

local _connect = function(self, ip, port, addressType)
  if port then
    self.remotePort = port
  end
  self.remoteAddress = address

  if addressType == 4 then
    self._tcp:connect(ip, port)
  elseif addressType == 6 then
    self._tcp:connect6(ip, port)
  end
end

local setTimeout = function(self, msecs, callback)
  callback = callback or function() end
  self._connectTimer:start(msecs, 0, function(status)
    self._connectTimer:close()
    callback()
  end)
end

local connect = function(self, port, host, callback)
  self._tcp:on('connect', function()
    timer.clear_timer(self._connectTimer)
    callback()
  end)
  self._tcp:on('error', function()
    timer.clear_timer(self._connectTimer)
    callback()
  end)
  dns.lookup(host, function(err, ip, addressType)
    if err then
      callback(err)
      return
    end
    _connect(self, ip, port, addressType)
  end)
end

local close = function(self)
  if self._tcp then
    self._tcp:close()
    self._tcp = nil
  end
end

local Socket = {}

Socket.new = function(options)
  local sock = {}
  utils.inherits(sock, stream)
  sock._tcp = tcp.new()
  sock._connectTimer = timer.new()
  sock.connect = connect
  sock.close = close
  sock.setTimeout = setTimeout
  return sock
end

Net.Socket = Socket

return Net
