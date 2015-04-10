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

local Object = require('core').Object
local Error = require('core').Error
local bit = require('bit')
local net = require('net')
local openssl = require('openssl')
local timer = require('timer')
local utils = require('utils')
local uv = require('uv')

local _root_ca = require('./root_ca')

local DEFAULT_CIPHERS = 'ECDHE-RSA-AES128-SHA256:AES128-GCM-SHA256:' .. -- TLS 1.2
                        'RC4:HIGH:!MD5:!aNULL:!EDH'                     -- TLS 1.0
exports.DEFAULT_CIPHERS = DEFAULT_CIPHERS

-------------------------------------------------------------------------------

local getSecureOptions = function(protocol, flags)
  return bit.bor(openssl.ssl.no_sslv2,
                 openssl.ssl.no_sslv3,
                 openssl.ssl.no_compression,
                 flags or 0)
end

-------------------------------------------------------------------------------

local loadRootCAStore = function()
  local store = openssl.x509.store:new()
  for _, cert in pairs(_root_ca.roots) do
    cert = assert(openssl.x509.read(cert))
    assert(store:add(cert))
  end
  return store
end

exports.DEFAULT_CA_STORE = loadRootCAStore()

-------------------------------------------------------------------------------

local Credential = Object:extend()
function Credential:initialize(secureProtocol, defaultCiphers, flags, rejectUnauthorized, context)
  self.rejectUnauthorized = rejectUnauthorized
  if context then
    self.context = context
  else
    self.context = openssl.ssl.ctx_new(secureProtocol or 'TLSv1',
      defaultCiphers or DEFAULT_CIPHERS)
    self.context:mode(true, 'release_buffers')
    self.context:options(getSecureOptions(secureProtocol, flags))
  end
end

function Credential:addRootCerts()
  self.context:cert_store(exports.DEFAULT_CA_STORE)
end

function Credential:setCA(certs)
  if not self.store then
    self.store = openssl.x509.store:new()
    self.context:cert_store(self.store)
  end
  if type(certs) == 'table' then
    for _, v in pairs(certs) do
      local cert = assert(openssl.x509.read(v))
      assert(self.store:add(cert))
    end
  else
    local cert = assert(openssl.x509.read(certs))
    assert(self.store:add(cert))
  end
end

function Credential:setKeyCert(key, cert)
  key = assert(openssl.pkey.read(key, true))
  cert = assert(openssl.x509.read(cert))
  self.context:use(key, cert)
end

exports.Credential = Credential

-------------------------------------------------------------------------------

local TLSSocket = net.Socket:extend()
function TLSSocket:initialize(socket, options)

  if socket then
    net.Socket.initialize(self, { handle = socket._handle })
  else
    net.Socket.initialize(self)
  end

  self.options = options
  self.ctx = options.secureContext
  self.server = options.isServer
  self.requestCert = options.requestCert
  self.rejectUnauthorized = options.rejectUnauthorized

  if self._handle == nil then
    self:once('connect', utils.bind(self._init, self))
  else
    self:_init()
  end

  self._connected = false
  self.encrypted = true
  self.readable = true
  self.writable = true

  if self.server then
    self._connecting = false
    self:once('secure', utils.bind(self._verifyServer, self))
  else
    self._connecting = true
    self:once('secure', utils.bind(self._verifyClient, self))
  end

  self:read(0)
end

function TLSSocket:_init()
  self.ctx = self.options.secureContext or
             self.options.credentials or
             exports.createCredentials(self.options)
  self.inp = openssl.bio.mem(8192)
  self.out = openssl.bio.mem(8192)
  self.ssl = self.ctx.context:ssl(self.inp, self.out, self.server)
end

function TLSSocket:getPeerCertificate()
  return self.ssl:peer()
end

function TLSSocket:_verifyClient()
  local verifyError, verifyResults

  verifyError, verifyResults = self.ssl:getpeerverification()
  if verifyError then
    self.authorized = true
    self:emit('secureConnection', self)
  else
    self.authorized = false
    self.authorizationError = verifyResults[1].error_string
    if self.rejectUnauthorized then
      local err = Error:new(self.authorizationError)
      self:destroy(err)
    else
      self:emit('secureConnection', self)
    end
  end
