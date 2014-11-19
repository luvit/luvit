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

local Object = require('core').Object

local bit = require('bit')
local openssl = require('openssl')
local table = require('table')

local _root_ca = require('_root_ca')

local DEFAULT_CIPHERS = 'AES128-GCM-SHA256:RC4:HIGH:!MD5:!aNULL:!EDH'

local DEFAULT_CERT_STORE

local function getSecureOptions(protocol, options)
  return bit.bor(openssl.ssl.no_sslv2,
                 openssl.ssl.no_sslv3,
                 openssl.ssl.no_compression)
end

local Credential = Object:extend()
function Credential:initialize(secureProtocol, defaultCiphers, flags, rejectUnauthorized, context)
  self.rejectUnauthorized = rejectUnauthorized

  if context then
    self.context = context
  else
    self.context = openssl.ssl.ctx_new(
      secureProtocol or 'SSLv23',
      defaultCiphers or DEFAULT_CIPHERS
    )
    self.context:options(getSecureOptions(secureProtocol, flags))
  end
end

function Credential:addRootCerts()
  if not DEFAULT_CERT_STORE then
    DEFAULT_CERT_STORE = openssl.x509.store:new()
    for _, v in pairs(_root_ca.roots) do
      DEFAULT_CERT_STORE:add(assert(openssl.x509.read(v)))
    end
  end
  self.context:cert_store(DEFAULT_CERT_STORE)
end

function Credential:addCACert(certs)
  local store = openssl.x509.store:new()
  if type(certs) == 'table' then
    for _, v in pairs(certs) do
      store:add(openssl.x509.read(v))
    end
  else
    store:add(openssl.x509.read(certs))
  end
  self.context:cert_store(store)
end

local function createCredentials(options, context)
  local c

  options = options or {}

  c = Credential:new(options.secureProtocol,
                     options.ciphers,
                     options.secureOptions,
                     options.rejectUnauthorized,
                     context)
  if context then
    return c
  end

  --if options.key then
  --  if options.passphrase then
  --    c.context:setKey(options.key, options.passphrase)
  --  else
  --    c.context:setKey(options.key)
  --  end
  --end

  --if options.cert then
  --  dbg('Setting Certificate')
  --  c.context:setCert(options.cert)
  --end

  if options.ca then
    c:addCACert(options.ca)
  else
    c:addRootCerts()
  end

  --if options.crl then
  --  dbg('Setting CRL')
  --  if type(options.crl) == 'table' then
  --    for _, v in pairs(options.crl) do
  --      c.context:addCRL(v)
  --    end
  --  else
  --    c.context:addCRL(options.crl)
  --  end
  --end

  --if options.sessionIdContext then
  --  dbg('Setting SessionIdContext')
  --  c.context:setSessionIdContext(options.sessionIdContext)
  --end
  --]]
  c.context:set_verify({"none"})

  return c
end

--[[
callbacks
   onsecureConnect -- When handshake completes successfully
]]--

return function (options)
  local ctx, bin, bout, ssl, outerWrite, outerRead, waiting, handshake, sslRead
  local tls = {}

  -- Both sides will call handshake as they are hooked up
  -- But the first to call handshake will simply wait
  -- And the second will perform the handshake and then
  -- resume the other.
  function handshake()
    if outerWrite and outerRead then
      while true do
        if ssl:handshake() then
          tls.verify()
          break
        end
        outerWrite(bout:read())
        local data = outerRead()
        if data then bin:write(data) end
      end
      assert(coroutine.resume(waiting))
      waiting = nil
    else
      waiting = coroutine.running()
      coroutine.yield()
    end
  end

  function sslRead()
    return ssl:read()
  end

  function tls.verify()
    if ctx.rejectUnauthorized then
      local ok, err = ssl:getpeerverification()
      if ok and tls.onsecureConnect then return tls.onsecureConnect() end
      if tls.onerror then
        tls.onerror(err)
      end
    else
      if tls.onsecureConnect then tls.onsecureConnect() end
    end
  end

  function tls.createContext(options)
    ctx = createCredentials(options)

    bin, bout = openssl.bio.mem(8192), openssl.bio.mem(8192)
    ssl = ctx.context:ssl(bin, bout, false)

    tls.ctx = ctx.context
    tls.ssl = ssl
  end

  function tls.decoder(read, write)
    outerRead = read
    handshake()
    for cipher in read do
      bin:write(cipher)
      for data in sslRead do
        write(data)
      end
    end
    write()
  end

  function tls.encoder(read, write)
    outerWrite = write
    handshake()
    for plain in read do
      ssl:write(plain)
      while bout:pending() > 0 do
        local data = bout:read()
        write(data)
      end
    end
    ssl:shutdown()
    write()
  end

  tls.createContext(options)

  return tls
end
