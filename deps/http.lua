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
exports.version = "1.0.3"

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
  local encode = codec.encoder()
  self.socket = socket
  self.encode = encode
  self.statusCode = 200
  self.headersSent = false
  self.headers = {}
  for _, evt in pairs({'close', 'finish'}) do
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
    if key:lower() == 'transfer-encoding' then
      self.transfer_encoding = value
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
    res:_end()
    res = nil
  end

  local socket = options.socket or net.createConnection(self.port, self.host)
  local connect_emitter = options.connect_emitter or 'connect'

  self.socket = socket
  socket:on('error',function(...) self:emit('error',...) end)
  socket:on(connect_emitter, function()
    self.connected = true
    self:emit('socket', socket)

    socket:on('data', function(chunk)
      -- Run the chunk through the decoder by concatenating and looping
      buffer = buffer .. chunk
      while true do
        local event, extra = self.decode(buffer)
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
            -- Call the user callback to handle the response
            if callback then
              callback(res)
            end
            self:emit('response', res)
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
      end
    end)
    socket:on('end', function ()
      -- Just in case the stream ended and we still had an open response,
      -- end it.
      if res then flush() end
    end)

    if self.ended then
      self:_done(self.ended.data, self.ended.encoding, self.ended.cb)
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

function ClientRequest:write(data, encoding, cb)
  self:flushHeaders()
  Writable.write(self, self.encode(data), encoding, cb)
end

function ClientRequest:_write(data, encoding, cb)
  self.socket:write(data, encoding, cb)
end

function ClientRequest:_done(data, encoding, cb)
  self:_end(data, encoding, function()
    self.socket = nil
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

function ClientRequest:done(data, encoding, cb)
  -- Send the data if connected otherwise just mark it ended
  if self.transfer_encoding and self.transfer_encoding:lower() == 'chunked' then
    self:write('') -- Send nothing/ends chunked encoded data/flush header
  else
    self:flushHeaders() --just flush the headers
  end
  self.ended =
    {cb = cb or function() end
    ,data = data
    ,encoding = encoding}
  if self.connected then
    self:_done(self.encode(data), encoding, cb)
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

