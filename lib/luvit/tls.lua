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
local tlsbinding = require('_tls')
local Buffer = require('buffer').Buffer
local Object = require('core').Object
local Emitter = require('core').Emitter
local iStream = require('core').iStream
local Socket = require('net').Socket
local timer = require('timer')
local table = require('table')
local net = require('net')
local bind = require('utils').bind

local Error = require('core').Error

local string = require('string')
local fmt = string.format

local END_OF_FILE = 42
local DEBUG = false

local function dbg(format, ...)
  if DEBUG == true then
    print(fmt(format, {...}))
  end
end

--[[ Credential ]]--

local Credential = Object:extend()
function Credential:initialize(secureProtocol, flags, context)
  dbg('Credential:initialize')
  if context then
    self.context = context
  else
    self.context = tlsbinding.secure_context()
  end
end

local function createCredentials(options, context)
  options = options or {}

  dbg('Create Credential')

  local c = Credential:new(options.secureProtocol, options.secureOptions, context)

  if context then
    return c
  end

  if options.key then
    if options.passphrase then
      dbg('Setting Key w/ Passphrase')
      c.context:setKey(options.key, options.passphrase)
    else
      dbg('Setting Key w/out Passphrase')
      c.context:setKey(options.key)
    end
  end

  if options.cert then
    dbg('Setting Certificate')
    c.context:setCert(options.cert)
  end

  if options.ciphers then
    dbg('Setting Ciphers')
    c.context:setCiphers(options.ciphers)
  end

  if options.ca then
    dbg('Setting CA')
    if type(options.ca) == 'table' then
      for _, v in pairs(options.ca) do
        c.context:addCACert(v)
      end
    else
      c.context:addCACert(options.ca)
    end
  else
    c.context:addRootCerts()
  end

  if options.crl then
    dbg('Setting CRL')
    if type(options.crl) == 'table' then
      for _, v in pairs(options.crl) do
        c.context:addCRL(v)
      end
    else
      c.context:addCRL(options.crl)
    end
  end

  if options.sessionIdContext then
    dbg('Setting SessionIdContext')
    c.context:setSessionIdContext(options.sessionIdContext)
  end

  return c
end

--[[ CryptoStream ]]--

local CryptoStream = iStream:extend()
function CryptoStream:initialize(pair, typeString)
  self.pair = pair
  self.readable = true
  self.writable = true
  self._paused = false
  self._pending = {}
  self._pendingCallbacks = {}
  self._pendingBytes = 0
  self._needDrain = false
  self._closing = false
  self._type = typeString
end

