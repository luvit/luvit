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
local HttpParser = require('http_parser')
local table = require('table')
local osDate = require('os').date
local string = require('string')
local stringFormat = require('string').format
local Object = require('core').Object
local Error = require('core').Error
local url = require('url')

local END_OF_FILE = 0
local CRLF = '\r\n'

local iStream = require('core').iStream
local http = {}

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
local IncomingMessage = iStream:extend()
function IncomingMessage:initialize(socket)
  self.socket = socket
  self.readable = true
  self._endEmitted = false
  self._pendings = {}
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
      while self._paused == false and #self._pendings > 0 do
        local chunk = table.remove(self._pendings)
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

  local function setCookie()
    if dest[field] then
      table.insert(dest[field], value)
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

--[[ Outgoing Message ]]--
local OutgoingMessage = IncomingMessage:extend()
function OutgoingMessage:initialize()
  IncomingMessage.initialize(self)

  self.output = {}

  self.writable = true

  self._last = false
  self.chunkedEncoding = false
  self.shouldKeepAlive = true
  self.useChunkedEncodingByDefault = true
  self.sendDate = false

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
    if type(data) == 'string' then
      data = self._header .. data
    else
      table.insert(self.output, self._header)
    end
    self._headerSent = true
  end
  return self:_writeRaw(data, encoding)
end


function OutgoingMessage:_writeRaw(data, encoding)
  if #data == 0 then
    return true
  end

  if self.socket and self.socket.writable == true then
    while #self.output > 0 do
      if self.socket.writable == false then
        -- buffer
        self:_buffer(data, encoding)
        return false
      end

      local c = table.remove(self.output)
      self.socket:write(c)
    end

    return self.socket:write(data, encoding)
  else
    self:_buffer(data, encoding)
    return false
  end
end

function OutgoingMessage:_buffer(data, encoding)
  if #data == 0 then
    return
  end

  local length = #self.output
  if length == 0 or type(data) ~= 'string' then
    table.insert(self.output, data)
    return false
  end

  table.insert(self.output, data)
  return false
end