end

function TLSSocket:_verifyServer()
  if self.requestCert then
    local peer, verify, err
    peer = self.ssl:peer()
    if peer then
      verify, err = self.ssl:getpeerverification()
      self.authorizationError = err
      if verify then
        self.authorized = true
      elseif self.rejectUnauthorized then
        self:destroy(err)
      end
    elseif self.rejectUnauthorized then
      self:destroy(Error:new('reject unauthorized'))
    end
  end
  if not self.destroyed then
    self:emit('secureConnection', self)
  end
end

function TLSSocket:destroy(err)
   if self.ssl then
     self.ssl:shutdown()
   end
   net.Socket.destroy(self, err)
end

function TLSSocket:connect(...)
  local args = {...}
  local secureCallback

  if type(args[#args]) == 'function' then
    secureCallback = args[#args]
    args[#args] = nil
  end

  self:on('secureConnection', secureCallback)
  net.Socket.connect(self, unpack(args))
end

function TLSSocket:_write(data, encoding, callback)
  local ret, i, err
  if not self.ssl then
    return
  end
  ret, err = self.ssl:write(data)
  if ret == nil then
    return self:destroy(err)
  end
  i = self.out:pending()
  if i > 0 then
    net.Socket._write(self, self.out:read(), encoding, callback)
  end
end

function TLSSocket:_read(n)
  local onHandshake, onData, handshake

  function onData(err, cipherText)
    timer.active(self)
    if err then
      return self:destroy(err)
    elseif cipherText then
      if self.inp:write(cipherText) then
        repeat
          local plainText = self.ssl:read()
          if plainText then self:push(plainText) end
        until not plainText
      end
    else
      self:push(nil)
      self:emit('_socketEnd')
    end
  end

  function handshake()
    if not self._connected then
      local ret, err = self.ssl:handshake()
      if ret == nil then
        return self:destroy(err)
      else
        local i = self.out:pending()
        if i > 0 then
          net.Socket._write(self, self.out:read(), nil, function()
            handshake()
          end)
        end
      end

      if ret == false then return end

      self._connected = true

      if not uv.is_active(self._handle) then return end
      uv.read_stop(self._handle)
      uv.read_start(self._handle, onData)
      self:emit('secure')
    end
  end

  function onHandshake(err, data)
    timer.active(self)
    if err then
      return self:destroy(err)
    end
    if not data then
      self:destroy()
      return
    end
    self.inp:write(data)
    handshake()
  end

  if self._connecting then
    self:once('connect', utils.bind(self._read, self, n))
  elseif not self._reading then
    self._reading = true
    uv.read_start(self._handle, onHandshake)
    handshake()
  end
end

exports.TLSSocket = TLSSocket

-------------------------------------------------------------------------------
local VERIFY_PEER = { "peer" }
local VERIFY_PEER_FAIL = { "peer", "fail_if_no_peer_cert" }
local VERIFY_NONE = { "none" }

exports.createCredentials = function(options, context)
  local ctx, returnOne

  options = options or {}

  ctx = Credential:new(options.secureProtocol, options.ciphers,
    options.secureOptions, options.rejectUnauthorized, context)
  if context then
    return ctx
  end

  if options.key and options.cert then
    ctx:setKeyCert(options.key, options.cert)
  end

  if options.ca then
    ctx:setCA(options.ca)
  else
    ctx:addRootCerts()
  end

  function returnOne()
    return 1
  end

  if options.server then
    if options.requestCert then
      if options.rejectUnauthorized then
        ctx.context:verify_mode(VERIFY_PEER_FAIL, returnOne)
      else
        ctx.context:verify_mode(VERIFY_PEER, returnOne)
      end
    else
      ctx.context:verify_mode(VERIFY_NONE, returnOne)
    end
  else
    ctx.context:verify_mode(VERIFY_NONE, returnOne)
  end

  return ctx
end
