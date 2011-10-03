local uv = require('uv')
local http_parser = require('http_parser')
local status_codes_table = {
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
  [418] = 'I\'m a teapot',              -- RFC 2324
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

-- Simple HTTP server
function create_server(on_connection)
  local socket = uv.new_tcp()
  local server = {}
  function server:listen(port, host)
    uv.tcp_bind(socket, host or "0.0.0.0", port)
    uv.listen(socket, function (status)
      local client = uv.new_tcp()
      uv.accept(socket, client)
      uv.read_start(client)
      
      local headers = {}
      local request = {
        socket = client,
        headers = headers,
        on = function (name, callback)
          uv.set_handler(client, name, callback)
        end
      }
      local response = {
        socket = client,
      }
      function response:write_head(code, headers)
        local head = "HTTP/1.1 " .. code .. " " .. status_codes_table[code] .. "\r\n"
        for field, value in pairs(headers) do
          head = head .. field .. ": " .. value .. "\r\n"
        end
        head = head .. "\r\n"

        uv.write(self.socket, head, function ()
--         print("HEAD written")
        end)
      end
      function response:write(chunk)
        uv.write(self.socket, chunk, function ()
--          print("CHUNK written")
        end)
      end
      function response:finish()
        uv.close(self.socket)
      end
      local current_field
      local parser
      parser = http_parser.new("request", {
        on_message_begin = function ()
--          print("on_message_begin")
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
--          print("on_body", utils.dump(chunk))
        end,
        on_message_complete = function ()
          parser:finish()
        end
      })
      
      uv.set_handler(client, "read", function (chunk, len)
        if len == 0 then 
          return
        end
        local nparsed = parser:execute(chunk, 0, len)
--        print("executed " .. nparsed .. " bytes")
        if nparsed < len then
          print("UH OH!")
        end
      end)
      
      uv.set_handler(client, "end", function ()
        parser:finish()
      end)

    end)
  end
  return server
end

-- Export the module
return {
  create_server = create_server
}
