local net = require ("net")

local server = net.createServer(function(client)
  client:on("data", function(data)
    client:write(data)
  end)
end)

server:listen(1234, "127.0.0.1")
