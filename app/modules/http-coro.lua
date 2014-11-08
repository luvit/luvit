
local STATUS_CODES

local server = {}
local client = {}
exports.server = server
exports.client = client

local function parser(read, write, isClient)
  -- 0 for headers, 1 for body
  local state = 0
  local head
  local offset = 1
  local headers = {}
  local item

  for chunk in read do
    if type(chunk) ~= 'string' then
      write(chunk)
    elseif state == 0 then
      head = head and (head .. chunk) or chunk
      while true do
        local s, e = string.find(head, '\r\n', offset, true)
        if not s then break end
        if s == offset then
          local event = item
          -- TODO write extra data after headers in same chunk
          item = nil
          headers = {}
          offset = 1
          head = nil
          state = 1
          write(event)
          break
        end
        if not item then
          item = { headers = headers }
          if isClient then
            item.version, item.code, item.reason = string.match(head, "HTTP/(%d%.%d) (%d+) (%u+)\r\n", offset)
            item.version = tonumber(item.version)
            item.code = tonumber(item.code)
          else
            item.method, item.path, item.version = string.match(head, "(%u+) ([^ ]+) HTTP/(%d%.%d)\r\n", offset)
            item.version = tonumber(item.version)
          end
        else
          headers[#headers + 1] = {string.match(head, "([^:]+): *([^\r]+)\r\n", offset)}
        end
        offset = e + 1
      end
    else
      -- TODO: chunked encoding
      write(chunk)
    end
  end
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
