local user_meta = require('utils').user_meta
local tcp_meta = require('tcp').meta
local os_date = require('os').date
local table_concat = require('table').concat
local string_format = require('string').format
local Response = {}

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

Response.prototype = {}
setmetatable(Response.prototype, tcp_meta)

-- Don't register new event types with the userdata, this should be a plain lua emitter
function Response.prototype.add_handler_type() end

function Response.new(client)
  local response = {
    code = 200,
    headers = {},
    header_names = {},
    headers_sent = false,
    userdata = client.userdata,
    prototype = Response.prototype
  }
  setmetatable(response, user_meta)
  return response
end

Response.prototype.auto_date = true
Response.prototype.auto_server = "Luvit"
Response.prototype.auto_chunked_encoding = true
Response.prototype.auto_content_length = true
Response.prototype.auto_content_type = "text/html"

function Response.prototype:set_code(code)
  if self.headers_sent then error("Headers already sent") end
  self.code = code
end

-- This sets a header, replacing any header with the same name (case insensitive)
function Response.prototype:set_header(name, value)
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
function Response.prototype:add_header(name, value)
  if self.headers_sent then error("Headers already sent") end
  self.headers[#self.headers + 1] = name .. ": " .. value
  return #self.headers
end

-- Removes a set header.  Cannot remove headers added with :add_header
function Response.prototype:unset_header(name)
  if self.headers_sent then error("Headers already sent") end
  local lower = name:lower()
  local name = self.header_names[lower]
  if not name then return end
  self.headers[name] = nil
  self.header_names[lower] = nil
end

function Response.prototype:flush_head(callback)
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
    if type(field) == "number" then
      field, value = value:match("^ *([^ :]+): *([^ ]+) *$")
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
    head[length] = os_date("!Date: %a, %d %b %Y %H:%M:%S GMT\r\n")
  end

  head = table_concat(head, "") .. "\r\n"
  self.userdata:write(head, callback)
  self.headers_sent = true
end

function Response.prototype:write_head(code, headers, callback)
  if self.headers_sent then error("Headers already sent") end

  self.code = code
  for field, value in pairs(headers) do
    if type(field) == "number" then
      field = #self.headers + 1
    end
    self.headers[field] = value
  end

  self:flush_head(callback)
end

function Response.prototype:write_continue(callback)
  self.userdata:write('HTTP/1.1 100 Continue\r\n\r\n', callback)
end

function Response.prototype:write(chunk, callback)
  if self.has_body == false then error("Body not allowed") end
  if not self.headers_sent then
    self.has_body = true
    self:flush_head()
  end
  local userdata = self.userdata
  if self.chunked then
    userdata:write(string_format("%x\r\n", #chunk))
    userdata:write(chunk)
    return userdata:write("\r\n", callback)
  end
  return userdata:write(chunk, callback)
end

function Response.prototype:finish(chunk, callback)
  if chunk and self.has_body == false then error ("Body not allowed") end
  if not self.headers_sent then
    if self.has_body == nil then
      if chunk then
        if self.auto_content_length and #self.headers == 0
         and (not self.header_names["content-length"])
         and (not self.header_names["transfer-encoding"]) then
          self:set_header("Content-Length", #chunk)
        end
        self.has_body = true
      else
        self.has_body = false
      end
    end
    self:flush_head()
  end
  if type(chunk) == "function" and callback == nil then
    callback = chunk
    chunk = nil
  end
  if chunk then
    self:write(chunk)
  end
  if self.chunked then
    self.userdata:write('0\r\n\r\n')
  end
  self:shutdown(function ()
    self:close()
    if callback then
      self:on("closed", callback)
    end
  end)
end


return Response
