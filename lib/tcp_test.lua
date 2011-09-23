local uv = require('uv')

print("Creating a new TCP server")
local server = uv.new_tcp()

print("Binding to 0.0.0.0 on port 8080")
server:bind("0.0.0.0", 8080)

print("Listening for connections")
server:listen(128, function (num)
  print("on_connection", num)
end)

print("Starting the event loop")
uv.run()

print("Done!")
