--[[

Copyright 2014-2015 The Luvit Authors. All Rights Reserved.

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

exports.name = "luvit/tls"
exports.version = "1.0.3"

local loaded = pcall(require, 'openssl')
if not loaded then return end

local _common_tls = require('./common')
local net = require('net')


local DEFAULT_CIPHERS = _common_tls.DEFAULT_CIPHERS

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

local Server = net.Server:extend()
function Server:init(options, connectionListener)
  options = options or {}
  options.server = true

  local sharedCreds = _common_tls.createCredentials(options)
  net.Server.init(self, options, function(raw_socket)
    local socket
    socket = _common_tls.TLSSocket:new(raw_socket, {
      secureContext = sharedCreds,
      isServer = true,
      requestCert = options.requestCert,
      rejectUnauthorized = options.rejectUnauthorized,
    })
    socket:on('secureConnection', function()
      connectionListener(socket)
    end)
  end)
end

local DEFAULT_OPTIONS = {
  ciphers = DEFAULT_CIPHERS,
  rejectUnauthorized = true,
  -- TODO checkServerIdentity
}

exports.connect = function(options, callback)
  local hostname, port, sock

  callback = callback or function() end
  options = extend({}, DEFAULT_OPTIONS, options or {})
  port = options.port
  hostname = options.servername or options.host

  sock = _common_tls.TLSSocket:new(nil, options)
  sock:connect(port, hostname, callback)
  return sock
end

exports.createServer = function(options, secureCallback)
  local server = Server:new()
  server:init(options, secureCallback)
  return server
end
