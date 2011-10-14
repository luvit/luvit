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
        on_connection(request, response)
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
      if len == 0 then return end
      local nparsed = parser:execute(chunk, 0, len)
      if nparsed < len then
        request:emit("error", "parse error")
      end
    end)

    client:on("end", function ()
      parser:finish()
    end)

  end)
  
  return server
end

return HTTP

