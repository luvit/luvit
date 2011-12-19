local TCP = require('tcp')

local client = TCP.new()
client:connect("127.0.0.1", 8080)
client:on("complete", function ()
  print("Connected...")

  client:read_start()
  process.stdin:read_start()

  process.stdin:pipe(client)
  client:pipe(process.stdout)
end)

