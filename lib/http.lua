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
local table = require('table')
local iStream = require('core').iStream
local Error = require('core').Error
local http_parser = require('http_parser')
local math = require('math')
local http = {}

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


-- Small helpers
local function callbackError(err, callback)
  if callback then return callback(Error:new(err)) end
  error(err)
end

-- Convert number base to string
function base(num, base)
  num = math.floor(num)
  if not base or base == 10 then return tostring(num) end
  local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  local t = {}
  local sign = ""
  if num < 0 then
    sign = "-"
  num = -num
  end
  repeat
    local digit = (num % base) + 1
    num = math.floor(num / base)
    table.insert(t, 1, digits:sub(digit, digit))
  until num == 0
  return sign .. table.concat(t, "")
end

-- OutgoingMessage:new(socket)
--
-- Used for ServerResponse and ClientRequest
local OutgoingMessage = iStream:extend()
http.OutgoingMessage = OutgoingMessage

function OutgoingMessage:initialize(socket)
  Socket.initialize(self)

  self.socket = socket

  self.write_queue = {}

  self._headers = {}
  self._header_keys = {}
  self._header_cache = nil
  self._headers_sent = false
  self._headers_written = false

  self._last = false
  self._has_body = true
  self._trailer = nil

  self.chunked_encoding = false
  self.should_keep_alive = true
  self.chunked_encoding_default = true
  self.completed = false
end

function OutgoingMessage:close()
  if not socket then return false end
  self.completed = true
  return self.socket:close()
end

function OutgoingMessage:setHeader(name, value)
  if self._headers_sent then error('Headers already sent.') end
  local key = name:lower()
  self._headers[key] = value
  self._header_keys[key] = name
  return self
end

function OutgoingMessage:getHeader(name)
  return self._headers[name:lower()]
end

function OutgoingMessage:removeHeader(name)
  if self._headers_sent then error('Headers already sent.') end
  name = name:lower()
  self._headers[name] = nil
  self._header_keys[name] = nil
  return self
end

function OutgoingMessage:addTrailers(headers)
  if not self._trailer then self._trailer = {} end

  for key, value in pairs(headers) do
    table.insert(self._trailer, key .. ': ' .. value)
  end

  return self
end

function OutgoingMessage:_cacheHeader(firstline, headers)
  local sent_connection = false
  local sent_content_length = false
  local sent_transfer_encoding = false
  local sent_expect = false

  local buffer = { firstline }

  function store(key, value)
    table.insert(buffer, key .. ': ' .. value)

    local key_lower = key:lower()
    local value_lower = value:lower()

    if nil ~= key_lower:find('connection', 1, true) then
      sent_connection = true
      if nil ~= value_lower:find('close', 1, true) then
        self._last = true
      end
    elseif nil ~= key_lower:find('transfer-encoding', 1, true) then
      sent_transfer_encoding = true
      if nil ~= value_lower:find('chunk', 1, true) then
        self.chunked_encoding = true
      end
    elseif nil ~= key_lower:find('content-length', 1, true) then
      sent_content_length = true
    end
  end

  if headers then
    for key, value in pairs(headers) do
      store(key, value)
    end
  end

  if not sent_connection then
    if self.should_keep_alive and
       (sent_content_length or
        self.chunked_encoding_default or
        self.agent) then
      table.insert(buffer, 'Connection: keep-alive')
    else
      self._last = true
      table.insert(buffer, 'Connection: close')
    end
  end

  if not sent_content_length and not sent_transfer_encoding then
    if self._has_body then
      if self.chunked_encoding_default then
        table.insert(buffer, 'Transfer-Encoding: chunked')
        self.chunked_encoding = true
      else
        self._last = true
      end
    else
      self.chunked_encoding = false
    end
  end

  table.insert(buffer, '\r\n')
  self._header_cache = table.concat(buffer, '\r\n') 

  -- TODO : Expect: 100-continue