function CryptoStream:write(data, ...)
  dbg('CryptoStream:write')

  if #data == 0 then
    return
  end

  if self._type == 'cleartextstream' then
    dbg('cleartext.write called with length ' .. #data)
  else
    dbg('encrypted.write called with length ' .. #data)
  end

  local args = {...}, callback

  if type(args[1]) == 'string' then
    encoding = args[1]
    callback = args[2]
  else
    encoding = ''
    callback = args[1]
  end

  table.insert(self._pending, data)
  table.insert(self._pendingCallbacks, callback)
  self._pendingBytes = self._pendingBytes + #data
  self.pair._writeCalled = true
  self.pair:cycle()

  if self._needDrain == false then
    if self._pendingBytes >= (128 * 1024) then
      self._needDrain = true
    else
      if self._type == 'cleartextstream' then
        self._needDrain = self.pair.encrypted._paused
      else
        self._needDrain = self.pair.cleartext._paused
      end
    end
  end

  return not self._needDrain
end

function CryptoStream:pause()
  dbg('pause')
  self._paused = true
end

function CryptoStream:resume()
  dbg('resume')
  self._paused = false
  self.pair:cycle()
end

function CryptoStream:setTimeout(n)
  dbg('setTimeout')
  if self.socket then
    self.socket:setTimeout(n)
  end
end

function CryptoStream:getSession()
  dbg('getSession')
  return self.pair.ssl:getSession()
end

function CryptoStream:getCipher()
  dbg('getCipher')
  return self.pair.ssl:getCurrentCipher()
end

function CryptoStream:destroySoon()
  dbg('destroySoon')
  if self.writable == true then
    self:done()
  else
    self:destroy()
  end
end

function CryptoStream:done(d)
  dbg('done')
  if self.pair._doneFlag then
    return
  end

  if self.writable == false then
    return
  end

  if d then
    self:write(d)
  end

  self.writable = false

  self.pair:cycle()
end

function CryptoStream:getPeerCertificate()
  if self.pair.ssl then
    local c = self.pair.ssl:getPeerCertificate()
    if c then
      return c
    end
  end
  return nil
end

function CryptoStream:destroy()
  dbg('destroy')
  if self.pair._doneFlag == true then
    return
  end
  self.pair:destroy()
end

function CryptoStream:_done()
  dbg('_done')
  self._doneFlag = true

  if self.pair.cleartext._doneFlag == true and
     self.pair.encrypted._doneFlag == true and
     self.pair._doneFlag == false then
    if self.pair._secureEstablished == false then
      self.pair:err()
    else
      self.pair:destroy()
    end
  end
end

function CryptoStream:_push()
  dbg('_push')
  if self._type == 'encryptedstream' and self.writable == false then
    return
  end

  while self._paused == false do
    local bytesRead = 0
    local data = ''
    local chunkBytes
    local tmpData
    local MAX_BUFFER_LENGTH = 16 * 4096

    repeat
      chunkBytes, tmpData = self:_pusher()

      if self.pair.ssl and self.pair.ssl:getError() then
        self.pair:err()
        return
      end

      self.pair:maybeInitFinished()

      if chunkBytes > 0 then
        data  = data .. tmpData
      end
    until chunkBytes <= 0 or #data > MAX_BUFFER_LENGTH

    assert(#data >= 0)

    if #data == 0 then
      if self:_internallyPendingBytes() == 0 then
        self:_done()
      end
      return
    end

    if self._type == 'encryptedstream' then
      dbg('encrypted emit data with ' .. #data .. ' bytes')
    else
      dbg('cleartext emit data with ' .. #data .. ' bytes')
    end
    self:emit('data', data)
  end
end

function CryptoStream:_pull()
  dbg('CryptoStream:_pull')

  while #self._pending > 0 do
    local tmp = table.remove(self._pending)
    local callback = table.remove(self._pendingCallbacks)

    if #tmp ~= 0 then
      local rv = self:_puller(tmp)

      if self.pair.ssl and self.pair.ssl:getError() then
        p('error function')
        self.pair:err()
        return
      end

      self.pair:maybeInitFinished()

      if rv <= 0 then
        table.insert(self._pending, 1, tmp)
        table.insert(self._pendingCallbacks, 1, callback)
        break
      end

      self._pendingBytes = self._pendingBytes - #tmp

      if callback then
        callback()
      end
    end
  end

  if self._needDrain == true and #self._pending == 0 then
    local paused
    if self._type == 'cleartextstream' then
      paused = self.pair.encrypted._paused
    else
      paused = self.pair.cleartext._paused
    end
    if paused == false then
      timer.setTimeout(0, function()
        self:emit('drain')
      end)
      self._needDrain = false
    end
  end
end

function string:split(sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  self:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

function parseCertString(s)
  local out = {}
  local parts = s:split('\n')
  for i, k in ipairs(parts) do
    local sepIndex = parts[i]:find('=')
    if sepIndex then
      local key = parts[i]:sub(0, sepIndex - 1)
      local value = parts[i]:sub(sepIndex + 1)
      if out[key] then
        if type(out[key]) ~= 'table' then
          out[key] = { out[key] }
        end
        table.insert(out[key], value)
      else
        out[key] = value
      end
    end
  end
  return out
end

function CryptoStream:getPeerCertificate()
  if self.pair.ssl then
    local c = self.pair.ssl:getPeerCertificate()
    if c then
      if c.issuer then c.issuer = parseCertString(c.issuer) end
      if c.subject then c.subject = parseCertString(c.subject) end
    end
    return c
  end
  return nil
end

--[[ CleartextStream ]]--

local CleartextStream = CryptoStream:extend()
function CleartextStream:initialize(pair)
  CryptoStream.initialize(self, pair, 'cleartextstream')
end

function CleartextStream:_internallyPendingBytes()
  if self.pair.ssl then
    dbg('CleartextStream_internallyPendingBytes')
    return self.pair.ssl:clearPending()
  else
    return 0
  end
end

function CleartextStream:_puller(d)
  dbg('CleartextStream:_puller')
  return self.pair.ssl:clearIn(d)
end

function CleartextStream:_pusher()
  dbg('CleartextStream:_pusher')
  if not self.pair.ssl then
    return -1
  end
  return self.pair.ssl:clearOut()
end

function CleartextStream:destroy()
  if self.socket and self._closing ~= true then
    self.socket:destroy()
  end
  self._closing = true
end

function CleartextStream:address()
  return self.socket and self.socket:address()
end

--[[ EncryptedStream ]]--

local EncryptedStream = CryptoStream:extend()
function EncryptedStream:initialize(pair)
  dbg('EncryptedStream:initialize')
  CryptoStream.initialize(self, pair, 'encryptedstream')
end

function EncryptedStream:_internallyPendingBytes()
  dbg('EncryptedStream:_internallyPendingBytes')
  return self.pair.ssl:encPending()
end

function EncryptedStream:_puller(d)
  dbg('EncryptedStream:_puller')
  return self.pair.ssl:encIn(d)
end

function EncryptedStream:_pusher()
  dbg('EncryptedStream:_pusher')
  if not self.pair.ssl then
    return -1
  end
  return self.pair.ssl:encOut()
end

--[[ Secure Pair ]]--

local SecurePair = Emitter:extend()
function SecurePair:initialize(credentials, isServer, requestCert, rejectUnauthorized, options)
  options = options or {}

  dbg('SecurePair:initialize')
  self._secureEstablished = false
  self._isServer = isServer
  self._rejectUnauthorized = rejectUnauthorized

  if self._isServer == false then
    requestCert = true
  end

  self._requestCert = requestCert or false

  self._cycleEncryptedPullLock = false
  self._cycleEncryptedPushLock = false
  self._cycleCleartextPullLock = false
  self._cycleCleartextPushLock = false

  if credentials then
    self.credentials = credentials
  else
    self.credentials = createCredentials()
  end

  local certOrServerName
  if self._isServer == true then
    certOrServerName = self._requestCert
  else
    if not options.servername then
      error('servername is a required parameter')
    end
    certOrServerName = options.servername
  end

  self.ssl = tlsbinding.connection(self.credentials.context,
    self._isServer == true,
    certOrServerName,
    self._rejectUnauthorized
  )

  -- setup SNI
  if self._isServer == true and options.SNICallback then
    self.ssl:setSNICallback(options.SNICallback)
  end

  self.cleartext = CleartextStream:new(self)
  self.encrypted = EncryptedStream:new(self)

  timer.setTimeout(0, function()
    if self.ssl then
      self.ssl:start()
    end
    self:cycle()
  end)
end

function SecurePair:cycle(depth)
  dbg('cycle')

  if self._doneFlag == true then
    return
  end

  depth = depth or 0

  if depth == 0 then
    self._writeCalled = false
  end

  local established = self._secureEstablished

  if self._cycleEncryptedPullLock == false then
    self._cycleEncyptedPullLock = true
    self.encrypted:_pull()
    self._cycleEncyptedPullLock = false
  end

  if self._cycleCleartextPullLock == false then
    self._cycleCleartextPullLock = true
    self.cleartext:_pull()
    self._cycleCleartextPullLock = false
  end

  if self._cycleCleartextPushLock == false then
    self._cycleCleartextPushLock = true
    self.cleartext:_push()
    self._cycleCleartextPushLock = false
  end

  if self._cycleEncryptedPushLock == false then
    self._cycleEncryptedPushLock = true
    self.encrypted:_push()
    self._cycleEncryptedPushLock = false
  end

  if (established == false and self._secureEstablished == true) or
     (depth == 0 and self._writeCalled == true) then
    self:cycle(depth + 1)
  end
end

function SecurePair:maybeInitFinished()
  dbg('maybeInitFinished')
  if self.ssl and self._secureEstablished == false and self.ssl:isInitFinished() == true then
    self._secureEstablished = true
    self.serverName = self.ssl:getServerName()
    self:emit('secure')
  end
end

function SecurePair:destroy()
  dbg('SecurePair:destroy')
  if self._doneFlag == true then
    return
  end

  self._doneFlag = true
  self.ssl:close()
  self.ssl = nil

  self.encrypted.writable = false
  self.encrypted.readable = false
  self.cleartext.writable = false
  self.cleartext.readable = false

  timer.setTimeout(0, function()
    self.cleartext:emit('end')
    self.encrypted:emit('close')
    self.cleartext:emit('close')
  end)
end

function SecurePair:err()
  dbg('SecurePair:err')
  if self._secureEstablished == false then
    local ssl_err, ssl_err_str = self.ssl:getError()
    local err = nil
    if not ssl_err then
      err = Error:new('socket hang up')
      err.code = 'ECONNRESET'
    else
      err = Error:new(ssl_err_str)
      err.code = ssl_err
    end
    self:emit('error', err)
    self:destroy()
  else
    local err = self.ssl:getError()
    self.ssl:clearError()
    self.cleartext:emit('error', err)
  end
end

--[[ Private ]]--

function pipe(pair, socket)
  pair.encrypted:pipe(socket)
  socket:pipe(pair.encrypted)

  pair.fd = socket.fd

  local cleartext = pair.cleartext
  cleartext.socket = socket
  cleartext.encrypted = pair.encrypted
  cleartext.authorized = false

  function onerror(e)
    cleartext:emit('error', e)
  end

  function onend()
    cleartext:emit('end')
  end

  function ontimeout()
    cleartext:emit('timeout')
  end

  socket:on('error', onerror)
  socket:on('end', onend)
  socket:on('timeout', ontimeout)

  return cleartext
end

--[[ Server ]]--

-- [options], [listener]
local Server = net.Server:extend()
function Server:initialize(...)
  local args = {...}
  local options, listener
  if type(args[1]) == 'table' then
    options = args[1]
    listener = args[2]
  else
    options = {}
    listener = args[1]
  end

  self._contexts = {}
  self:setOptions(options)

  local sharedCreds = createCredentials({
    key = self.key,
    passphrase = self.passphrase,
    cert = self.cert,
    ca = self.ca,
    crl = self.crl,
    ciphers = self.ciphers or 'RC4-SHA:AES128-SHA:AES256-SHA',
    secureProtocol = self.secureProtocol,
    secureOptions = self.secureOptions,
    sessionIdContext = self.sessionIdContext
  })

  -- Constructor
  net.Server.initialize(self, function(socket)
    local creds = createCredentials(nil, sharedCreds.context)
    local pair = SecurePair:new(creds, true, self.requestCert, self.rejectUnauthorized, {
      SNICallback = bind(Server.SNICallback, self)
    })
    local cleartext = pipe(pair, socket)
    cleartext.socket = socket
    pair:on('secure', function()
      cleartext.serverName = pair.serverName
      pair.cleartext.authorized = false
      pair.cleartext.serverName = pair.serverName

      if self.requestCert == false then
        self:emit('secureConnection', cleartext, pair.encrypted)
      else
        local verifyError = pair.ssl:verifyError()
        if verifyError then
          pair.cleartext.authorizationError = verifyError
          if self.rejectUnauthorized == true then
            pair:destroy()
          else
            self:emit('secureConnection', cleartext, pair.encrypted)
          end
        else
          pair.cleartext.authorized = true
          self:emit('secureConnection', cleartext, pair.encrypted)
        end
      end

    end)
    pair:on('error', function(err)
      self:emit('clientError', err)
    end)
  end)

  if listener then
    self:on('secureConnection', listener)
  end
end

function Server:addContext(serverName, credentials)
  if not serverName then
    error('ServerName is a required parameter')
  end
  self._contexts[serverName] = createCredentials(credentials).context
end

function Server:SNICallback(serverName)
  return self._contexts[serverName]
end

function Server:setOptions(options)
  if type(options.requestCert) == 'boolean' then
    self.requestCert = options.requestCert
  else
    self.requestCert = false
  end

  if type(options.rejectUnauthorized) == 'boolean' then
    self.rejectUnauthorized = options.rejectUnauthorized
  else
    self.rejectUnauthorized = false
  end

  if options.key then
    self.key = options.key
  end

  if options.passphrase then
    self.passphrase = options.passphrase
  end

  if options.cert then
    self.cert = options.cert
  end

  if options.ca then
    self.ca = options.ca
  end

  if options.secureProtocol then
    self.secureProtocol = options.secureProtocol
  end

  if options.crl then
    self.crl = options.crl
  end

  if options.ciphers then
    self.ciphers = options.ciphers
  end

  if options.secureProtocol then
    self.secureProtocol = options.secureProtocol
  end

  self.secureOptions = options.secureOptions or 0

  if options.honorCipherOrder then
    -- TODO
  end

  -- TODO NPN and SNI support
  if options.SNICallback then
    self.SNICallback = options.SNICallback
  end

  if options.sessionIdContext then
    self.sessionIdContext = options.sessionIdContext
  end
end

function createServer(options, listener)
  return Server:new(options, listener)
end

--[[ Public ]]--

function connect(...)
  local args = {...}
  local options = {}
  local callback

  if type(args[1]) == 'table' then
    options = args[1]
  elseif type(args[2]) == 'table' then
    options = args[2]
    options.port = args[1]
  elseif type(args[3]) == 'table' then
    options = args[3]
    options.port = args[1]
    options.host = args[2]
  end

  if type(args[#args]) == 'function' then
    callback = args[#args]
  end

  local socket = options.socket or Socket:new()
  
  if options.context then
    sslcontext = createCredentials(options, options.context)
  else
    sslcontext = createCredentials(options)
  end

  socket:connect(options.port, options.host)

  local servername = options.servername or options.host
  if not servername then
    error('host is a required parameter')
  end
  local pair = SecurePair:new(sslcontext, false, true, options.rejectUnauthorized == true, {
    servername = servername
  })

  if options.session then
    pair.ssl.setSession(options.session)
  end

  local cleartext = pipe(pair, socket)
  if callback then
    cleartext:on('secureConnect', function()
      callback(nil, cleartext)
    end)
  end

  pair:on('secure', function()
    local verifyError = pair.ssl:verifyError()
    if verifyError then
      cleartext.authorized = false
      cleartext.authorizationError = verifyError
      if pair._rejectUnauthorized == true then
        cleartext:emit('error', verifyError)
        pair:destroy()
      else
        cleartext:emit('secureConnect')
      end
    else
      cleartext.authorized = true
      cleartext:emit('secureConnect')
    end
  end)

  pair:on('error', function(err)
    cleartext:emit('error', err)
  end)

  return cleartext
end

local exports = {}
exports.Server = Server
exports.createServer = createServer
exports.connect = connect
exports.createCredentials = createCredentials
return exports
