local uv = require('uv')
local httpCodec = require('http-codec').server

-- Implement the app as a filter
-- Input is request objects
-- Output is response objects
local function app(write)
  return function (req)
    local body = "Hello Client\n"
    local res = {
      code = 200,
      headers = {
        {"Server", "Luvit"},
        {"Content-Length", #body},
        {"Content-Type", "text/plain"},
      }
    }
    p {
      req = req,
      res = res
    }
    -- Send the headers
    write(res)
    -- Send the body
    write(body)
    -- End the stream
    write()
  end
end

-- Hook the app to the TCP server with the httpCodec in the middle
local server = uv.new_tcp()
uv.tcp_bind(server, "127.0.0.1", 8080)
uv.listen(server, 128, function (_, err)
  assert(not err, err)
  local client = uv.new_tcp()
  uv.accept(server, client)
  uv.read_start(client, httpCodec(app)(function (chunk)
    uv.write(client, chunk)
  end))
end)
print("HTTP server listening at http://127.0.0.1:8080/")
