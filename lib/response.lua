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

local Emitter = require('emitter')
local osDate = require('os').date
local tableConcat = require('table').concat
local stringFormat = require('string').format

local Response = Emitter:extend()

local status_codes_table = {
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



function Response.prototype:initialize(socket)
  self.code = 200
  self.headers = {}
  self.header_names = {}
  self.headers_sent = false
  self.body_started = false
  self.closing = false
  self.socket = socket
  self.socket:on('drain', function (...)
    if not self.body_started or self.closing then return end
    self:emit('drain', ...)
  end)
end

Response.prototype.auto_date = true
Response.prototype.auto_server = "Luvit"
Response.prototype.auto_chunked_encoding = true
Response.prototype.auto_content_length = true
Response.prototype.auto_content_type = "text/html"

function Response.prototype:setCode(code)
  if self.headers_sent then error("Headers already sent") end
  self.code = code
end

-- This sets a header, replacing any header with the same name (case insensitive)
function Response.prototype:setHeader(name, value)
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
function Response.prototype:addHeader(name, value)
  if self.headers_sent then error("Headers already sent") end
  self.headers[#self.headers + 1] = { name, value }
  return #self.headers
end

-- Removes a set header.  Cannot remove headers added with :addHeader
function Response.prototype:unsetHeader(name)
  if self.headers_sent then error("Headers already sent") end
  local lower = name:lower()
  local name = self.header_names[lower]
  if not name then return end
  self.headers[name] = nil
  self.header_names[lower] = nil
end

function Response.prototype:flushHead(callback)
  if self.headers_sent then error("Headers already sent") end

  local reason = status_codes_table[self.code]
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
    if self.code == 204 or self.code == 304 or (self.code >= 100 and self.code < 200) then
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

  head = tableConcat(head, "") .. "\r\n"
  local ret = self.socket:write(head, callback)
  self.headers_sent = true
  return ret
end

function Response.prototype:writeHead(code, headers, callback)
  if self.headers_sent then error("Headers already sent") end

  self.code = code
  for field, value in pairs(headers) do
    if type(field) == "number" then
      field = #self.headers + 1
    end
    self.headers[field] = value
  end

  return self:flushHead(callback)
end

function Response.prototype:writeContinue(callback)
  self.socket:write('HTTP/1.1 100 Continue\r\n\r\n', callback)
end

function Response.prototype:write(chunk, callback)
  if self.has_body == false then error("Body not allowed") end
  if not self.headers_sent then
    self.has_body = true
    self:flushHead()
  end
  if self.chunked then
    self.socket:write(stringFormat("%x\r\n", #chunk))
    self.socket:write(chunk)
    self.body_started = true
    return self.socket:write("\r\n", callback)
  end
  local ret = self.socket:write(chunk, callback)
  self.body_started = true
  return ret
end

function Response.prototype:finish(chunk, callback)
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
    self:close()
    if callback then
      self:on("closed", callback)
    end
  end)
  self.closing = true
end

function Response.prototype:close(...)
  return self.socket:close(...)
end

return Response
