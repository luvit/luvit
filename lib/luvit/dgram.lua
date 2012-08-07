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

-- Ported from node's dgram.js.

local dns = require('dns')
local net = require('net')
local Udp = require('uv').Udp
local Emitter = require('core').Emitter

local dgram = {}

local function lookup(address, family, callback)
  local matchedFamily = net.isIP(address)
  if matchedFamily then
    return callback(nil, address, matchedFamily)
  end
  return dns.lookup(address, family, callback)
end

local function lookup4(address, callback)
  return lookup(address or '0.0.0.0', 4, callback)
end

local function lookup6(address, callback)
  return lookup(address or '::0', 6, callback)
end

local function newHandle(family)
  if family == 'udp4' then
    local handle = Udp:new()
    handle.lookup = lookup4
    handle.bind = handle.bind
    handle.send = handle.send
    return handle
  end

  if family == 'udp6' then
    local handle = Udp:new()
    handle.lookup = lookup6
    handle.bind = handle.bind6
    handle.send = handle.send6
    return handle
  end

  error('Bad socket type specified. Valid types are: udp4, udp6')
end

--[[ Socket ]]--

local Socket = Emitter:extend()

dgram.Socket = Socket

function Socket:initialize(family, listener)
  self._handle = newHandle(family)
  self._receiving = false
  self._bound = false
  self._family = family

  self:_initEmitters()

  if type(listener) == 'function' then
    self:on('message', listener)
  end
end

function Socket:_initEmitters()
  self._handle:on('close', function(msg, rinfo)
    self._handle = nil
    self:emit('close')
  end)

  self._handle:on('message', function(msg, rinfo)
    self:emit('message', msg, rinfo)
  end)

  self._handle:on('error', function(err)
    self:emit('error', err)
  end)
end

function dgram.createSocket(family, listener)
  return Socket:new(family, listener)
end

function Socket:bind(port, address)
  self:_healthCheck()

  self._handle.lookup(address, function(err, ip)
    if err then
      process.nextTick(function()
        self:emit('error', err)
      end)
      return
    end

    self._handle:bind(ip, port or 0)
    self._bound = true
    self:_startReceiving()
    self:emit('listening')
  end)
end

function Socket:send(msg, port, address, callback)
  self:_healthCheck()
  self:_startReceiving()

  self._handle.lookup(address, function(err, ip)
    if err then
      if callback then callback(err) end
      self:emit('error', err)
      return
    end

    self._handle:send(msg, port, address, callback)
  end)
end

function Socket:close()
  self:_healthCheck()
  self:_stopReceiving()
  self._handle:close()
end

function Socket:address()
  self:_healthCheck()

  return self._handle:getsockname()
end

function Socket:setBroadcast(opt)
  self._handle:setBroadcast(opt and 1 or 0)
end

function Socket:setTTL(opt)
  self._handle:setTTL(opt)
end

function Socket:setMulticastTTL(opt)
  self._handle:setMulticastTTL(opt)
end

function Socket:setMulticastLoopback(opt)
  self._handle:setMulticastLoopback(opt and 1 or 0)
end

function Socket:setMembership(multicastAddress, interfaceAddress, op)
  self:_healthCheck()

  if not multicastAddress then
    error("multicast address must be specified")
  end

  if not multicastInterface then
    if self._family == 'udp4' then
      multicastInterface = '0.0.0.0'
    elseif self._family == 'udp6' then
      multicastInterface = '::0'
    end
  end

  self._handle:setMembership(multicastAddress, multicastInterface, op)
end

function Socket:addMembership(multicastAddress, interfaceAddress)
  self:setMembership(multicastAddress, interfaceAddress, 'join')
end

function Socket:dropMembership(multicastAddress, interfaceAddress)
  self:setMembership(multicastAddress, interfaceAddress, 'leave')
end

function Socket:_healthCheck()
  if not self._handle then
    error('self._handle uninitialized')
  end
end

function Socket:_startReceiving()
  if self._receiving then
    return
  end

  if not self._bound then
    self:bind()

    if not self._bound then
      error('implicit bind failed')
    end
  end

  self._handle:recvStart()
  self._receiving = true
end

function Socket:_stopReceiving()
  if not self._receiving then
    return
  end

  self._handle:recvStop()
  self._receiving = false
end

return dgram
