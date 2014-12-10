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


return function ()

  -- This decoder is somewhat stateful with 5 different parsing states.
  local decodeHead, decodeEmpty, decodeRaw, decodeChunked, decodeCounted
  local mode -- state variable that points to various decoders
  local bytesLeft -- For counted decoder

  -- This state is for decoding the status line and headers.
  function decodeHead(chunk)
    if not chunk then return end

    local _, length = string.find(chunk, "\r\n\r\n", 1, true)
    -- First make sure we have all the head before continuing
    if not length then
      if #chunk < 8 * 1024 then return end
      -- But protect against evil clients by refusing heads over 8K long.
      error("entity too large")
    end

    -- Parse the status/request line
    local head = {}
    local _, offset
    _, offset, head.version, head.code, head.reason =
      string.find(chunk, "^HTTP/(%d%.%d) (%d+) ([^\r]+)\r\n")
    if offset then
      head.code = tonumber(head.code)
    else
      _, offset, head.method, head.path, head.version =
        string.find(chunk, "^(%u+) ([^ ]+) HTTP/(%d%.%d)\r\n")
      if not offset then
        error("expected HTTP data")
      end
    end
    head.version = tonumber(head.version)
    head.keepAlive = head.version > 1.0

    -- We need to inspect some headers to know how to parse the body.
    local contentLength
    local chunkedEncoding

    -- Parse the header lines
    while true do
      local key, value
      _, offset, key, value = string.find(chunk, "^([^:]+): *([^\r]+)\r\n", offset + 1)
      if not offset then break end
      local lowerKey = string.lower(key)

      -- Inspect a few headers and remember the values
      if lowerKey == "content-length" then
        contentLength = tonumber(value)
      elseif lowerKey == "transfer-encoding" then
        chunkedEncoding = string.lower(value) == "chunked"
      elseif lowerKey == "connection" then
        head.keepAlive = string.lower(value) == "keep-alive"
      end
      head[#head + 1] = {key, value}
    end

    if head.keepAlive and not (chunkedEncoding or (contentLength and contentLength > 0)) then
      mode = decodeEmpty
    elseif chunkedEncoding then
      mode = decodeChunked
    elseif contentLength then
      bytesLeft = contentLength
      mode = decodeCounted
    elseif not head.keepAlive then
      mode = decodeRaw
    end

    return head, string.sub(chunk, length + 1)

  end

  -- This is used for inserting a single empty string into the output string for known empty bodies
  function decodeEmpty(chunk)
    mode = decodeHead
    return "", chunk or ""
  end

  function decodeRaw(chunk)
    if not chunk then return "", "" end
    if #chunk == 0 then return end
    return chunk, ""
  end

  function decodeChunked(chunk)
    local match, term
    match, term = string.match(chunk, "^(%x+)(..)")
    if not match then return end
    assert(term == "\r\n")
    local length = tonumber(match, 16)
    if #chunk < length + 4 + #match then return end
    if length == 0 then
      mode = decodeHead
    end
    chunk = string.sub(chunk, #match + 3)
    assert(string.sub(chunk, length + 1, length + 2) == "\r\n")
    return string.sub(chunk, 1, length), string.sub(chunk, length + 3)
  end

  function decodeCounted(chunk)
    if bytesLeft == 0 then
      mode = decodeEmpty
      return mode(chunk)
    end
    local length = #chunk
    -- Make sure we have at least one byte to process
    if length == 0 then return end

    -- If the entire chunk fits, pass it all through
    if length <= bytesLeft then
      bytesLeft = bytesLeft - length
      return chunk, ""
    end

    mode = decodeEmpty
    return string.sub(chunk, 1, bytesLeft), string.sub(chunk, bytesLeft + 1)
  end

  -- Switch between states by changing which decoder mode points to
  mode = decodeHead
  return function (chunk)
    return mode(chunk)
  end

end