function OutgoingMessage:_storeHeader(firstLine, headers)
  local sentConnectionHeader = false
  local sentContentLengthHeader = false
  local sentTransferEncodingHeader = false
  local sentDateHeader = false
  local sentExpect = false

  local messageHeader = firstLine
  local field, value

  local function store(field, value)
    local matchField = field:lower()
    messageHeader = messageHeader .. field .. ': ' .. value .. CRLF
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
    for k, v in pairs(headers) do
      if isArray then
        field = headers[k][0]
        value = headers[k][1]
      else
        field = k
        value = v
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

  if sentConnectionHeader == false then
    local shouldSendKeepAlive = self.shouldKeepAlive and (sentContentLengthHeader or self.useChunkedEncodingByDefault)
    if shouldSendKeepAlive == true then
      messageHeader = messageHeader .. 'Connection: keep-alive\r\n'
    else
      self._last = true
      messageHeader = messageHeader .. 'Connection: close\r\n'
    end
  end

  if sentContentLengthHeader == false and sentTransferEncodingHeader == false then
    if self._hasBody == true then
      if self.useChunkedEncodingByDefault == true then
        messageHeader = messageHeader .. 'Transfer-Encoding: chunked\r\n'
        self.chunkedEncoding = true
      else
        self._last = true
      end
    else
      self.chunkedEncoding = false
    end
  end

  self._header = messageHeader .. CRLF
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
    local len = stringFormat("%x", #chunk)
    chunk = len .. CRLF .. chunk .. CRLF
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
  for k, v in headers do
    if isArray then
      field = headers[k][0]
      value = headers[k][1]
    else
      field = k
      value = headers[k]
    end

    self._trailer = self._trailer .. field .. ': ' .. value .. CRLF
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
    #data > 0 and #self.output == 0 and self.socket and self.socket.writable then
    hot = true
  end

  if hot then
    if self.chunkedEncoding then
      local len = stringFormat("%x", #data)
      local buf = self._header .. len .. CRLF .. data .. '\r\n0\r\n' .. self._trailer .. CRLF
      ret = self.socket:write(buf)
    else
      ret = self.socket:write(self._header .. data)
    end
    self._headerSent = true
  else
    ret = self:write(data, encoding)
  end

  if not hot then
    if self.chunkedEncoding then
      ret = self:_send('0\r\n' .. self._trailer .. '\r\n')
    else
      ret = self:_send('')
    end
  end

  self.finished = true
  if #self.output == 0 then
    self:_finish()
  end

  return ret
end


function OutgoingMessage:_finish()
  self:emit('finish')
end

function OutgoingMessage:_flush()
  if not self.socket then
    return
  end

  local ret
  while #self.output > 0 do
    if not self.socket.writable then
      return
    end

    local data = table.remove(self.output)
    ret = self.socket:write(data)
  end

  if self.finished then
    self:_finish()
  elseif ret then
    self:emit('drain')
  end
end

--[[ ServerResponse ]]--
local ServerResponse = OutgoingMessage:extend()
function ServerResponse:initialize(req)
  OutgoingMessage.initialize(self)

  if req.method == 'HEAD' then
    self._hasBody = false
  end

  self.sendDate = false
  self.statusCode = 200
end

function ServerResponse:assignSocket(socket)
  socket._httpMessage = self
  socket:on('close', function()
    self._httpMessage:emit('close')
  end)
  self.socket = socket
  self:_flush()
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
      for i, v in ipairs(obj) do
        field = obj[i][1]
        if headers[field] then
          table.insert(obj, {field, headers[field]})
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

  local statusLine = 'HTTP/1.1 ' .. tostring(statusCode) .. ' ' .. reasonPhrase .. CRLF
  if statusCode == 204 or statusCode == 304 or (100 <= statusCode and statusCode <= 199) then
    self._hasBody = false
  end

  self:_storeHeader(statusLine, headers)
end

function ServerResponse:writeHeader(...)
  self:writeHead(...)
end

--[[ Client Request ]]--
local ClientRequest = OutgoingMessage:extend()
function ClientRequest:initialize(options, callback)
  OutgoingMessage.initialize(self)
  local defaultPort = options.defaultPort or 80
  local port = options.port or defaultPort
  local host = options.hostname or options.host or 'localhost'
  local setHost = options.setHost or true
  self.socketPath = options.socketPath
  self.method = (options.method or 'GET'):upper()
  self.path = options.path or options.pathname or '/'
  self._hadError = false
  self._hadResponse = false

  if options.search then
    self.path = self.path .. options.search
  end

  self:once('response', function(...)
    self:onResponse(callback, ...)
  end)

  -- TODO Authorization

  if options.headers then
    for k, v in pairs(options.headers) do
      self:setHeader(k, v)
    end
  end

  if host and not self:getHeader('host') and setHost then
    local hostHeader = host
    if port and port ~= defaultPort then
      hostHeader = hostHeader .. ':' .. port
    end
    self:setHeader('Host', hostHeader)
  end

  if self.method == 'GET' or self.method == 'HEAD' or self.method == 'CONNECT' then
    self.useChunkedEncodingByDefault = false
  else
    self.useChunkedEncodingByDefault = true
  end

  if options.headers and options.headers[1] then
    self:_storeHeader(self.method .. ' ' .. self.path .. ' HTTP/1.1\r\n', options.headers)
  elseif self:getHeader('expect') then
    self:_storeHeader(self.method .. ' ' .. self.path .. ' HTTP/1.1\r\n', self:_renderHeaders())
  end

  local conn
  self._last = true
  self.shouldKeepAlive = false

  if options.createConnection then
    options.port = port
    options.host = host
    conn = options.createConnection(options)
  else
    conn = net.createConnection({
      port = port,
      host = host,
      localAddress = options.localAddress
    });
  end

  self.socket = conn

  self:onSocket(conn)
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

function ClientRequest:onResponse(callback, ...)
  self._hadResponse = true

  if callback then
    callback(...)
  end
end

function ClientRequest:onSocketClose()
  self:emit('close')
  if not self._hadError and not self._hadResponse then
    local err = Error:new('socket hang up');
    err.code = 'ECONNRESET';
    self:emit('error', err)
  end
end

function ClientRequest:onSocket(socket)
  local response = ServerResponse:new(self)
  local headers, current_field
  response.socket = socket

  self.socket = socket

  self.parser = HttpParser.new("response", {
    onMessageBegin = function ()
      headers = {}
    end,
    onUrl = function (url)
    end,
    onHeaderField = function (field)
      current_field = field
    end,
    onHeaderValue = function (value)
      headers[current_field:lower()] = value
    end,
    onHeadersComplete = function (info)
      response.headers = headers
      response.statusCode = info.status_code
      response.status_code = info.status_code
      response.version_minor = info.version_minor
      response.version_major = info.version_major
      response.httpVersionMinor = info.version_minor
      response.httpVersionMajor = info.version_major
      self:emit('response', response)
    end,
    onBody = function (chunk)
      response:emit("data", chunk)
    end,
    onMessageComplete = function ()
      response:emit("end")
    end
  })
  socket._httpMessage = self

  socket:on('drain', function()
    if self._httpMessage then
      self._httpMessage:emit('drain')
    end
  end)
  socket:once('close', function()
    self:onSocketClose()
  end)
  socket:once('end', function()
    self:emit('end')
  end)
  socket:once('timeout', function()
    self:emit('timeout')
  end)
  socket:on('data', function(chunk)
    -- Ignore empty chunks
    if #chunk == 0 then return end

    -- Once we're in "upgrade" mode, the protocol is no longer HTTP and we
    -- shouldn't send data to the HTTP parser
    if response.upgrade then
      response:emit("data", chunk)
      return
    end

    local nparsed = self.parser:execute(chunk, 0, #chunk)
    -- If it wasn't all parsed then there was an error parsing
    if nparsed < #chunk then
      local err = Error:new('parse error')
      self:emit("error", err)
    end
  end)
  socket:on('error', function(err)
    self._hadError = true
    self:emit('error', err)
  end)
  self:emit('socket', socket)
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


local Request = iStream:extend()
http.Request = Request

function Request:initialize(socket)
  self.socket = socket
end

function Request:destroy(...)
  return self.socket:destroy(...)
end

--------------------------------------------------------------------------------

local Response = iStream:extend()
http.Response = Response

function Response:initialize(socket)
  self.code = 200
  self.headers = {}
  self.header_names = {}
  self.headers_sent = false
  self.socket = socket

  self.socket:on('error', function(err)
      self:emit('error', err)
  end)
end

Response.auto_date = true
Response.auto_server = "Luvit"
Response.auto_chunked_encoding = true
Response.auto_content_length = true
Response.auto_content_type = "text/html"

function Response:setCode(code)
  if self.headers_sent then error("Headers already sent") end
  self.code = code
end

-- This sets a header, replacing any header with the same name (case insensitive)
function Response:setHeader(name, value)
  if self.headers_sent then error("Headers already sent") end
  local lower = name:lower()
  local old_name = self.header_names[lower]
  if old_name then
    self.headers[old_name] = nil
  end
  self.header_names[lower] = name
  self.headers[name] = value
  return name
end

-- Adds a header line.  This does not replace any header by the same name and
-- allows duplicate headers.  Returns the index it was inserted at
function Response:addHeader(name, value)
  if self.headers_sent then error("Headers already sent") end
  self.headers[#self.headers + 1] = { name, value }
  return #self.headers
end

-- Removes a set header.  Cannot remove headers added with :addHeader
function Response:unsetHeader(name)
  if self.headers_sent then error("Headers already sent") end
  local lower = name:lower()
  local name = self.header_names[lower]
  if not name then return end
  self.headers[name] = nil
  self.header_names[lower] = nil
end

function Response:flushHead(callback)
  if self.headers_sent then error("Headers already sent") end

  local reason = STATUS_CODES[self.code]
  if not reason then error("Invalid response code " .. tostring(self.code)) end

  local head = {"HTTP/1.1 " .. self.code .. " " .. reason .. "\r\n"}
  local length = 1
  local has_server, has_content_length, has_date, has_content_type

  -- We still don't know if there is a body, try to guess
  if self.has_body == nil then
    -- RFC 2616, 10.2.5:
    -- The 204 response MUST NOT include a message-body, and thus is always
    -- terminated by the first empty line after the header fields.
    -- RFC 2616, 10.3.5:
    -- The 304 response MUST NOT contain a message-body, and thus is always
    -- terminated by the first empty line after the header fields.
    -- RFC 2616, 10.1 Informational 1xx:
    -- This class of status code indicates a provisional response,
    -- consisting only of the Status-Line and optional headers, and is
    -- terminated by an empty line.
    if self.code == 204
      or self.code == 304
      or (self.code >= 100 and self.code < 200)
    then
      self.has_body = false
    else
      -- Default to true if we don't know.  It's the safe thing to assume
      self.has_body = true
    end
  end
  local has_body = self.has_body

  for field, value in pairs(self.headers) do
    -- handle headers added with `add_header`
    if type(field) == "number" then
      field = value[1]
      value = value[2]
    end
    local lower = field:lower()
    if lower == "server" then
      has_server = true
    elseif lower == "content-length" then
      has_content_length = true
      self.has_body = true
    elseif lower == "content-type" then
      has_content_type = true
      self.has_body = true
    elseif lower == "date" then
      has_date = true
    elseif lower == "transfer-encoding" and value:lower() == "chunked" then
      self.chunked = true
      self.has_body = true
    elseif lower == "connection" then
      self.has_connection = true
    end
    length = length + 1
    head[length] = field .. ": " .. value .. "\r\n"
  end

  -- Implement auto headers so people's http server are more spec compliant
  if not self.has_connection and self.should_keep_alive then
    length = length + 1
    head[length] = "Connection: keep-alive\r\n"
  end
  if not has_server and self.auto_server then
    length = length + 1
    head[length] = "Server: " .. self.auto_server .. "\r\n"
  end
  if has_body and not has_content_type and self.auto_content_type then
    length = length + 1
    head[length] = "Content-Type: " .. self.auto_content_type .. "\r\n"
  end
  if has_body and not has_content_length and self.auto_chunked_encoding then
    length = length + 1
    self.chunked = true
    head[length] = "Transfer-Encoding: chunked\r\n"
  end
  if not has_date and self.auto_date then
    -- This should be RFC 1123 date format
    -- IE: Tue, 15 Nov 1994 08:12:31 GMT
    length = length + 1
    head[length] = osDate("!Date: %a, %d %b %Y %H:%M:%S GMT\r\n")
  end

  head = table.concat(head, "") .. "\r\n"
  self.socket:write(head, callback)
  self.headers_sent = true
end

function Response:writeHead(code, headers, callback)
  if self.headers_sent then error("Headers already sent") end

  self.code = code
  for field, value in pairs(headers) do
    if type(field) == "number" then
      field = #self.headers + 1
    end
    self.headers[field] = value
  end

  self:flushHead(callback)
end

function Response:writeContinue(callback)
  self.socket:write('HTTP/1.1 100 Continue\r\n\r\n', callback)
end

function Response:write(chunk, callback)
  if self.has_body == false then error("Body not allowed") end
  if not self.headers_sent then
    self.has_body = true
    self:flushHead()
  end
  if self.chunked and #chunk > 0 then
    self.socket:write(stringFormat("%x\r\n", #chunk))
    self.socket:write(chunk)
    return self.socket:write("\r\n", callback)
  end
  return self.socket:write(chunk, callback)
end

function Response:finish(chunk, callback)
  if chunk and self.has_body == false then error ("Body not allowed") end
  if not self.headers_sent then
    if self.has_body == nil then
      if chunk then
        if self.auto_content_length and #self.headers == 0
         and (not self.header_names["content-length"])
         and (not self.header_names["transfer-encoding"]) then
          self:setHeader("Content-Length", #chunk)
        end
        self.has_body = true
      else
        self.has_body = false
      end
    end
    self:flushHead()
  end
  if type(chunk) == "function" and callback == nil then
    callback = chunk
    chunk = nil
  end
  if chunk then
    self:write(chunk)
  end
  if self.chunked then
    self.socket:write('0\r\n\r\n')
  end
  self:done(callback)
end

function Response:done(callback)
  if not self.should_keep_alive then
    self.socket:shutdown(function ()
      self:emit("end")
      self:destroy()
      if callback then
        self:on("close", callback)
      end
    end)
  else
    self:emit("end")
    -- TODO: cleanup more thoroughly
    self.socket = nil
  end
end

function Response:destroy(...)
  return self.socket:destroy(...)
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

function http.onClient(server, client, onConnection)
  -- Convert tcp stream to HTTP stream
  local request
  local current_field
  local parser
  local url
  local headers
  parser = HttpParser.new("request", {
    onMessageBegin = function ()
      headers = {}
    end,
    onUrl = function (value)
      url = value
    end,
    onHeaderField = function (field)
      current_field = field:lower()
    end,
    onHeaderValue = function (value)
      headers[current_field] = value
    end,
    onHeadersComplete = function (info)

      -- Accept the client and build request and response objects
      request = Request:new(client)
      local response = Response:new(client)

      request.method = info.method
      request.headers = headers
      request.url = url
      request.upgrade = info.upgrade

      request.version_major = info.version_major
      request.version_minor = info.version_minor

      -- Give upgrade requests access to the raw client if they want it
      if info.upgrade then
        request.client = client
      end

      -- HTTP keep-alive logic
      request.should_keep_alive = info.should_keep_alive
      response.should_keep_alive = info.should_keep_alive
      -- N.B. keep-alive requires explicit message length
      if info.should_keep_alive then
        --[[
          In order to remain persistent, all messages on the connection MUST
          have a self-defined message length (i.e., one not defined by closure
          of the connection)
        ]]
        response.auto_content_length = false
        -- HTTP/1.0 should insert Connection: keep-alive
        if info.version_minor < 1 then
          response:setHeader("Connection", "keep-alive")
        end
      else
        -- HTTP/1.1 should insert Connection: close for last message
        if info.version_minor >= 1 then
          response:setHeader("Connection", "close")
        end
      end

      -- Handle 100-continue requests
      if request.headers.expect
        and info.version_major == 1
        and info.version_minor == 1
        and request.headers.expect:lower() == "100-continue"
      then
        if server.handlers and server.handlers.check_continue then
          server:emit("check_continue", request, response)
        else
          response:writeContinue()
          onConnection(request, response)
        end
      else
        onConnection(request, response)
      end

    end,
    onBody = function (chunk)
      request:emit("data", chunk)
    end,
    onMessageComplete = function ()
      request:emit("end")
      request:removeListener("end")
      if request.should_keep_alive then
        parser:finish()
      end
    end
  })

  client:on("data", function(chunk)
     -- Once we're in "upgrade" mode, the protocol is no longer HTTP and we
    -- shouldn't send data to the HTTP parser
    if request and request.upgrade then
      request:emit("data", chunk)
      return
    end

    --[[ from http_parser documentation:
      To tell http_parser about EOF, give 0 as the forth parameter to
      http_parser_execute()
    ]]--
    -- don't route empty chunks to the parser
    if #chunk == 0 then return end

    -- Parse the chunk of HTTP, this will syncronously emit several of the
    -- above events and return how many bytes were parsed
    local nparsed = parser:execute(chunk, 0, #chunk)

    -- If it wasn't all parsed then there was an error parsing
    if nparsed < #chunk and request then
      if request.upgrade then
        request:emit("data", chunk:sub(nparsed + 1))
      else
        request:emit("error", "parse error: " .. chunk)
      end
    end
  end)

  client:once("end", function ()
    if request then
      request:emit("end")
      request:removeListener("end")
    end
    parser:finish()
  end)

  client:once("close", function ()
    if request then
      request:emit("end")
      request:removeListener("end")
    end
    parser:finish()
  end)

  client:once("error", function (err)
    parser:finish()
    -- read from closed client
    if err.code == "ECONNRESET" then
      -- ???
    -- written to closed client
    elseif err.code == "EPIPE" then
      -- ???
    -- other errors
    else
      if request then
        request:emit("error", err)
       end
    end
  end)

  return server
end

function http.createServer(onConnection)
  local server
  server = net.createServer(function(client)
    return http.onClient(server, client, onConnection)
  end)
  return server
end

return http
