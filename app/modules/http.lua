--[[

Copyright 2015 The Luvit Authors. All Rights Reserved.

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

exports.name = "luvit/http"
exports.version = "0.1.0"

local net = require('net')
local codec = require('http-codec')
local Readable = require('stream').Readable
local Writable = require('stream').Writable
local date = require('os').date

local IncomingMessage = Readable:extend()
exports.IncomingMessage = IncomingMessage

function IncomingMessage:initialize(head, socket)
  Readable.initialize(self)
  self.httpVersion = tostring(head.version)
  local headers = {}
  for i = 1, #head do
    local name, value = unpack(head[i])
    headers[name:lower()] = value
  end
  self.headers = headers
  self.method = head.method
  self.url = head.path
  self.socket = socket
end

function IncomingMessage:_read()
  self.socket:resume()
end

local ServerResponse = Writable:extend()
exports.ServerResponse = ServerResponse

function ServerResponse:initialize(socket)
  local encode = codec.encoder()
  self.socket = socket
  self.encode = encode
  self.statusCode = 200
  self.headersSent = false
  self.headers = {}
end

-- Override this in the instance to not send the date
ServerResponse.sendDate = true

function ServerResponse:setHeader(name, value)
  assert(not self.headersSent, "headers already sent")
  self.headers[name] = value
end

function ServerResponse:getHeader(name)
  assert(not self.headersSent, "headers already sent")
  local lower = name:lower()
  for key, value in pairs(self.headers) do
    if lower == key:lower() then
      return value
    end
  end
end

function ServerResponse:removeHeader(name)
  assert(not self.headersSent, "headers already sent")
  local lower = name:lower()
  local toRemove = {}
  for key in pairs(self.headers) do
    if lower == key:lower() then
      toRemove[#toRemove + 1] = key
    end
  end
  for i = 1, #toRemove do
    self.headers[toRemove[i]] = nil
  end
end

function ServerResponse:flushHeaders()
  if self.headersSent then return end
  self:writeHead(self.statusCode, self.headers)
end

function ServerResponse:write(chunk)
  self:flushHeaders()
  return self.socket:write(self.encode(chunk))
end

function ServerResponse:finish(chunk)
  self:flushHeaders()
  local last = ""
  if chunk then
    last = last .. self.encode(chunk)
  end
  last = last .. (self.encode("") or "")
  if #last > 0 then
    self.socket:write(last)
  end
  self.socket:_end()
end

function ServerResponse:writeHead(statusCode, headers)
  assert(not self.headersSent, "headers already sent")
  self.headersSent = true
  headers = headers or {}
  local head = {}

  local lower = {}

  for key, value in pairs(headers) do
    lower[key:lower()] = value
    head[#head + 1] = {tostring(key), tostring(value)}
  end
  if not lower.date and self.sendDate then
    head[#head + 1] = {"Date", date("!%a, %d %b %Y %H:%M:%S GMT")}
  end
  if not lower["content-length"] and not lower["transfer-encoding"] then
    head[#head + 1] = {"Transfer-Encoding", "chunked"}
  end
  head.code = statusCode
  self.socket:write(self.encode(head))

end

function exports.handleConnection(socket, onRequest)

  -- Initialize the two halves of the stateful decoder and encoder for HTTP.
  local decode = codec.decoder()

  local buffer = ""
  local req, res

  local function flush()
    req:push()
    req = nil
  end

  socket:on('data', function (chunk)
    -- Run the chunk through the decoder by concatenating and looping
    buffer = buffer .. chunk
    while true do
      local event, extra = decode(buffer)
      -- nil extra means the decoder needs more data, we're done here.
      if not extra then break end
      -- Store the leftover data.
      buffer = extra
      if type(event) == "table" then
        -- If there was an old request that never closed, end it.
        if req then flush() end
        -- Create a new request object
        req = IncomingMessage:new(event, socket)
        -- Create a new response object
        res = ServerResponse:new(socket)
        -- Call the user callback to handle the request
        onRequest(req, res)
      elseif req and type(event) == "string" then
        if #event == 0 then
          -- Empty string in http-decoder means end of body
          -- End the request stream and remove the req reference.
          flush()
        else
          -- Forward non-empty body chunks to the req stream.
          if not req:push(event) then
            -- If it's queue is full, pause the source stream
            -- This will be resumed by IncomingMessage:_read
            socket:pause()
          end
        end
      end
    end
  end)
  socket:on('end', function ()
    -- Just in case the stream ended and we still had an open request,
    -- end it.
    if req then flush() end
  end)
end

function exports.createServer(onRequest)
  return net.createServer(function (socket)
    return exports.handleConnection(socket, onRequest)
  end)
end

