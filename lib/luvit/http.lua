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

--------------------------------------------------------------------------------

local Request = iStream:extend()
http.Request = Request

function Request:initialize(socket)
  self.socket = socket
end

function Request:close(...)
  return self.socket:close(...)
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
    headers[old_name] = nil
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
    end
    length = length + 1
    head[length] = field .. ": " .. value .. "\r\n"
  end

  -- Implement auto headers so people's http server are more spec compliant
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
  self.socket:shutdown(function ()
    self:emit("end")
    self:close()
    if callback then
      self:on("closed", callback)
    end
  end)
end

function Response:close(...)
  return self.socket:close(...)
end

--------------------------------------------------------------------------------

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
    -- FIXME: pairs() toss headers, while order can be significant!
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
        response:emit("data", chunk)
      end,
      onMessageComplete = function ()
        response:emit("end")
      end
    });

    client:on("data", function (chunk)

      -- Ignore empty chunks
      if #chunk == 0 then return end

      -- Once we're in "upgrade" mode, the protocol is no longer HTTP and we
      -- shouldn't send data to the HTTP parser
      if response.upgrade then
        response:emit("data", chunk)
        return
      end

      local nparsed = parser:execute(chunk, 0, #chunk)

      -- If it wasn't all parsed then there was an error parsing
      if nparsed < #chunk then
        response:emit("error", "parse error")
      end

    end)

    client:once("end", function ()
      parser:finish()
    end)

    client:once("error", function (err)
      parser:finish()
      response:emit("error", err)
    end)

  end)

  return client
end

function http.createServer(onConnection)
  local server
  server = net.createServer(function (client)

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
        request:emit("error", "parse error")
      end

    end)

    client:once("end", function ()
      parser:finish()
    end)

    client:once("error", function (err)
      parser:finish()
      request:emit("error", err)
    end)

  end)

  return server
end

return http

