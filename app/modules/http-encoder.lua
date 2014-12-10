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

return function ()

  local mode
  local encodeHead, encodeRaw, encodeChunked

  function encodeHead(item)
    if not item then return end
    local head, chunkedEncoding
    local version = item.version or 1.1
    if item.method then
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

    mode = chunkedEncoding and encodeChunked or encodeRaw
    return table.concat(head)
  end

  function encodeRaw(item)
    if type(item) ~= "string" then
      mode = encodeHead
      return encodeHead(item)
    end
    return item
  end

  function encodeChunked(item)
    if type(item) ~= "string" then
      mode = encodeHead
      local extra = encodeHead(item)
      if extra then
        return "0\r\n\r\n" .. extra
      else
        return "0\r\n\r\n"
      end
    end
    if #item == 0 then
      mode = encodeHead
    end
    return string.format("%x", #item) .. "\r\n" .. item .. "\r\n"
  end

  mode = encodeHead
  return function (item)
    return mode(item)
  end
end
