local uv = require('uv')

print("Creating a new TCP server")
local server = uv.new_tcp()

print("Binding to 0.0.0.0 on port 8080")
uv.tcp_bind(server, "0.0.0.0", 8080)

print("Server listening")
uv.listen(server, function (status)
  p("on_connection", status)
  print("Creating new tcp client object")
  local client = uv.new_tcp()
  
  print("Adding listener for data events")
  uv.set_handler(client, "read", function (chunk, len)
    p("on_read", chunk, len)
    
    print("Sending chunk back to client")
    uv.write(client, chunk, function ()
      p("on_written")
    end);

  end)
  
  print("Adding listener for close event")
  uv.set_handler(client, "end", function ()
    p("on_end")
    
    print("Adding listener for closed event")
    uv.set_handler(client, "closed", function ()
      p("on_closed")
    end)
    
    print("Closing connection")
    uv.close(client)
  end)
  
  print("Accepting the client")
  uv.accept(server, client)
  
  print("Starting reads")
  uv.read_start(client)

end)


