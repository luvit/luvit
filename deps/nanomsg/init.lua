local uv = require('uv')
local timer = require('timer')
local utils = require('utils')
local Emitter = require('core').Emitter
local nn = require './nanomsg-ffi'

--[[ Socket ]]--
local Socket = Emitter:extend()
function Socket:initialize(address,type)
  self.address = address
  self.type = type
  
  self._socket,  self.err = nn.socket( nn[type] )
  assert(self._socket, nn.strerror(self.err) )

  self._sndfd = self._socket:getsockopt(nn.SOL_SOCKET, nn.SNDFD)
  self._rcvfd = self._socket:getsockopt(nn.SOL_SOCKET, nn.RCVFD)

  self._snd = assert(uv.new_socket_poll(self._sndfd))
  self._rcv = assert(uv.new_socket_poll(self._rcvfd))

  self:on('finish', utils.bind(self._onSocketFinish, self))
end

function Socket:_onSocketFinish()
  print("Socket",_onSocketFinish)
  return self:destroy()
end

function Socket:setTimeout(msecs, callback)
  if msecs > 0 then
    timer.enroll(self, msecs)
    timer.active(self)
    if callback then self:once('timeout', callback) end
  elseif msecs == 0 then
    timer.unenroll(self)
  end
end

function Socket:send(data, callback)
  if not self._socket then return end
  timer.active(self)
  local sz,err
  if type(data)=='string' then
    sz, err = self._socket:send(data,#data, nn.DONTWAIT)
  else
    sz, err = self._socket:send_zc(data, nn.DONTWAIT)
  end
  if callback then callback(err,sz) end
end

function Socket:recv(len)
  timer.active(self)
  local sz,data,err
  if len then
    local buf = ffi.new("char [?]",len)
    sz,err = self._socket:recv(buf, len, nn.DONTWAIT)
    if(sz>=0) then
      data = ffi.string(buf,sz)
    end
  else
    data,err = self._socket:recv_zc(nn.DONTWAIT)
  end

  if data then
    self:emit('data',data)
  else
    self:emit('error',err)
  end
end

function Socket:getopt(level, opt)
  return self._socket:getsockopt(level,opt)
end

function Socket:setopt(level, opt, optval, optvallen)
  return self._socket:setsockopt(level, opt, optval, optvallen )
end

function Socket:pause()
  if not self._socket then return end
  uv.read_stop(self._socket)
end

function Socket:resume()
  if not self._socket then return end
  if not self.onRead then return end

  uv.read_start(self._socket, self.onRead)
end

function Socket:bind(callback)
  assert(type(callback)=='function')
  timer.active(self)
  assert(self._socket)

  uv.poll_start(self._rcv, 'r', function(err,event)
    if err then
      self:emit('error', err)
    else
      self:recv()
    end
  end)

  local cid, err = self._socket:bind( self.address )
  print(cid,err)
  if not cid then
    self:emit('error', err)
  end
  callback(err)
  return self
end

function Socket:connect(callback)
  timer.active(self)
  assert(self._socket)

  uv.poll_start(self._snd, 'w', function(err,event)
    uv.poll_stop(self._snd)
    if err then
      self:emit('error',err)
      if callback then callback(err) end
      return
    end
    uv.poll_start(self._rcv, 'r', function(err,status)
      if err then
        self:emit('error',err)
      else
        self:recv()        
      end
    end)
    callback()
  end)

  local eid, err = self._socket:connect( self.address )
  print(cid,err)
  if not cid then
    self:emit('error', err)
  end
  return self  
end

function Socket:destroy(exception, callback)
  callback = callback or function() end
  if self.destroyed == true or self._socket == nil then
    return callback()
  end

  timer.unenroll(self)
  self.destroyed = true
  self.readable = false
  self.writable = false

  if uv.is_closing(self._socket) then
    timer.setImmediate(callback)
  else
    uv.close(self._socket, callback)
  end

  if exception then
    process.nextTick(function()
      self:emit('error', exception)
    end)
  end
end

-- Exports

exports.Socket = Socket

exports.bind = function(address,type, callback)
  local server = Socket:new(address, type)
  server:bind(callback)
  return server
end
exports.connect = function(address,type,callback)
  local client = Socket:new(address, type)
  client:connect(callback)
  return client
end
