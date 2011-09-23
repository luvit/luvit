local uv = require('uv')

print("Creating a new TCP server")
local server = uv.new_tcp()

print("Binding to 0.0.0.0 on port 8080")
server:bind("0.0.0.0", 8080)

print("Listening for connections")
server:on("connection", function (status)
  p("on_connection", status)
  local client = uv.new_tcp()
  client:on("read", function (chunk)
    p("on_read", chunk)
  end)
  client:on("close", function ()
    p("on_close")
  end)
  server:accept(client)
  client:read_start()
end)
server:listen()

print("Starting the event loop")
uv.run()

print("Done!")
