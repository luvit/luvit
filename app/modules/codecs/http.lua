--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

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

local STATUS_CODES

local server = {}
local client = {}
exports.server = server
exports.client = client

local function decoder(read, write, isClient)

  local readHead, rawBody, chunkedBody, countedBody

  function readHead(chunk)
    assert(type(chunk) == "string", "Expected HTTP data")
    local head = chunk
    local item
    local offset = 1
    local contentLength
    local chunkedEncoding
    while true do
      local s = string.find(head, '\r\n', offset, true)
      -- If there is no \r\n found, read more data
      if not s then
        chunk = read()
        assert(type(chunk) == "string", "Expected HTTP data")
        head = head .. chunk

      -- If this is the first line, parse it special
      elseif not item then
        item = {}
        if isClient then
          item.version, item.code, item.reason = string.match(head, "^HTTP/(%d%.%d) (%d+) ([^\r]+)\r\n", offset)
          item.version = tonumber(item.version)
          item.code = tonumber(item.code)
        else
          item.method, item.path, item.version = string.match(head, "^(%u+) ([^ ]+) HTTP/(%d%.%d)\r\n", offset)
          item.version = tonumber(item.version)
        end
        item.keepAlive = item.version >= 1.1
        offset = s + 2

      -- Parse all other non-empty lines as header key/value pairs
      elseif s > offset then
        local key, value = string.match(head, "^([^:]+): *([^\r]+)\r\n", offset)
        local lowerKey = string.lower(key)
        if lowerKey == "content-length" then
          contentLength = tonumber(value)
        elseif lowerKey == "transfer-encoding" then
          chunkedEncoding = string.lower(value) == "chunked"
        elseif lowerKey == "connection" then
          item.keepAlive = string.lower(value) == "keep-alive"
        end
        item[#item + 1] = {key, value}
        offset = s + 2

      -- When a double "\r\n\r\n" if found, we're done with the head.
      else
        write(item)
        if item.keepAlive and not (chunkedEncoding or (contentLength and contentLength > 0)) then
          write("")
        end

        if #head > offset + 1 then
          chunk = string.sub(head, offset + 2)
        else
          chunk = read()
        end

        if chunkedEncoding then
          return chunkedBody(chunk)
        elseif contentLength then
          return countedBody(chunk, contentLength)
        elseif item.keepAlive then
          if chunk == nil then
            return write()
          end
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
      if #chunk > 0 then
        write(chunk)
      end
      chunk = read()
    end
    write("")
    write();
  end

  function countedBody(chunk, length)
    while length > 0 do
      assert(type(chunk) == "string")
      length = length - #chunk
      if length < 0 then
        -- If the start of the next head is in the same chunk, split it.
        write(string.sub(chunk, 1, length - 1))
        write("")
        return readHead(string.sub(chunk, length))
      elseif length == 0 then
        -- If it was a clean end, write it...
        write(chunk)
        write("")
        -- And start the next read
        chunk = read()
        if chunk ~= nil then
          return readHead(chunk)
        end
      else
        -- If it's just part of the body, write it and continue
        write(chunk)
        chunk = read()
      end
    end
    write()
  end

  function chunkedBody(chunk)
    local match, term
    while true do
      match, term = string.match(chunk, "^(%x+)(..)")
      if match then break end
      local item = read()
      assert(type(item) == "string")
      chunk = chunk .. item
    end
    assert(term == "\r\n")
    local length = tonumber(match, 16)
    chunk = string.sub(chunk, #match + 3)
    while #chunk < length + 2 do
      local item = read()
      assert(type(item) == "string")
      chunk = chunk .. item
    end
    assert(string.sub(chunk, length + 1, length + 2) == "\r\n")
    write(string.sub(chunk, 1, length))
    chunk = string.sub(chunk, length + 3)
    if #chunk == 0 then
      chunk = read()
    end
    if length == 0 then
      if chunk == nil then
        return write()
      else
        return readHead(chunk)
      end
    end
    return chunkedBody(chunk)
  end

  return readHead(read())

end

local function encoder(read, write, isClient)

  local chunkedEncoding

  local function writeHead(item)
    local head
    local version = item.version or 1.1
    if isClient then
      head = { item.method .. ' ' .. item.path .. ' HTTP/' .. version .. '\r\n' }
    else
      local reason = item.reason or STATUS_CODES[item.code]
      head = { 'HTTP/' .. version .. ' ' .. item.code .. ' ' .. reason .. '\r\n' }
    end
    for i = 1, #item do
      local key, value = unpack(item[i])
      local lowerKey = string.lower(key)
      if lowerKey == "transfer-encoding" then
        chunkedEncoding = string.lower(value) == "chunked"
      end
      head[#head + 1] = key .. ': ' .. tostring(value) .. '\r\n'
    end
    head[#head + 1] = '\r\n'
    write(table.concat(head))
  end

  for item in read do
    local t = type(item)
    if t == "string" then
      if chunkedEncoding then
        write(string.format("%x", #item) .. "\r\n" .. item .. "\r\n")
        if #item == 0 then chunkedEncoding = nil end
      elseif #item > 0 then
        write(item)
      end
    else
      if chunkedEncoding then
        write("0\r\n\r\n")
        chunkedEncoding = nil
      end
      if t == "table" then
        writeHead(item)
      else
      end
    end
  end
  if chunkedEncoding then
    write("0\r\n\r\n")
    chunkedEncoding = nil
  end
  write()

end

function server.decoder(read, write)
  return decoder(read, write, false)
end

function client.decoder(read, write)
  return decoder(read, write, true)
end

function server.encoder(read, write)
  return encoder(read, write, false)
end

function client.encoder(read, write)
  return encoder(read, write, true)
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
