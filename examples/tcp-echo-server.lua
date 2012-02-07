local net = require('net')

local server = net.createServer(function (client)
  p("on_connection", client)

  print("Adding listener for data events")
  client:on("data", function (chunk)
    p("on_read", chunk)

    print("Sending chunk back to client")
    client:write(chunk, function (err)
      p("on_written", err)
    end)

  end)

  print("Adding listener for close event")
  client:on('finish', function ()
    p("on_end")

    print("Closing connection")
    client:close(function ()
      p("on_closed")
    end)
  end)

end)

server:listen(8080, '0.0.0.0', function(err)
  print("TCP echo server listening on port 8080")
end)

print("Listening for errors in the server")
server:on("error", function (err)
  p("ERROR", err)
end)
