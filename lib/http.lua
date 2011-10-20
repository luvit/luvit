local TCP = require('tcp')
local Request = require('request')
local Response = require('response')
local HTTP_Parser = require('http_parser')
local HTTP = {}


function HTTP.create_server(host, port, on_connection)
  local server = TCP.new()
  server:bind(host, port)
  server:listen(function (err)
    if err then
      return server:emit("error", err)
    end

    -- Accept the client and build request and response objects
    local client = TCP.new()
    server:accept(client)
    client:read_start()
    local request = Request.new(client)
    local response = Response.new(client)

    -- Convert TCP stream to HTTP stream
    local current_field
    local parser
    local headers
    parser = HTTP_Parser.new("request", {
      on_message_begin = function ()
        headers = {}
        request.headers = headers
      end,
      on_url = function (url)
        request.url = url
      end,
      on_header_field = function (field)
        current_field = field
      end,
      on_header_value = function (value)
        headers[current_field:lower()] = value
      end,
      on_headers_complete = function (info)

        request.method = info.method
        request.upgrade = info.upgrade

        on_connection(request, response)

        -- We're done with the parser once we hit an upgrade
        if request.upgrade then
          parser:finish()
        end
      end,
      on_body = function (chunk)
        request:emit('data', chunk)
      end,
      on_message_complete = function ()
        parser:finish()
        request:emit('end')
      end
    })


    client:on("data", function (chunk, len)

      -- Ignore empty chunks
      if len == 0 then return end

      -- Once we're in "upgrade" mode, the protocol is no longer HTTP and we
      -- shouldn't send data to the HTTP parser
      if request.upgrade then
        request:emit("data", chunk, len)
        return
      end

      -- Parse the chunk of HTTP, this will syncronously emit several of the
      -- above events and return how many chunks were parsed.
      local nparsed = parser:execute(chunk, 0, len)

      -- If it wasn't all parsed then there was an error parsing
      if nparsed < len then
        -- If the error was caused by non-http protocol like in websockets
        -- then that's ok, just emit the rest directly to the request object
        if request.upgrade then
          len = len - nparsed
          chunk = chunk:sub(nparsed + 1)
          request:emit("data", chunk, len)
        else
          request:emit("error", "parse error")
        end
      end

    end)

    client:on("end", function ()
      parser:finish()
    end)

  end)

  return server
end

return HTTP

