--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

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

local net = require('net')
local Request = require('request')
local Response = require('response')
local HttpParser = require('http_parser')
local table = require('table')
local http = {}

function http.request(options, callback)
  -- Load options into local variables.  Assume defaults
  local host = options.host or "127.0.0.1"
  local port = options.port or 80
  local method = options.method or "GET"
  local path = options.path or "/"
  local headers = options.headers or {}
  if not headers.host then headers.host = host end

  local client
  client = net.create(port, host, function(err)
    if err then
      callback(err)
      client:close()
      return
    end

    local response = Response:new(client)
    local request = {method .. " " .. path .. " HTTP/1.1\r\n"}
    for field, value in pairs(headers) do
      request[#request + 1] = field .. ": " .. value .. "\r\n"
    end
    request[#request + 1] = "\r\n"
    client:write(table.concat(request))

    local headers
    local current_field

    local parser = HttpParser.new("response", {
      onMessageBegin = function ()
        headers = {}
      end,
      onUrl = function (url)
      end,
      onHeaderField = function (field)
        current_field = field
      end,
      onHeaderValue = function (value)
        headers[current_field:lower()] = value
      end,
      onHeadersComplete = function (info)
        response.headers = headers
        response.status_code = info.status_code
        response.version_minor = info.version_minor
        response.version_major = info.version_major

        callback(response)

      end,
      onBody = function (chunk)
        response:emit('data', chunk)
      end,
      onMessageComplete = function ()
        response:emit('end')
      end
    });

    client:on("data", function (chunk)
      local nparsed = parser:execute(chunk, 0, #chunk)

      -- If it wasn't all parsed then there was an error parsing
      if nparsed < #chunk then
        error("Parse error in server response")
      end

    end)

    client:on("end", function ()
      parser:finish()
    end)
  end)

  return client
end

function http.createServer(host, port, onConnection)
  local server
  server = net.createServer(function(client)
    if err then
      return server:emit("error", err)
    end

    -- Accept the client and build request and response objects
    local request = Request:new(client)
    local response = Response:new(client)

    -- Convert tcp stream to HTTP stream
    local current_field
    local parser
    local headers
    parser = HttpParser.new("request", {
      onMessageBegin = function ()
        headers = {}
        request.headers = headers
      end,
      onUrl = function (url)
        request.url = url
      end,
      onHeaderField = function (field)
        current_field = field
      end,
      onHeaderValue = function (value)
        headers[current_field:lower()] = value
      end,
      onHeadersComplete = function (info)

        request.method = info.method
        request.upgrade = info.upgrade

        request.version_major = info.version_major
        request.version_minor = info.version_minor

        -- Give upgrade requests access to the raw client if they want it
        if info.upgrade then
          request.client = client
        end

        -- Handle 100-continue requests
        if request.headers.expect and info.version_major == 1 and info.version_minor == 1 and request.headers.expect:lower() == "100-continue" then
          if server.handlers and server.handlers.check_continue then
            server:emit("check_continue", request, response)
          else
            response:writeContinue()
            onConnection(request, response)
          end
        else
          onConnection(request, response)
        end

      end,
      onBody = function (chunk)
        request:emit('data', chunk, #chunk)
      end,
      onMessageComplete = function ()
        request:emit('end')
      end
    })


    client:on("data", function (chunk)

      -- Ignore empty chunks
      if #chunk == 0 then return end

      -- Once we're in "upgrade" mode, the protocol is no longer HTTP and we
      -- shouldn't send data to the HTTP parser
      if request.upgrade then
        request:emit("data", chunk)
        return
      end

      -- Parse the chunk of HTTP, this will syncronously emit several of the
      -- above events and return how many bytes were parsed.
      local nparsed = parser:execute(chunk, 0, #chunk)

      -- If it wasn't all parsed then there was an error parsing
      if nparsed < #chunk then
        -- If the error was caused by non-http protocol like in websockets
        -- then that's ok, just emit the rest directly to the request object
        if request.upgrade then
          chunk = chunk:sub(nparsed + 1)
          request:emit("data", chunk)
        else
          request:emit("error", "parse error")
        end
      end

    end)

    client:on("end", function ()
      parser:finish()
    end)

  end)

  server:listen(port, host)

  return server
end

return http

