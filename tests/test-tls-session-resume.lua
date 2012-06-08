local tls = require('tls')

--Server Side Inits
local serveroptions = {
  cert = certPem,
  key = keyPem
}

local found = {}
local Server = tls.createServer(serveroptions, function(listener)
  listener:on('data', function(data)
    local received = tostring(data)
    if received:find('Zaphod') then
      found.x = true
    elseif received:find('Beeblebrox') then
      found.y = true
    end
  end)  
end)
  
--Client Side Inits
local connections = {}
  
--Server Listens, Client Connects, Disconnects, and Reconnects
Server:listen(4000, function()
  connections.x = tls.connect({port = 4000, host = '127.0.0.1'}, {}, function()
    connections.x:write('Zaphod')
    connections.x.transmit = true
    local context = connections.x.pair.credentials.context
    asserts.ok(context)
    connections.x:destroy()
    connections.y = tls.connect({port = 4000, host = '127.0.0.1', context = context},{}, function()
      connections.y:write('Beeblebrox')
      connections.y.transmit = true
      connections.y:destroy()
      Server:close(function()
        asserts.ok(found.x)
        asserts.ok(found.y)
        asserts.ok(connections.x.transmit)
        asserts.ok(connections.y.transmit)
      end)
    end)
  end)
end)