end

function OutgoingMessage:write(chunk, callback)
  if not self._has_body then
    local err = 'This type of stream must not have a body.'
    return callbackError(err, callback)
  end

  local length = #chunk
  local ret = true
  if 0 == length then return ret end

  if self.chunked_encoding then
    chunk = table.concat({
      base(length, 16),
      '\r\n',
      chunk,
      '\r\n'
    }, '')

    ret = self:_write(chunk, callback)
  else
    ret = self:_write(chunk, callback)
  end

  return ret
end

-- For munging headers with the body etc.
function OutgoingMessage:_write(chunk, callback)
  local pos = -1

  if not self._headers_sent then
    self._headers_sent = true
    if self._header_cache then
      chunk = table.concat({ self._header_cache, chunk }, '')
      pos = 1
    end
  end

  if self.socket and
     self.socket._http_message == self and
     self.socket.writable then
    local c
    while true do
      c = table.remove(self._write_queue, 1)
      if nil == c then break end
      c = self.socket:write(c[1], c[2])
      if not c then
        table.insert(self._write_queue, pos, { chunk, callback })
        return false
      end
    end

    self._write_queue = {}
    return self.socket:write(chunk, callback)
  end

  table.insert(self._write_queue, pos, { chunk, callback })
  return false
end

function OutgoingMessage:finish(chunk, callback)
  if self.completed then return true end
  if chunk and not self._has_body then
    printStderr('This stream must not have a body. Ignoring body.')
  end

  local ret = false

  if chunk then
    ret = self:write(chunk, callback)
  end

  if self.chunked_encoding then
    if self._trailer then
      table.insert(self._trailer, '\r\n')
      ret = self:_write('0\r\n' .. table.concat(self._trailer, '\r\n'))
      table.remove(self._trailer)
    else
      ret = self:_write('0\r\n\r\n')
    end
  else
    -- TODO : Do we need to force flush here?
    --        Copying node.js here.
    ret = self:_write('')
  end

  self.completed = true

  return ret
end


-- IncomingMessage:new(socket)
--
-- Used for ServerRequest and ClientResponse
local IncomingMessage = iStream:extend()
http.IncomingMessage = IncomingMessage

function IncomingMessage:initialize(socket)
  Socket.initialize(self)
  self.socket = socket

  self.http_version = nil
  self.complete = false
  self.headers = {}
  self.tailers = {}
  self.method = nil
  self.status_code = nil
end

function IncomingMessage:pause()
  if not socket then return false end
  return self.socket:pause()
end

function IncomingMessage:resume()
  if not socket then return false end
  return self.socket:resume()
end

function IncomingMessage:close()
  if not socket then return false end
  self.completed = true
  return self.socket:close()
end

-- Parser metatable and freelist
--
-- This saves on memory usage.
local parser_meta = {}

function parser_meta:reinitialize (flag, socket)
  self.resetState()
  self.userdata:reinitialize(flag)
  self.socket = socket
  return self
end
function parser_meta:onMessageBegin ()
  self._headers = {}
end
function parser_meta:onUrl (url)
end
function parser_meta:onHeaderField (field)
  self._current_field = field
end
function parser_meta:onHeaderValue (value)
  self._headers[self._current_field:lower()] = value
end
function parser_meta:onHeadersComplete (info)
  self.incoming = IncomingMessage:new(self.socket)
  self.incoming.headers = self._headers
  self.incoming.status_code = info.status_code
  self.incoming.version_minor = info.version_minor
  self.incoming.version_major = info.version_major
end
function parser_meta:onBody (chunk)
  response:emit('data', chunk)
end
function parser_meta:onMessageComplete ()
  response:emit('finish')
end
function parser_meta:resetState ()
  self._headers = {}
  self._current_field = nil
  self.incoming = nil
  self.socket = nil
  return self
end
function parser_meta:execute (chunk, offset, length)
  return parser.userdata:execute(chunk, offset, length)
