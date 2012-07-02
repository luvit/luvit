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

local net = require('net')
local Freelist = require('freelist')
local HttpParser = require('http_parser')
local table = require('table')
local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local osDate = require('os').date
local string = require('string')
local stringFormat = require('string').format
local Object = require('core').Object
local Emitter = require('core').Emitter
local iStream = require('core').iStream
local Queue = require('core').Queue
local url = require('url')

local END_OF_FILE = 0
local CRLF = '\r\n'

local http = {}
local IncomingMessage = nil
local OugoingMessage = nil
local ServerResponse = nil
local ClientRequest = nil


local Parser = {}

function Parser:cleanup(ondata, onend)
  if self.incoming then
    self.incoming.parser = nil
    self.incoming.response = nil
  end
  self.incoming = nil

  if self.socket then
    if ondata then
      self.socket:removeListener('data', ondata)
    end
    if onend then
      self.socket:removeListener('end', onend)
    end
  end
  self.socket = nil

  self.onIncoming = nil
  self.headers = {}
  self.url = ''
end

local parsers = Freelist:new('parsers', 1000, function ()
  local currentField = nil -- string
  local parser = setmetatable({
    parser = nil,
    socket = nil, -- net.Socket
    incoming = nil, -- IncomingMessage
    onIncoming = nil, -- function
    headers = {},
    url = ''
  }, { __index = Parser })

  parser.parser = HttpParser.new("request", {
    onUrl = function (url)
      parser.url = url
    end,
    onHeaderField = function (field)
      parser._currentField = field
    end,
    onHeaderValue = function (value)
      local exists = parser.headers[parser._currentField]

      -- Turn multiple values into an table
      if exists then
        if 'table' ~= type(exists) then
          parser.headers[parser._currentField] = { exists }
          exists = parser.headers[parser._currentField]
        end
        exists[#exists + 1] = value
        return
      end

      parser.headers[parser._currentField] = value
    end,
    onHeadersComplete = function (info)
      parser.incoming = IncomingMessage:new(parser.socket)
      local incoming = parser.incoming

      incoming.httpVersionMajor = info.version_major
      incoming.httpVersionMinor = info.version_minor
      incoming.url = parser.url
      incoming.upgrade = info.upgrade

      for key, value in pairs(parser.headers) do
        incoming:_addHeaderLine(key, value)
      end

      if info.method then
        incoming.method = info.method
      else
        incoming.statusCode = info.status_code
      end

      local skipBody = false

      if not info.upgrade then
        skipBody = parser:onIncoming(incoming, info.should_keep_alive)
      end

      return skipBody
    end,
    onBody = function (data)
      parser.incoming:emit('data', data)
    end,
    onMessageComplete = function ()
      local incoming = parser.incoming
      local socket = parser.socket

      incoming.complete = true

      -- Trailing headers
      if #parser.headers > 0 then
        for key, value in pairs(parser.headers) do
          incoming:_addHeaderLine(key, value)
        end
        parser.headers = {}
      end

      if not incoming.upgrade then
        local pendings = incoming._pendings
        if incoming._paused or 0 < pendings:length() then
          pendings.push(END_OF_FILE)
        else
          incoming.readable = false
          incoming:_emitEnd()
        end
      end

      if socket.readable then
        socket:resume()
      end
    end
  })

  return parser
end)
http.parsers = parsers

local connectionExpression = 'connection'
local transferEncodingExpression = 'transfer-encoding'
local closeExpression = 'close'
local chunkExpression = 'chunk'
local contentLengthExpression = 'content-length'
local dateExpression = 'date'
local expectExpression = 'expect'
local continueExpression = '100-continue'

local STATUS_CODES = {
  [100] = 'Continue',
  [101] = 'Switching Protocols',
  [102] = 'Processing',                 -- RFC 2518, obsoleted by RFC 4918
  [200] = 'OK',
  [201] = 'Created',
  [202] = 'Accepted',
  [203] = 'Non-Authoritative Information',
  [204] = 'No Content',
  [205] = 'Reset Content',
  [206] = 'Partial Content',
  [207] = 'Multi-Status',               -- RFC 4918
  [300] = 'Multiple Choices',
  [301] = 'Moved Permanently',
  [302] = 'Moved Temporarily',
  [303] = 'See Other',
  [304] = 'Not Modified',
  [305] = 'Use Proxy',
  [307] = 'Temporary Redirect',
  [400] = 'Bad Request',
  [401] = 'Unauthorized',
  [402] = 'Payment Required',
  [403] = 'Forbidden',
  [404] = 'Not Found',
  [405] = 'Method Not Allowed',
  [406] = 'Not Acceptable',
  [407] = 'Proxy Authentication Required',
  [408] = 'Request Time-out',
  [409] = 'Conflict',
  [410] = 'Gone',
  [411] = 'Length Required',
  [412] = 'Precondition Failed',
  [413] = 'Request Entity Too Large',
  [414] = 'Request-URI Too Large',
  [415] = 'Unsupported Media Type',
  [416] = 'Requested Range Not Satisfiable',
  [417] = 'Expectation Failed',
  [418] = 'I\'m a teapot',              -- RFC 2324
  [422] = 'Unprocessable Entity',       -- RFC 4918
  [423] = 'Locked',                     -- RFC 4918
  [424] = 'Failed Dependency',          -- RFC 4918
  [425] = 'Unordered Collection',       -- RFC 4918
  [426] = 'Upgrade Required',           -- RFC 2817
  [500] = 'Internal Server Error',
  [501] = 'Not Implemented',
  [502] = 'Bad Gateway',
  [503] = 'Service Unavailable',
  [504] = 'Gateway Time-out',
  [505] = 'HTTP Version not supported',
  [506] = 'Variant Also Negotiates',    -- RFC 2295
  [507] = 'Insufficient Storage',       -- RFC 4918
  [509] = 'Bandwidth Limit Exceeded',
  [510] = 'Not Extended'                -- RFC 2774
}
http.STATUS_CODES = STATUS_CODES

--------------------------------------------------------------------------------
--[[ Incoming Message Base Class ]]--
IncomingMessage = iStream:extend()
function IncomingMessage:initialize(socket)
  self.socket = socket
  self.readable = true
  self._endEmitted = false
  self._pendings = Queue:new()
  self.headers = {}
  self.trailers = {}
  self.complete = false
end

function IncomingMessage:destroy(...)
  self.socket:destroy(...)
end

function IncomingMessage:pause()
  self._paused = true
  self.socket:pause()
end

function IncomingMessage:resume()
  self._paused = false
  if self.socket then
    self.socket:resume()
  end
  self:_emitPending()
end

function IncomingMessage:_emitPending(callback)
  if #self._pendings > 0 then
    process.nextTick(function()
      local pendings = self._pendings
      while self._paused == false and pendings:length() > 0 do
        local chunk = pendings:pop()
        if chunk ~= END_OF_FILE then
          self:_emitData(chunk)
        else
          self.readable = false
          self:_emitEnd()
        end
      end
    end)
  elseif callback then
    callback()
  end
end

function IncomingMessage:_emitData(d)
  self:emit('data', d)
end

function IncomingMessage:_emitEnd()
  if self._endEmitted == false then
    self:emit('end')
  end
  self._endEmitted = true
end

function IncomingMessage:_addHeaderLine(field, value)
  local dest = self.complete and self.trailers or self.headers
  local headerMap = {}
  field = field:lower()

  local function commaSeparate()
    if dest[field] then
      dest[field] = dest[field] .. ', ' .. value
    else
      dest[field] = value
    end
  end

  local function default()
    if field:sub(1,2) == 'x-' then
      if dest[field] then
        dest[field] = dest[field] .. ', ' .. value
      else
        dest[field] = value
      end
    else
      if not dest[field] then
        dest[field] = value
      end
    end
  end

  local function setCoookie()
    if dest[field] then
      dest[field][#desk[field] + 1] = value
    else
      dest[field] = { value }
    end
  end

  headerMap['accept'] = commaSeparate
  headerMap['accept-charset'] = commaSeparate
  headerMap['accept-encoding'] = commaSeparate
  headerMap['accept-language'] = commaSeparate
  headerMap['connection'] = commaSeparate
  headerMap['cookie'] = commaSeparate
  headerMap['pragma'] = commaSeparate
  headerMap['link'] = commaSeparate
  headerMap['www-authenticate'] = commaSeparate
  headerMap['sec-websocket-extensions'] = commaSeparate
  headerMap['set-cookie'] = setCookie

  -- execute
  local func = headerMap[field] or default
  func()
end

--[[ Setup HTTP socket ]]--
local function httpSocketSetup(socket)
  if socket._onDrain then
    return
  end
  function socket._onDrain()
    if socket._httpMessage then
      socket._httpMessage:emit('drain')
    end
  end
  socket:on('drain', socket._onDrain)
end

--[[ Outgoing Message ]]--
local OutgoingMessage = IncomingMessage:extend()
function OutgoingMessage:initialize()
  IncomingMessage.initialize(self)

  self.output = Queue:new()

  self.writable = true

  self._last = false
  self.chunkedEncoding = false
  self.shouldKeepAlive = true
  self.useChunkedEncodingByDefault = true
  self.sendDate = true

  self._hasBody = true
  self._headerSent = false
  self._trailer = ''

  self.finished = false
end

function OutgoingMessage:destroy(err)
  self.socket:destroy(err)
end

function OutgoingMessage:_send(data, encoding)
  if self._headerSent == false then
    data = tconcat({ self._header, data })
    self._headerSent = true
  end
  return self:_writeRaw(data, encoding)
end


function OutgoingMessage:_writeRaw(data, encoding)
  if #data == 0 then
    return true
  end

  local socket = self.socket
  local output = self.output

  if socket and socket.writable == true then
    local length = output:length()
    while length > 0 do
      if socket.writable == false then
        -- buffer
        output:push(data)
        return false
      end

      local c = output:pop()
      length = length - 1
      socket:write(c)
    end

    return socket:write(data, encoding)
  else
    output:push(data)
    return false
  end
end

function OutgoingMessage:_storeHeader(firstLine, headers)
  local sentConnectionHeader = false
  local sentContentLengthHeader = false
  local sentTransferEncodingHeader = false
  local sentDateHeader = false
  local sentExpect = false

  local messageHeader = { firstLine }
  local length = #messageHeader
  local field, value

  local function store(field, value)
    length = length + 1
    messageHeader[length] = field .. ': ' .. value .. CRLF

    local matchField = field:lower()
    if matchField == connectionExpression then
      sentConnectionHeader = true
      if value == closeExpression then
        self._last = true
      else
        self.shouldKeepAlive = true
      end
    elseif matchField == transferEncodingExpression then
      sentTransferEncodingHeader = true
      if value == chunkExpression then
        self.chunkedEncoding = true
      end
    elseif matchField == contentLengthExpression then
      sentContentLengthHeader = true
    elseif matchField == dateExpression then
      sentDateHeader = true
    elseif matchField == expectExpression then
      sentExpect = true
    end
  end

  if headers then
    local isArray = headers[1]
    for field, value in pairs(headers) do
      if isArray then
        field = headers[field][0]
        value = headers[value][1]
      end

      if type(value) == 'table' and value[1] then -- isArray
        for k, v in pairs(value) do
          store(field, v)
        end
      else
        store(field, value)
      end
    end
  end

  if self.sendDate == true and sentDateHeader == false then
    length = length + 1
    messageHeader[length] = osDate("!Date: %a, %d %b %Y %H:%M:%S GMT\r\n")
  end

  if sentConnectionHeader == false then
    local shouldSendKeepAlive = self.shouldKeepAlive and (sentContentLengthHeader or self.useChunkedEncodingByDefault)
    if shouldSendKeepAlive == true then
      length = length + 1
      messageHeader[length] = 'Connection: keep-alive\r\n'
    else
      self._last = true
      length = length + 1
      messageHeader[length] = 'Connection: close\r\n'
    end
  end

  if sentContentLengthHeader == false and sentTransferEncodingHeader == false then
    if self._hasBody == true then
      if self.useChunkedEncodingByDefault == true then
        length = length + 1
        messageHeader[length] = 'Transfer-Encoding: chunked\r\n'
        self.chunkedEncoding = true
      else
        self._last = true
      end
    else
      self.chunkedEncoding = false
    end
  end


  length = length + 1
  messageHeader[length] = CRLF

  self._header = tconcat(messageHeader)
  self._headerSent = false

  if sentExpect then
    self:_send('')
  end
end

function OutgoingMessage:setHeader(name, value)
  local key = name:lower()
  self._headers = self._headers or {}
  self._headerNames = self._headerNames or {}
  self._headers[key] = value
  self._headerNames[key] = name
end

function OutgoingMessage:getHeader(name)
  if not self._headers then
    return
  end

  local key = name:lower()
  return self._headers[key]
end

function OutgoingMessage:removeHeader(name)
  if not self._headers then
    return
  end

  local key = name:lower()
  self._headers[key] = nil
  self._headerNames[key] = nil
end

function OutgoingMessage:_renderHeaders()
  if not self._headers then
    return
  end

  local headers = {}
  for k, v in pairs(self._headers) do
    headers[self._headerNames[k]] = v
  end
  return headers
end

function OutgoingMessage:write(chunk, encoding)
  if not self._header then
    self:_implicitHeader()
  end

  if not self._hasBody then
    print('This type of response must not have a body')
    return true
  end

  if not chunk or #chunk == 0 then
    return false
  end

  local ret
  if self.chunkedEncoding then
    local len = #chunk
    chunk = tconcat({ stringFormat('%x', #chunk), CRLF, chunk, CRLF })
    ret = self:_send(chunk, encoding)
  else
    ret = self:_send(chunk, encoding)
  end

  return ret
end

function OutgoingMessage:addTrailers(headers)
  self._trailer = ''
  local isArray = headers[1]
  local field, value
  for k, v in pairs(headers) do
    if isArray then
      field = headers[k][0]
      value = headers[k][1]
    else
      field = k
      value = headers[k]
    end

    self._trailer = tconcat({ self._trailer, field, ': ', value, CRLF })
  end
end

function OutgoingMessage:done(data, encoding)
  if self.finished then
    return
  end

  if not self._header then
    self:_implicitHeader()
  end

  if data and not self._hasBody then
    print('This type of response must not have a body')
    data = false
  end

  local hot = false
  local ret
  if self._headerSent == false and type(data) == 'string' and
    #data > 0 and self.output:length() == 0 and self.socket and self.socket.writable then
    hot = true
  end

  if hot then
    if self.chunkedEncoding then
      local l = stringFormat('%x', #data)
      local buf = tconcat({ self._header, l, CRLF, data, '\r\n0\r\n', self._trailer, CRLF })
      ret = self.socket:write(buf)
    else
      ret = self.socket:write(tconcat({ self._header, data }))
    end
    self._headerSent = true
  else
    ret = self:write(data, encoding)

    if self.chunkedEncoding then
      ret = self:_send(tconcat({ '0\r\n', self._trailer, '\r\n' }))
    else
      ret = self:_send('')
    end
  end

  self.finished = true
  if self.output:length() == 0 then
    self:emit('finish')
  end

  return ret
end

function OutgoingMessage:_flush()
  if not self.socket then
    return
  end

  local ret
  local output = self.output
  local socket = self.socket
  local length = output:length()
  while length > 0 do
    if not socket.writable then
      return
    end

    local data = output:pop()
    length = length - 1
    ret = socket:write(data)
  end

  if self.finished then
    self:emit('finish')
  elseif ret then
    self:emit('drain')
  end
end

--[[ ServerResponse ]]--
ServerResponse = OutgoingMessage:extend()
function ServerResponse:initialize(req)
  OutgoingMessage.initialize(self)

  if req.method == 'HEAD' then
    self._hasBody = false
  end

  self.statusCode = 200

  if req.httpVersionMajor < 1 or req.httpVersionMinor < 1 then
    self.useChunkedEncodingByDefault = false
    self.shouldKeepAlive = false
  end
end

function ServerResponse:assignSocket(socket)
  socket._httpMessage = self
  function self._onClose()
    self._httpMessage:emit('close')
  end
  socket:on('close', self._onClose)
  self.socket = socket
  self:_flush()
end

function ServerResponse:detachSocket(socket)
  if self._onClose then
    socket:removeListener('close', self._onClose)
  end
  socket._httpMessage = nil
  self.socket = nil
end

function ServerResponse:writeContinue()
  self:_writeRaw('HTTP/1.1 100 Continue' + CRLF + CRLF, 'ascii')
  self.sent100 = true
end

function ServerResponse:_implicitHeader()
  self:writeHead(self.statusCode)
end

function ServerResponse:writeHead(statusCode, ...)
  local reasonPhrase, headers
  local args = {...}

  reasonPhrase = STATUS_CODES[statusCode] or 'unknown'
  self.statusCode = statusCode

  local obj = args[1]

  if obj and self._headers then
    headers = self:_renderHeaders()
    local field
    if obj[1] then
      for i, val in pairs(obj) do
        field = val[1]
        if headers[field] then
          tinsert(obj, {field, headers[field]})
        end
      end
      headers = obj
    else
      for k, v in pairs(obj) do
        headers[k] = v
      end
    end
  elseif self._headers then
    headers = self:_renderHeaders()
  else
    headers = obj
  end

  local statusLine = tconcat({ 'HTTP/1.1 ', tostring(statusCode), ' ', reasonPhrase, CRLF })
  if statusCode == 204 or statusCode == 304 or (100 <= statusCode and statusCode <= 199) then
    self._hasBody = false
  end

  if self._expectContinue and not self._sent100 then
    self.shouldKeepAlive = false
  end

  self:_storeHeader(statusLine, headers)
end

function ServerResponse:writeHeader(...)
  self:writeHead(...)
end


--[[ Agent ]]--
local Agent = Emitter:extend()
http.Agent = Agent

function Agent:initialize(options)
  self.options = options or {}
  self.requests = {}
  self.sockets = {}
  self.maxSockets = self.options.maxSockets or Agent.defaultMaxSockets

  self:on('free', function (socket, host, port, localaddr)
    local name = { host, port }
    if localaddr then
      name[#name + 1] = localaddr
    end
    name = tconcat(name)

    if self.requests[name] and 0 < #self.requests[name] then
      local request = self.requests[name]:pop()
      request:onSocket(socket)

      if 0 == #self.requests[name] then
        self.requests[name] = nil
      end
    else
      socket:destroy()
    end
  end)
end

Agent.createConnection = net.createConnection
Agent.defaultMaxSockets = 5
Agent.defaultPort = 80

function Agent:addRequest(request, host, port, localaddr)
  local name = { host, port }
  if localaddr then
    name[#name + 1] = localaddr
  end
  name = tconcat(name)

  if not self.sockets[name] then
    self.sockets[name] = Queue:new()
  end
  if self.maxSockets > self.sockets[name]:length() then
    request:onSocket(self:createSocket(name, host, port, localaddr))
  else
    if not self.requests[name] then
      self.requests[name] = Queue:new()
    end
    self.requests[name]:push(request)
  end
end

function Agent:createSocket(name, host, port, localaddr)
  -- Copy options
  local options = {}
  for key, val in pairs(self.options) do
    options[key] = val
  end

  options.port = port
  options.host = host
  options.localAddress = localaddr

  local socket = self.createConnection(port, host)

  if not self.sockets[name] then
    self.sockets[name] = Queue:new()
  end
  self.sockets[name]:push(socket)

  local function onfree()
    self:emit('free', socket, host, port, localaddr)
  end
  socket:on('free', onfree)

  local function onclose()
    self:removeSocket(socket, name, host, port, localaddr)
  end
  socket:on('close', onclose)

  local function onremove()
    self:removeSocket(socket, name, host, port, localaddr)
    self:removeListener('close', onclose)
    self:removeListener('free', onfree)
    self:removeListener('agentRemove', onremove)
  end
  socket:on('agentRemove', onremove)

  return socket
end

function Agent:removeSocket(socket, name, host, port, localaddr)
  local sockets = self.sockets[name]
  local requests = self.requests[name]

  if sockets then
    if sockets:remove(socket) then
      if 0 == sockets:length() then
        self.sockets[name] = nil
      end
    end
  end

  if requests and 0 < requests:length() then
    self:createSocket(name, host, port, localaddr):emit('free')
  end
end

-- Global agent
local globalagent = Agent:new()
http.globalAgent = globalagent

--[[ Client Request ]]--
ClientRequest = OutgoingMessage:extend()
function ClientRequest:initialize(options, callback)
  OutgoingMessage.initialize(self)

  self.agent = options.agent or globalagent

  local defaultPort = options.defaultPort or 80
  local port = options.port or defaultPort
  local host = options.hostname or options.host or 'localhost'
  local setHost = options.setHost or true
  self.socketPath = options.socketPath
  self.method = (options.method or 'GET'):upper()
  self.path = options.path or options.pathname or '/'

  if options.search then
    self.path = self.path .. options.search
  end

  if callback then
    self:once('response', callback)
  end

  -- TODO Authorization

  if options.headers then
    for k, v in pairs(options.headers) do
      self:setHeader(k, v)
    end

    if host and not self:getHeader('host') and setHost then
      local hostHeader = host
      if port and port ~= defaultPort then
        hostHeader = hostHeader .. ':' .. port
      end
      self:setHeader('Host', hostHeader)
    end
  end

  if method == 'GET' or method == 'HEAD' or method == 'CONNECT' then
    self.useChunkedEncodingByDefault = false
  else
    self.useChunkedEncodingByDefault = true
  end

  if options.headers and options.headers[1] then
    self:_storeHeader(self.method .. ' ' .. self.path .. ' HTTP/1.1\r\n', options.headers)
  elseif self:getHeader('expect') then
    self:_storeHeader(self.method .. ' ' .. self.path .. ' HTTP/1.1\r\n', self:_renderHeaders())
  end

  if self.socketPath then
    self._last = true
    self.shouldKeepAlive = false
    if options.createConnection then
      self:onSocket(options.createConnection(self.socketPath))
    else
      self:onSocket(net.createConnection(self.socketPath))
    end
  elseif self.agent then
    self._last = false
    self.shouldKeepAlive = true
    self.agent:addRequest(self, host, port)
  else
    -- No agent, Connection: close
    self._last = true
    self.shouldKeepAlive = false

    local conn
    if options.createConnection then
      options.port = port
      options.host = host
      conn = options.createConnection(options)
    else
      conn = net.createConnection({
        port = port,
        host = host,
        localAddress = options.localAddress
      })
    end

    self:onSocket(conn)
  end

  self:_deferToConnect(function()
    self:_flush()
  end)
end

function ClientRequest:setTimeout(msecs, callback)
  if callback then
    self:once('timeout', callback)
  end

  local function emitTimeout()
    self:emit('timeout')
  end

  if self.socket and self.socket.writable then
    self.socket:setTimeout(msecs, emitTimeout)
    return
  end

  if self.socket then
    self.socket:on('connect', function()
      self:setTimeout(msecs, emitTimeout)
    end)
    return
  end

  self:once('socket', function(sock)
    self:setTimeout(msecs, emitTimeout)
  end)
end

function ClientRequest:onSocket(socket)
  process.nextTick(function()
    local request = self
    local parser = parsers:alloc()
    self.socket = socket
    self.parser = parser
    parser.parser:reinitialize('response')
    parser.socket = socket
    socket._httpMessage = self

    -- drain
    httpSocketSetup(socket)

    local function onclose()
      local response = request.response

      if response and response.readable then
        response:emit('aborted')
        response:_emitPending(function ()
          response:_emitEnd()
          response:emit('close')
        end)
      elseif not response and not request._hadError then
        request:emit('error', 'ECONNRESET: socket hang up')
      end
    end
    local function onend()
      if not request.response then
        request:emit('error', 'ECONNRESET: socket hang up')
        request._hadError = true
      end
      if parser then
        parser.parser:finish()
        parser:cleanup()
        parsers:free(parser)
      end
      socket:destroy()
    end
    local function ontimeout()
      self:emit('timeout')
    end
    local function ondata(chunk)
      -- Ignore empty chunks
      if #chunk == 0 then return end

      local response = request.response

      local nparsed = parser.parser:execute(chunk, 0, #chunk)
      -- If it wasn't all parsed then there was an error parsing
      if nparsed < #chunk then
        parser:cleanup()
        parsers:free(parser)
        socket:destroy()
        socket:emit('error', 'parse error')
      elseif parser.incoming and parser.incoming.upgrade then
        -- Once we're in "upgrade" mode, the protocol is no longer HTTP and we
        -- shouldn't send data to the HTTP parser
        request:removeListener('data', ondata)
        request:removeListener('end', onend)
        parser.parser:finish()

        local event = ''
        local handlers = rawget(request, 'handlers')
        if parser.incoming.method == 'CONNECT' then
          event = 'connect'
        else
          event = 'upgrade'
        end

        if handlers[event] and 0 < #handlers[event] then
          request.upgradeOrConnect = true
          socket:emit('agentRemove')
          socket:removeListener('close', onclose)
          socket:removeListener('error', onerror)
          request:emit(event, response, socket, chunk)
        else
          socket:destroy()
        end
        parser:cleanup()
        parsers:free(parser)
        return
      end
    end
    local function onerror(err)
      request._hadError = true
      self:emit('error', err)
    end

    socket:on('close', onclose)
    socket:on('end', onend)
    socket:on('timeout', ontimeout)
    socket:on('data', ondata)
    socket:on('error', onerror)

    function responseonend()
      if not request.shouldKeepAlive then
        if socket.writable then
          socket:destroySoon()
        end
      else
        socket:removeListener('close', onclose)
        socket:removeListener('error', onerror)
        socket:emit('free')
      end
    end

    function parser:onIncoming(response, shouldkeepalive)
      if request.response then
        socket:destroy()
        return
      end
      request.response = response
      response.request = request

      if request.method == 'CONNECT' then
        response.upgrade = true
        return true
      end

      local isheadresponse = request.method == 'HEAD'

      if response.statusCode == 100 then
        request.response = nil
        request:emit('continue')
        return true
      end

      if request.shouldKeepAlive and not shouldkeepalive and
         not request.upgradeOrConnect then
        request.shouldKeepAlive = false
      end

      request:emit('response', response)
      response:on('end', responseonend)

      return isheadresponse
    end

    self:emit('socket', socket)
  end)
end

function ClientRequest:_deferToConnect(callback)
  local onSocket = function()
    if self.socket.writable then
      if callback then
        callback()
      end
    else
      self.socket:once('connect', function()
        if callback then
          callback()
        end
      end)
    end
  end

  if not self.socket then
    self:once('socket', onSocket)
  else
    onSocket()
  end
end


function ClientRequest:_implicitHeader()
  self:_storeHeader(self.method .. ' ' .. self.path .. ' HTTP/1.1\r\n',
                    self:_renderHeaders())
end

function ClientRequest:abort()
  if self.socket then
    self.socket:destroy()
  else
    self:_deferToConnect(function ()
      self.socket:destroy()
    end)
  end
end


--------------------------------------------------------------------------------

local Server = net.Server:extend()

http.Server = Server

--[[
  Server metatable
  ]]--
function Server:initialize(onRequest)
  net.Server.initialize(self)
  local server = self

  if onRequest then
    self:on('request', onRequest)
  end

  --[[
    Called when we have an incoming socket
    ]]--
  local function onConnection(socket)
    httpSocketSetup(socket)

    -- 2 minute timeout
    socket:setTimeout(2 * 60 * 1000)
    socket:on('timeout', function ()
      socket:destroy()
    end)

    socket:on('error', function (err)
      self:emit('clientError', err)
    end)

    local incoming = Queue:new()
    local outgoing = Queue:new()

    local parser = parsers:alloc()
    parser:cleanup()
    parser.parser:reinitialize('request')
    parser.socket = socket

    local function abortincoming()
      local req = nil
      local length = incoming:length()
      while length > 0 do
        req = incoming:pop()
        length = length - 1
        req:emit('aborted')
        req:emit('close')
      end
    end

    local function ondata(data)
      local length = #data
      if 0 == length then return end

      local bytes = parser.parser:execute(data, 0, length)

      if bytes < length then
        socket:emit('error', 'http parse error')
        socket:destroy()
      elseif parser.incoming and parser.incoming.upgrade then
        socket:removeListener('data', ondata)
        socket:removeListener('end', onend)
        socket:removeListener('close', onSocketClose)
        parser.parser:finish()

        local event = ''
        local handlers = rawget(request, 'handlers')
        if parser.incoming.method == 'CONNECT' then
          event = 'connect'
        else
          event = 'upgrade'
        end

        if handlers[event] and 0 < #handlers[event] then
          self:emit(event, request, socket, chunk)
        else
          socket:destroy()
        end
        parser:cleanup()
        parsers:free(parser)
      end
    end

    local function onend()
      parser.parser:finish()

      if 0 < outgoing:length() then
        outgoing[outgoing.tail]._last = true
      elseif socket._httpMessage then
        socket._httpMessage._last = true
      elseif socket.writable then
        socket:done()
      end
    end

    local function onclose()
      parser:cleanup()
      parsers:free(parser)
      abortincoming()
    end

    socket:on('data', ondata)
    socket:on('end', onend)
    socket:on('close', onclose)

    function parser:onIncoming(request, shouldkeepalive)
      incoming:push(request)

      local response = ServerResponse:new(request)
      response.shouldKeepAlive = shouldkeepalive

      if socket._httpMessage then
        outgoing:push(response)
      else
        response:assignSocket(socket)
      end

      -- After writing the response checkout to see if it is the last one.
      -- We will procede to destroy it if so.
      response:on('finish', function ()
        incoming:pop()
        response:detachSocket(socket)

        if response._last then
          socket:destroySoon()
        else
          local msg = outgoing:pop()
          if msg then
            msg:assignSocket(socket)
          end
        end
      end)

      local handlers = rawget(server, 'handlers')

      -- expect continue
      if request.headers['expect'] and (request.httpVersionMajor == 1 and request.httpVersionMinor == 1) and
         request.headers['expect']:lower() == continueExpression then
        response._expectContinue = true

        if handlers['checkContinue'] and 0 < #handlers['checkContinue'] then
          server:emit('checkContinue', request, response)
        else
          response:writeContinue()
          server:emit('request', request, response)
        end
      else
        server:emit('request', request, response)
      end
    end
  end

  self:on('connection', onConnection)
end

--------------------------------------------------------------------------------
function http.request(options, callback)
  if type(options) == 'string' then
    options = url.parse(options)
  end
  return ClientRequest:new(options, callback)
end

function http.get(options, callback)
  local req = http.request(options, callback)
  req:done()
  return req
end

function http.createServer(onRequest)
  return Server:new(onRequest)
end

-- More lua-like naming
http.createserver = http.createServer

return http

