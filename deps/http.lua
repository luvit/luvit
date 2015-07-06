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
exports.version = "1.1.3-1"
exports.dependencies = {
  "luvit/net@1.1.1",
  "luvit/url@1.0.4",
  "luvit/http-codec@1.0.0",
  "luvit/stream@1.1.0",
  "luvit/utils@1.0.0",
}
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/http.lua"
exports.description = "Node-style http client and server module for luvit"
exports.tags = {"luvit", "http", "stream"}

local net = require('net')
local url = require('url')
local codec = require('http-codec')
local Writable = require('stream').Writable
local date = require('os').date
local luvi = require('luvi')
local utils = require('utils')

local IncomingMessage = net.Socket:extend()
exports.IncomingMessage = IncomingMessage

function IncomingMessage:initialize(head, socket)
  net.Socket.initialize(self)
  self.httpVersion = tostring(head.version)
  local headers = {}
  for i = 1, #head do
    local name, value = unpack(head[i])
    headers[name:lower()] = value
  end
  self.headers = headers
  if head.method then
    -- server specific
    self.method = head.method
    self.url = head.path
  else
    -- client specific
    self.statusCode = head.code
    self.statusMessage = head.reason
  end
  self.socket = socket
end

function IncomingMessage:_read()
  self.socket:resume()
end

local ServerResponse = Writable:extend()
exports.ServerResponse = ServerResponse

function ServerResponse:initialize(socket)
  Writable.initialize(self)
  local encode = codec.encoder()
  self.socket = socket
  self.encode = encode
  self.statusCode = 200
  self.headersSent = false
  self.headers = {}
  for _, evt in pairs({'close', 'drain', 'end' }) do
    self.socket:on(evt, utils.bind(self.emit, self, evt))
  end
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

function ServerResponse:write(chunk, callback)
  if chunk and #chunk > 0 then
    self.hasBody = true
  end
  self:flushHeaders()
  return self.socket:write(self.encode(chunk), callback)
end

function ServerResponse:finish(chunk)
  if chunk and #chunk > 0 then
    self.hasBody = true
  end
  self:flushHeaders()
  local last = ""
  if chunk then
    last = last .. self.encode(chunk)
  end
  last = last .. (self.encode("") or "")
  local function maybeClose()
    self:emit('finish')
    if not self.keepAlive then
      self.socket:_end()
    end
  end
  if #last > 0 then
    self.socket:write(last, function()
      maybeClose()
    end)
  else
    maybeClose()
  end
end

