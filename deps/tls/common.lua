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
local net = require('net')
local openssl = require('openssl')
local timer = require('timer')
local utils = require('utils')
local uv = require('uv')


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

do
  local data = module:load("root_ca.dat")
  exports.DEFAULT_CA_STORE = openssl.x509.store:new()
  local index = 1
  local len = #data
  while index < len do
    local len = bit.bor(bit.lshift(data:byte(index), 8), data:byte(index + 1))
    index = index + 2
    local cert = assert(openssl.x509.read(data:sub(index, index + len)))
    index = index + len
    assert(exports.DEFAULT_CA_STORE:add(cert))
  end
end

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

  if socket then
    self._connecting = socket._connecting
  end

  self:once('end', function()
    self:destroy()
  end)

  self:read(0)
end

function TLSSocket:_init()
  self.ctx = self.options.secureContext or
             self.options.credentials or
             exports.createCredentials(self.options)
  self.inp = openssl.bio.mem(8192)
  self.out = openssl.bio.mem(8192)
  self.ssl = self.ctx.context:ssl(self.inp, self.out, self.server)

  if (not self.server) then
    if self.options.servername then
      self.ssl:set('hostname',self.options.servername)
    end
    if self.ctx.session then
      self.ssl:session(self.ctx.session)
    end
  end
end

function TLSSocket:getPeerCertificate()
  return self.ssl:peer()
end

function TLSSocket:_verifyClient()
  if self.ssl:session_reused() then
    self.sessionReused = true
    self:emit('secureConnection', self)
  else
    local verifyError, verifyResults
    self.ctx.session = self.ssl:session()
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

  local hasShutdown = false
  local function reallyShutdown()
    if hasShutdown then return end
    hasShutdown = true
    net.Socket.destroy(self, err)
  end

  local function shutdown()
    timer.active(self)
    if self._shutdown then
      local _, shutdown_err = self.ssl:shutdown()
      if shutdown_err == "want_read" or shutdown_err == "want_write" or shutdown_err == "syscall" then
        local r = self.out:pending()
        if r > 0 then
          timer.active(self._shutdownTimer)
          net.Socket._write(self, self.out:read(), function(err)
            timer.active(self._shutdownTimer)
            if err then
              self._shutdown = false
              return reallyShutdown()
            end
            shutdown()
          end)
        end
      else
        self._shutdown = false
        return reallyShutdown()
      end
    end
  end

  local function onShutdown(read_err, data)
    timer.active(self)
    if read_err or not data then
      return reallyShutdown()
    end
    timer.active(self._shutdownTimer)
    self.inp:write(data)
    shutdown()
  end

  if self.destroyed or self._shutdown then return end
  if self.ssl and self.authorized then
    if not self._shutdownTimer then
      self._shutdownTimer = timer.setTimeout(5000, reallyShutdown)
    end
    self._shutdown = true
    uv.read_stop(self._handle)
    uv.read_start(self._handle, onShutdown)
    self:emit('shutdown')
    shutdown()
  else
    reallyShutdown()
  end
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

function TLSSocket:sni(hosts)
  if self.server then
    local maps = {}
    for k,v in pairs(hosts) do
      local ctx = exports.createCredentials(v)
      maps[k] = ctx.context
    end
    self.ctx.context:set_servername_callback(maps)
  end
end

function TLSSocket:_write(data, callback)
  local ret, i, err
  if not self.ssl or self.destroyed or self._shutdown or not self._connected then
    return
  end
  if data then
    ret, err = self.ssl:write(data)
    if ret == nil then
      return self:destroy(err)
    end
  end
  i = self.out:pending()
  if i > 0 then
    net.Socket._write(self, self.out:read(), callback)
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
          local plainText, op = self.ssl:read()
          if not plainText then
            if op == 0 then
              return net.Socket.destroy(self)
            else
              return
            end
          else
            self:push(plainText)
          end
        until not plainText
      end
    else
      self.ssl = nil
      self:push(nil)
      self:emit('_socketEnd')
    end
  end

  function handshake()
    if not self._connected then
      local ret, err = self.ssl:handshake()
      if ret == nil then
        return net.Socket.destroy(self, err)
      else
        local i = self.out:pending()
        if i > 0 then
          net.Socket._write(self, self.out:read(), function(err)
            if err then return self:shutdown(err) end
            handshake()
          end)
        end
      end

      if ret == false then return end

      self._connected = true
      self._handshake_complete = true

      if not uv.is_active(self._handle) then return end
      uv.read_stop(self._handle)
      uv.read_start(self._handle, onData)
      self:emit('secure')
    end
  end

  function onHandshake(err, data)
    timer.active(self)
    if err then
      return net.Socket.destroy(self, err)
    end
    if not data then
      return net.Socket.destroy(self)
    end
    self.inp:write(data)
    handshake()
  end

  if self._connecting then
    self:once('connect', utils.bind(self._read, self, n))
  elseif not self._reading and not self._handshake_complete then
    self._reading = true
    uv.read_start(self._handle, onHandshake)
    handshake()
  elseif not self._reading then
    self._reading = true
    uv.read_start(self._handle, onData)
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
