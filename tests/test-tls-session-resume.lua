local tls = require('tls')
local fixture = require('./fixture-tls')

--Server Side Inits
local serveroptions = {
  cert = fixture.certPem,
  key = fixture.keyPem
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
Server:listen(fixture.commonPort, function()
  connections.x = tls.connect({port = fixture.commonPort, host = '127.0.0.1'}, {}, function()
    connections.x:write('Zaphod')
    connections.x.transmit = true
    local context = connections.x.pair.credentials.context
    assert(context, 'Context does not exist for first connection')
    connections.x:destroy()
    connections.y = tls.connect({port = fixture.commonPort, host = '127.0.0.1', context = context},{}, function()
      connections.y:write('Beeblebrox')
      connections.y.transmit = true
      connections.y:destroy()
      Server:close(function()
        assert(found.x, 'Message 1 not received')
        assert(found.y, 'Message 2 not received')
        assert(connections.x.transmit, 'Message 1 not transmitted')
        assert(connections.y.transmit, 'Message 2 not transmitted')
      end)
    end)
  end)
end)

