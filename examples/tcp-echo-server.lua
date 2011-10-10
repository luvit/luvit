local TCP = require('tcp')

print("Creating a new TCP server")
local server = TCP.new()

print("Binding to 0.0.0.0 on port 8080")
server:bind("0.0.0.0", 8080)

print("Server listening")
server:listen(function (...)

  p("on_connection", ...)

  print("Creating new tcp client object")
  local client = TCP.new()
  
  print("Adding listener for data events")
  client:on("read", function (chunk, len)
    p("on_read", chunk, len)
    
    print("Sending chunk back to client")
    client:write(chunk, function ()
      p("on_written")
    end)

  end)
  
  print("Adding listener for close event")
  client:on("end", function ()
    p("on_end")
    
    print("Closing connection")
    client:close(function ()
      p("on_closed")
    end)
  end)
  
  print("Accepting the client")
  server:accept(client)
  
  print("Starting reads")
  client:read_start()

end)