function ServerResponse:writeHead(statusCode, headers)
  assert(not self.headersSent, "headers already sent")
  self.headersSent = true
  headers = headers or {}
  local head = {}

  local lower = {}

  local sent_connection, sent_transfer_encoding, sent_content_length
  for key, value in pairs(headers) do
    local klower = key:lower()
    lower[klower] = value
    head[#head + 1] = {tostring(key), tostring(value)}
    if klower == "connection" then
      self.keepAlive = value:lower() ~= "close"
      sent_connection = true
    elseif klower == "transfer-encoding" then
      sent_transfer_encoding = true
    elseif klower == "content-length" then
      sent_content_length = true
    end
  end
  if not lower.date and self.sendDate then
    head[#head + 1] = {"Date", date("!%a, %d %b %Y %H:%M:%S GMT")}
  end
  if self.hasBody and not sent_transfer_encoding and not sent_content_length then
    sent_transfer_encoding = true
    head[#head + 1] = {"Transfer-Encoding", "chunked"}
  end
  if not sent_connection then
    if self.keepAlive then
      if self.hasBody then
        if sent_transfer_encoding or sent_content_length then
          head[#head + 1] = {"Connection", "keep-alive"}
        else
          -- body has no length so close to indicate end
          self.keepAlive = false
          head[#head + 1] = {"Connection", "close"}
        end
      elseif statusCode >= 300 then
        self.keepAlive = false
        head[#head + 1] = {"Connection", "close"}
      else
        head[#head + 1] = {"Connection", "keep-alive"}
      end
    else
      self.keepAlive = false
      head[#head + 1] = {"Connection", "close"}
    end
  end
  head.code = statusCode
  local h = self.encode(head)
  self.socket:write(h)

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

  local function onTimeout()
    socket:_end()
  end

  local function onEnd()
    process:removeListener('exit', onTimeout)
    -- Just in case the stream ended and we still had an open request,
    -- end it.
    if req then flush() end
  end

  local function onData(chunk)
    -- Run the chunk through the decoder by concatenating and looping
    buffer = buffer .. chunk
    while true do
      local R, event, extra = pcall(decode,buffer)
      if R then
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
          res.keepAlive = event.keepAlive

          -- If the request upgrades the protocol then detatch the listeners so http codec is no longer used
          if req.headers.upgrade then
            req.is_upgraded = true
            socket:setTimeout(0)
            socket:removeListener("timeout", onTimeout)
            socket:removeListener("data", onData)
            socket:removeListener("end", onEnd)
            process:removeListener('exit', onTimeout)
            if #buffer > 0 then
              socket:pause()
              socket:unshift(buffer)
            end
            onRequest(req, res)
            break
          else
            -- Call the user callback to handle the request
            onRequest(req, res)
          end
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
      else
        socket:emit('error',event)
        break
      end
    end
  end
  socket:once('timeout', onTimeout)
  -- set socket timeout
  socket:setTimeout(120000)
  socket:on('data', onData)
  socket:on('end', onEnd)
  process:once('exit', onTimeout)
end

function exports.createServer(onRequest)
  return net.createServer(function (socket)
    return exports.handleConnection(socket, onRequest)
  end)
end

local ClientRequest = Writable:extend()
exports.ClientRequest = ClientRequest

function exports.ClientRequest.getDefaultUserAgent()
  if exports.ClientRequest._defaultUserAgent == nil then
    exports.ClientRequest._defaultUserAgent = 'luvit/http/' .. exports.version .. ' luvi/' .. luvi.version
  end
  return exports.ClientRequest._defaultUserAgent
end

function ClientRequest:initialize(options, callback)
  Writable.initialize(self)
  self:cork()
  local headers = options.headers or { }
  local host_found, connection_found, user_agent
  for i, header in ipairs(headers) do
    local key, value = unpack(header)
    local hfound = key:lower() == 'host'
    if hfound then
      host_found = value
    end
    local cfound = key:lower() == 'connection'
    if cfound then
      connection_found = value
    end
    local uafound = key:lower() == 'user-agent'
    if uafound then
      user_agent = value
    end
    table.insert(self, header)
  end

  if not user_agent then
    user_agent = self.getDefaultUserAgent()
  end

  if user_agent ~= '' then
    table.insert(self, 1, { 'user-agent', user_agent })
  end

  if not host_found and options.host then
    table.insert(self, 1, { 'host', options.host })
  end

  self.host = options.host
  self.method = (options.method or 'GET'):upper()
  self.path = options.path or '/'
  self.port = options.port or 80
  self.self_sent = false
  self.connection = connection_found

  self.encode = codec.encoder()
  self.decode = codec.decoder()

  local buffer = ''
  local res

  local function flush()
    res:push()
    res = nil
  end

  local socket = options.socket or net.createConnection(self.port, self.host)
  local connect_emitter = options.connect_emitter or 'connect'

  self.socket = socket
  socket:on('error',function(...) self:emit('error',...) end)
  socket:on(connect_emitter, function()
    self.connected = true
    self:emit('socket', socket)

    local function onEnd()
      -- Just in case the stream ended and we still had an open response,
      -- end it.
      if res then flush() end
    end
    local function onData(chunk)
      -- Run the chunk through the decoder by concatenating and looping
      buffer = buffer .. chunk
      while true do
        local R, event, extra = pcall(self.decode,buffer)
        if R==true then
          -- nil extra means the decoder needs more data, we're done here.
          if not extra then break end
          -- Store the leftover data.
          buffer = extra
          if type(event) == "table" then
            if self.method ~= 'CONNECT' or res == nil then
              -- If there was an old response that never closed, end it.
              if res then flush() end
              -- Create a new response object
              res = IncomingMessage:new(event, socket)
              -- If the request upgrades the protocol then detatch the listeners so http codec is no longer used
              local is_upgraded
              if res.headers.upgrade then
                is_upgraded = true
                socket:removeListener("data", onData)
                socket:removeListener("end", onEnd)
                socket:read(0)
                if #buffer > 0 then
                  socket:pause()
                  socket:unshift(buffer)
                end
              end
              -- Call the user callback to handle the response
              if callback then
                callback(res)
              end
              self:emit('response', res)
              if is_upgraded then
                break
              end
            end
            if self.method == 'CONNECT' then
              self:emit('connect', res, socket, event)
            end
          elseif res and type(event) == "string" then
            if #event == 0 then
              -- Empty string in http-decoder means end of body
              -- End the res stream and remove the res reference.
              flush()
            else
              -- Forward non-empty body chunks to the res stream.
              if not res:push(event) then
                -- If it's queue is full, pause the source stream
                -- This will be resumed by IncomingMessage:_read
                socket:pause()
              end
            end
          end
        else
          self:emit('error', event)
          break
        end
      end
    end
    socket:on('data', onData)
    socket:on('end', onEnd)

    if self.ended then
      self:_done(self.ended.data, self.ended.cb)
    end

  end)
end

function ClientRequest:flushHeaders()
  if not self.headers_sent then
    self.headers_sent = true
    -- set connection
    self:_setConnection()
    Writable.write(self, self.encode(self))
  end
end

function ClientRequest:write(data, cb)
  self:flushHeaders()
  local encoded = self.encode(data)

  -- Don't write empty strings to the socket, it breaks HTTPS.
  if encoded and #encoded > 0 then
    Writable.write(self, encoded, cb)
  else
    if cb then
      cb()
    end
  end
end

function ClientRequest:_write(data, cb)
  self.socket:write(data, cb)
end

function ClientRequest:_done(data, cb)
  self:_end(data, function()
    if cb then
      cb()
    end
  end)
end

function ClientRequest:_setConnection()
  if not self.connection then
    table.insert(self, { 'connection', 'close' })
  end
end

function ClientRequest:done(data, cb)
  -- Optionally send one more chunk
  if data then self:write(data) end

  self:flushHeaders()

  local ended =
    {
      cb = cb or function() end,
      data = ''
    }
  if self.connected then
    self:_done(ended.data, ended.cb)
  else
    self.ended = ended
  end
end

function ClientRequest:setTimeout(msecs, callback)
  if self.socket then
    self.socket:setTimeout(msecs,callback)
  end
end

function ClientRequest:destroy()
  if self.socket then
    self.socket:destroy()
  end
end

function exports.parseUrl(options)
  if type(options) == 'string' then
    options = url.parse(options)
  end
  return options
end

function exports.request(options, onResponse)
  return ClientRequest:new(exports.parseUrl(options), onResponse)
end

function exports.get(options, onResponse)
  options = exports.parseUrl(options)
  options.method = 'GET'
  local req = exports.request(options, onResponse)
  req:done()
  return req
end
