local net = require('net')

local client
client = net.createConnection(8080, '127.0.0.1', function(err)
  if err then
    p(err)
    return
  end

  print("Connected...")

  process.stdin:read_start()

  process.stdin:pipe(client)
  client:pipe(process.stdout)
end)

