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

local loaded, openssl = pcall(require, 'openssl')
if not loaded then return end

local Emitter = require('core').Emitter
local net = require('net')
local utils = require('utils')
local tlsCodec = require('codecs/tls')

local codec = require('codec')
local chain = codec.chain
local wrapStream = codec.wrapStream

local extend = function(...)
  local args = {...}
  local obj = args[1]
  for i=2, #args do
    for k,v in pairs(args[i]) do
      obj[k] = v
    end
  end
  return obj
end

local once = function(callback)
  local called = false
  return function(...)
    if called then return end
    called = true
    callback(...)
  end
end

local CleartextStream = Emitter:extend()

function CleartextStream:setStream(socket)
  self._socket = socket
end

function CleartextStream:destroy()
  if self._socket then self._socket:destroy() end
end

exports.connect = function(options, callback)
  local defaults, hostname, context, sock, cleartext, tlsChain, tls
  local port, onConnect, onError

  callback = callback or function() end

  -- Setup options
  defaults = {
    ciphers = DEFAULT_CIPHERS,
    rejectUnauthorized = true,
    -- TODO checkServerIdentity
  }

  options = extend(defaults, options or {})
  port = options.port
  hostname = options.servername or options.host or
     (options.socket and options.socket._host)

  cleartext = CleartextStream:new()
  tls = tlsCodec(options)
  tls.onsecureConnect = once(callback)
  tls.onerror = function(err)
    cleartext:emit('error', err)
  end

  function onConnect()
    local read1, write1 = codec.wrapStream(sock._handle)
    local read2, write2 = codec.wrapEmitter(cleartext)
    chain(tls.decoder)(read1, write2)
    chain(tls.encoder)(read2, write1)
  end

  function onError(err)
    cleartext:emit('error', err)
  end

  sock = net.create(port, hostname, onConnect)
  sock:on('error', onError)

  cleartext:setStream(sock)
  cleartext._tls = tls
  
  return cleartext
end
