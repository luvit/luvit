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

exports.DEFAULT_CIPHERS = 'ECDHE-RSA-AES128-SHA256:AES128-GCM-SHA256:' .. -- TLS 1.2
                          'RC4:HIGH:!MD5:!aNULL:!EDH'                     -- TLS 1.0

-------------------------------------------------------------------------------

local getSecureOptions = function(protocol, options)
  return bit.bor(openssl.ssl.no_sslv2,
                 openssl.ssl.no_sslv3,
                 openssl.ssl.no_compression)
end

-------------------------------------------------------------------------------

local CertificateStoreCtx = Object:extend()
function CertificateStoreCtx:initialize(ctx)
  self.ctx = ctx
  self.cert_store = openssl.x509.store:new()
end

function CertificateStoreCtx:add(cert)
  p('adding', cert:subject())
  return self.cert_store:add(cert)
end

function CertificateStoreCtx:load(filename)
  return self.cert_store:load(filename)
end

exports.CertificateStoreCtx = CertificateStoreCtx

-------------------------------------------------------------------------------

local Credential = Object:extend()
function Credential:initialize(secureProtocol, defaultCiphers, flags, rejectUnauthorized, context)
  self.rejectUnauthorized = rejectUnauthorized

  if context then
    self.context = context
  else
    self.context = openssl.ssl.ctx_new(secureProtocol or 'TLSv1',
      defaultCiphers or DEFAULT_CIPHERS)
    self.context:options(getSecureOptions(secureProtocol, flags))
  end
end

function Credential:addRootCerts()
  local store = self.context:cert_store()
  for _, cert in pairs(_root_ca.roots) do
    cert = assert(openssl.x509.read(cert))
    p(cert)
    p(cert:subject())
    assert(store(cert))
  end
  p('addRootCerts end')
end

function Credential:addCACert(certs)
  local new_store = false, cert
  if not self.store then
    self.store = CertificateStoreCtx:new(self.context)
    new_store = true
  end
  self.store:load('test.pem')
  if type(certs) == 'table' then
    for _, cert in pairs(certs) do
      cert = openssl.x509.read(cert)
      self.store:add(cert)
    end
  else
    cert = openssl.x509.read(certs)
    self.store:add(cert)
  end
  if new_store then
    self.context:cert_store(self.store.cert_store)
  end
end

function Credential:createBIO()
  return openssl.bio.mem(8192), openssl.bio.mem(8192)
end

function Credential:createSSLContext(bin, bout, server)
  return self.context:ssl(bin, bout, server)
end

exports.Credential = Credential

-------------------------------------------------------------------------------

exports.createCredentials = function(options, context)
  local ctx
  options = options or {}
  ctx = Credential:new(options.secureProtocol, options.ciphers,
                       options.secureOptions, options.rejectUnauthorized,
                       context)
  if context then
    return ctx
  end

  ctx.context:set_verify({"none"}, function()
    return 1
  end)

  return ctx
end
