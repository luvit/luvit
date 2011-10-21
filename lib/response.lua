local user_meta = require('utils').user_meta
local TCP = require('tcp')
local OS = require('os')
local Table = require('table')
local String = require('string')
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
setmetatable(Response.prototype, TCP.meta)

function Response.new(client)
  local response = {
    userdata = client.userdata,
    prototype = Response.prototype
  }
  setmetatable(response, user_meta)
  return response
end

function Response.prototype:write_head(code, headers, callback)

  local reason = status_codes_table[code]
  if not reason then error("Invalue response code " .. tostring(code)) end

  local head = {"HTTP/1.1 " .. code .. " " .. reason .. "\r\n"}
  local length = 1
  local has_server, has_content_length, has_date

  for field, value in pairs(headers) do
    local lower = field:lower()
    if lower == "server" then has_server = true
    elseif lower == "content-length" then has_content_length = true
    elseif lower == "date" then has_date = true
    elseif lower == "transfer-encoding" and value:lower() == "chunked" then self.chunked = true
    end
    length = length + 1
    head[length] = field .. ": " .. value .. "\r\n"
  end
  if not has_server then
    length = length + 1
    head[length] = "Server: Luvit\r\n"
  end
  if not has_content_length then
    length = length + 1
    self.chunked = true
    head[length] = "Transfer-Encoding: chunked\r\n"
  end
  if not has_date then
    -- This should be RFC 1123 date format
    -- IE: Tue, 15 Nov 1994 08:12:31 GMT
    length = length + 1
    head[length] = OS.date("!Date: %a, %d %b %Y %H:%M:%S GMT\r\n")
  end


  head = Table.concat(head, "") .. "\r\n"
  self.userdata:write(head, callback)
end

function Response.prototype:write_continue()
  self.userdata:write('HTTP/1.1 100 Continue\r\n\r\n')
end

function Response.prototype:write(chunk)
  local userdata = self.userdata
  if self.chunked then
    userdata:write(String.format("%x\r\n", #chunk))
    userdata:write(chunk)
    userdata:write("\r\n")
  end
  return self.userdata:write(chunk)
end

function Response.prototype:finish(chunk)
  if chunk then
    self:write(chunk)
  end
  if self.chunked then
    self.userdata:write('0\r\n\r\n')
  end
  self:close()
end


return Response