end

local parsers = Freelist:new('parsers', 1000, function (socket)
  local parser = http_parser.new('request', parser_meta)

  -- Init parser
  parser:resetState()

  return parser
end

-- http.request(options, callback)
function http.request(options, callback)
  -- Load options into local variables.  Assume defaults
  local host = options.host or "127.0.0.1"
  local port = options.port or 80
  local method = options.method or "GET"
  local path = options.path or "/"
  local headers = options.headers or {}
  if not headers.host then headers.host = host end

  local client
  client = net.create(port, host, function(err)
    if err then
      callback(err)
      client:close()
      return
    end

    local response = Request:new(client)
    local request = {method .. " " .. path .. " HTTP/1.1\r\n"}
    for field, value in pairs(headers) do
      request[#request + 1] = field .. ": " .. value .. "\r\n"
    end
    request[#request + 1] = "\r\n"
    client:write(table.concat(request))

    local headers
    local current_field

    local parser = HttpParser.new("response", {
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
        response.status_code = info.status_code
        response.version_minor = info.version_minor
        response.version_major = info.version_major

        client:emit('response', response)
      end,
      onBody = function (chunk)
        response:emit('data', chunk)
      end,
      onMessageComplete = function ()
        response:emit('finish')
      end
    })

    client:on("data", function (chunk)
      local nparsed = parser:execute(chunk, 0, #chunk)

      -- If it wasn't all parsed then there was an error parsing
      if nparsed < #chunk then
        client:emit('error', Error:new('parse error in server response'))
      end

    end)

    client:on('finish', function ()
      parser:finish()
    end)
  end)

  if callback then client:on('response', callback) end

  return client
end

function http.createServer(onConnection)
  local server
  server = net.createServer(function(client)
    if err then
      return server:emit("error", err)
    end

    -- Accept the client and build request and response objects
    local request = Request:new(client)
    local response = Response:new(client)

    -- Convert tcp stream to HTTP stream
    local current_field
    local parser
    local headers
    parser = HttpParser.new("request", {
      onMessageBegin = function ()
        headers = {}
        request.headers = headers
      end,
      onUrl = function (url)
        request.url = url
      end,
      onHeaderField = function (field)
        current_field = field
      end,
      onHeaderValue = function (value)
        headers[current_field:lower()] = value
      end,
      onHeadersComplete = function (info)

        request.method = info.method
        request.upgrade = info.upgrade

        request.version_major = info.version_major
        request.version_minor = info.version_minor

        -- Give upgrade requests access to the raw client if they want it
        if info.upgrade then
          request.client = client
        end

        -- Handle 100-continue requests
        if request.headers.expect and info.version_major == 1 and info.version_minor == 1 and request.headers.expect:lower() == "100-continue" then
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
        request:emit('data', chunk, #chunk)
      end,
      onMessageComplete = function ()
        request:emit('finish')
      end
    })


    client:on("data", function (chunk)

      -- Ignore empty chunks
      if #chunk == 0 then return end

      -- Once we're in "upgrade" mode, the protocol is no longer HTTP and we
      -- shouldn't send data to the HTTP parser
      if request.upgrade then
        request:emit("data", chunk)
        return
      end

      -- Parse the chunk of HTTP, this will syncronously emit several of the
      -- above events and return how many bytes were parsed.
      local nparsed = parser:execute(chunk, 0, #chunk)

      -- If it wasn't all parsed then there was an error parsing
      if nparsed < #chunk then
        -- If the error was caused by non-http protocol like in websockets
        -- then that's ok, just emit the rest directly to the request object
        if request.upgrade then
          chunk = chunk:sub(nparsed + 1)
          request:emit("data", chunk)
        else
          request:emit("error", "parse error")
        end
      end

    end)

    client:on('finish', function ()
      parser:finish()
    end)

  end)

  return server
end

return http

