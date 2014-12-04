local uv = require("uv")

-- Create listening socket and bind to 127.0.0.1:8080
local server = uv.new_tcp()
uv.tcp_bind(server, "127.0.0.1", 8080)

-- Setup listener
uv.listen(server, 128, function(error)
  -- This function is executed for each new client
  print("New connection")

  -- Create handles for client and upstream
  local client = uv.new_tcp()
  local upstream = uv.new_tcp()

  -- Accept the client connection
  uv.accept(server, client)

  -- Connect to upstream server
  uv.tcp_connect(upstream, "127.0.0.1", 80, function(error)
    -- Setup handler to send data from upstream to client
    uv.read_start(upstream, function(err, data)
      if err then print("Upstream error:" .. err) end
      if data then
        print("Upstream response: " .. data)
        uv.write(client, data)
      else
        print("Upstream disconnected")
      end
    end)

    -- Setup handler to send data from client to upstream
    uv.read_start(client, function(err, data)
      if err then print("Client error:" .. err) end
      if data then
        print("Client request: " .. data)
        uv.write(upstream, data)
      else
        print("Client disconnected")
      end
    end)
  end)
end)

-- Notify that the proxy is ready
print("Listening on 127.0.0.1:8080, proxying to 127.0.0.1:80")
