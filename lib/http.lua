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
local stringFormat = require('string').format
local iStream = require('core').iStream
local Error = require('core').Error
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


-- OutgoingMessage:new(socket)
--
-- Used for ServerResponse and ClientRequest
local OutgoingMessage = iStream:extend()
http.OutgoingMessage = OutgoingMessage

function OutgoingMessage:initialize(port, host, onConnection)
  Socket.initialize(self)
  self.socket = net.create(port, host, onConnection)
end

function OutgoingMessage:pause()
  if not socket then return false end
  return self.socket:pause()
end

function OutgoingMessage:resume()
  if not socket then return false end
  return self.socket:resume()
end

function OutgoingMessage:close()
  if not socket then return false end
  return self.socket:close()
end

function OutgoingMessage:write(chunk, callback)
end


-- IncomingMessage:new(socket)
--
-- Used for ServerRequest and ClientResponse
local IncomingMessage = iStream:extend()
http.IncomingMessage = IncomingMessage

function

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
  response:emit('end')
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

    local response = Response:new(client)
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

        callback(response)

      end,
      onBody = function (chunk)
        response:emit('data', chunk)
      end,
      onMessageComplete = function ()
        response:emit('end')
      end
    });

    client:on("data", function (chunk)
      local nparsed = parser:execute(chunk, 0, #chunk)

      -- If it wasn't all parsed then there was an error parsing
      if nparsed < #chunk then
        client:emit('error', Error:new('parse error in server response'))
      end

    end)

    client:on("end", function ()
      parser:finish()
    end)
  end)

  return client
end

function http.createServer(host, port, onConnection)
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
        request:emit('end')
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

    client:on("end", function ()
      parser:finish()
    end)

  end)

  server:listen(port, host)

  return server
end

return http

