local net = require('net')

local server
server = net.createServer(function (client)

  -- Echo everything the client says back to itself
  client:pipe(client)

  -- Also log it to the server's stdout
  client:pipe(process.stdout)

end):listen(8080)

print("TCP echo server listening on port 8080")
