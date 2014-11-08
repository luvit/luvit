
local STATUS_CODES

local server = {}
local client = {}
exports.server = server
exports.client = client

local function parser(read, write, isClient)

  local readHead, rawBody, chunkedBody, countedBody

  function readHead(chunk)
    assert(type(chunk) == "string", "Expected HTTP data")
    local head = chunk
    local item
    local offset = 1
    local headers = {}
    local contentLength
    local chunkedEncoding
    local keepAlive
    while true do
      local s = string.find(head, '\r\n', offset, true)

      -- If there is no \r\n found, read more data
      if not s then
        chunk = read()
        assert(type(chunk) == "string", "Expected HTTP data")
        head = head .. chunk

      -- If this is the first line, parse it special
      elseif not item then
        item = { headers = headers }
        if isClient then
          item.version, item.code, item.reason = string.match(head, "HTTP/(%d%.%d) (%d+) (%u+)\r\n", offset)
          item.version = tonumber(item.version)
          item.code = tonumber(item.code)
        else
          item.method, item.path, item.version = string.match(head, "(%u+) ([^ ]+) HTTP/(%d%.%d)\r\n", offset)
          item.version = tonumber(item.version)
        end
        keepAlive = item.version >= 1.1
        offset = s + 2

      -- Parse all other non-empty lines as header key/value pairs
      elseif s > offset then
        local key, value = string.match(head, "([^:]+): *([^\r]+)\r\n", offset)
        local lowerKey = string.lower(key)
        if lowerKey == "content-length" then
          contentLength = tonumber(value)
        elseif lowerKey == "transfer-encoding" then
          chunkedEncoding = string.lower(value) == "chunked"
        elseif lowerKey == "connection" then
          keepAlive = string.lower(value) == "keep-alive"
        end
        headers[#headers + 1] = {key, value}
        offset = s + 2

      -- When a double "\r\n\r\n" if found, we're done with the head.
      else
        write(item)
        local length = #head
        if length > offset + 1 then
          chunk = string.sub(head, offset + 2)
        else
          chunk = read()
          -- If the connection is closed here, close our end.
          if chunk == nil then
            return write()
          end
        end

        if chunkedEncoding then
          return chunkedBody(chunk)
        elseif contentLength == 0 then
          return readHead(chunk)
        elseif contentLength then
          return countedBody(chunk, contentLength)
        elseif keepAlive then
          return readHead(chunk)
        else
          return rawBody(chunk)
        end
      end
    end
  end

  function rawBody(chunk)
    while chunk do
      assert(type(chunk) == "string")
      write(chunk)
      chunk = read()
    end
    write(chunk);
  end

  function countedBody(chunk, length)
    while true do
      assert(type(chunk) == "string")
      length = length - #chunk
      if length < 0 then
        write(string.sub(chunk, 1, length - 1))
        return readHead(string.sub(chunk, length))
      elseif length == 0 then
        write(chunk)
        return readHead(read())
      else
        write(chunk)
      end
    end
  end

  function chunkedBody(chunk)
    error("TODO: Implement chunkedEncoding parsing")
  end

  return readHead(read())

end

function server.decoder(read, write)
  return parser(read, write, false)
end

function client.decoder(read, write)
  return parser(read, write, true)
end

function server.encoder(read, write)
  for item in read do
    if type(item) ~= 'table' then
      write(item)
    else
      local head = { 'HTTP/1.1 ' .. item.code .. ' ' .. STATUS_CODES[item.code] .. '\r\n' }
      for i = 1, #item.headers do
        local pair = item.headers[i]
        head[#head + 1] = pair[1] .. ': ' .. tostring(pair[2]) .. '\r\n'
      end
      head[#head + 1] = '\r\n'
      write(table.concat(head))
    end
  end
  write()
end


function client.encoder(read, write)
  for item in read do
    if type(item) ~= 'table' then
      write(item)
    else
      local head = { item.method .. ' ' .. item.path .. ' HTTP/1.1\r\n' }
      for i = 1, #item.headers do
        local pair = item.headers[i]
        head[#head + 1] = pair[1] .. ': ' .. tostring(pair[2]) .. '\r\n'
      end
      head[#head + 1] = '\r\n'
      write(table.concat(head))
    end
  end
end

STATUS_CODES = {
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
  [418] = "I'm a teapot",               -- RFC 2324
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
