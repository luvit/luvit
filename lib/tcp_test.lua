local uv = require('uv')

print("Creating a new TCP server")
local server = uv.new_tcp()

print("Binding to 0.0.0.0 on port 8080")
server:bind("0.0.0.0", 8080)

print("Server listening")
server:listen(function (status)
  p("on_connection", status)
  print("Creating new tcp client object")
  local client = uv.new_tcp()
  
  print("Adding listener for data events")
  client:on("read", function (chunk, len)
    p("on_read", chunk, len)
    
    print("Sending chunk back to client")
    client:write(chunk, function ()
      p("on_written")
    end);

  end)
  
  print("Adding listener for close event")
  client:on("end", function ()
    p("on_end")
    
    print("Adding listener for closed event")
    client:on("closed", function ()
      p("on_closed")
    end)
    
    print("Closing connection")
    client:close()
  end)
  
  print("Accepting the client")
  server:accept(client)
  
  print("Starting reads")
  client:read_start()

end)


