local uv = require('uv')
local httpCodec = require('http-codec').server

-- Implement the app as a filter
-- Input is request objects
-- Output is response objects
local function app(write)
  return function (req)
    -- print(req.method, req.path)
    if req.method == 'GET' and req.path == '/' then
      local body = "Hello Client\n"
      -- Send the headers
      write({
        code = 200,
        headers = {
          {"Server", "Luvit"},
          {"Content-Length", #body},
          {"Content-Type", "text/plain"},
        }
      })
      -- Send the body
      write(body)
      -- Close the connection
      write()
    else
      write({
        code = 404,
        headers = {
          {"Server", "Luvit"},
          {"Content-Length", 0}
        }
      })
      write()
    end
  end
end

-- Hook the app to the TCP server with the httpCodec in the middle
local server = uv.new_tcp()
uv.tcp_bind(server, "127.0.0.1", 8080)
uv.listen(server, 128, function (_, err)
  assert(not err, err)
  local client = uv.new_tcp()
  uv.accept(server, client)
  local process = httpCodec(app)(function (chunk)
    if chunk then
      uv.write(client, chunk)
    else
      uv.close(client)
    end
  end)
  uv.read_start(client, function (_, _, chunk)
    if not chunk then
      uv.close(client)
    else
      return process(chunk)
    end
  end)
end)
print("HTTP server listening at http://127.0.0.1:8080/")
