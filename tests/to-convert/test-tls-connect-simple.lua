require('helper')
local fixture = require('./fixture-tls')
local tls = require('tls')

local options = {
  cert = fixture.certPem,
  key = fixture.keyPem
}

local serverConnected = 0
local clientConnected = 0

local server
server = tls.createServer(options, function(conn)
  serverConnected = serverConnected + 1
  if (serverConnected == 2) then
    server:close()
  end
end)

server:listen(fixture.commonPort, function()
  local client1, client2
  client1 = tls.connect({port = fixture.commonPort, host = '127.0.0.1'}, {}, function()
    clientConnected = clientConnected + 1
    client1:destroy()
  end)

  client2 = tls.connect({port = fixture.commonPort, host = '127.0.0.1'}, {}, function()
    clientConnected = clientConnected + 1
    client2:destroy()
  end)
end)

process:on('exit', function()
  assert(serverConnected == 2)
  assert(clientConnected == 2)
end)
