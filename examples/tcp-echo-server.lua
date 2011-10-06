local UV = require('uv')

print("Creating a new TCP server")
local server = UV.new_tcp()

print("Binding to 0.0.0.0 on port 8080")
UV.tcp_bind(server, "0.0.0.0", 8080)

print("Server listening")
UV.listen(server, function (status)
  p("on_connection", status)
  print("Creating new tcp client object")
  local client = UV.new_tcp()
  
  print("Adding listener for data events")
  UV.set_handler(client, "read", function (chunk, len)
    p("on_read", chunk, len)
    
    print("Sending chunk back to client")
    UV.write(client, chunk, function ()
      p("on_written")
    end);

  end)
  
  print("Adding listener for close event")
  UV.set_handler(client, "end", function ()
    p("on_end")
    
    print("Adding listener for closed event")
    UV.set_handler(client, "closed", function ()
      p("on_closed")
    end)
    
    print("Closing connection")
    UV.close(client)
  end)
  
  print("Accepting the client")
  UV.accept(server, client)
  
  print("Starting reads")
  UV.read_start(client)

end)


