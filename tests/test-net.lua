local net = require('net')

local PORT = 8080
local HOST = '127.0.0.1'

local server = net.createServer(function(client)
  client:on("data", function (chunk)
    client:write(chunk, function (err)
      assert(err == nil)
    end)
  end)

  client:on("end", function ()
    client:close(function ()
    end)
  end)

end)

server:listen(PORT, HOST, function(err)
  local client
  client = net.createConnection(PORT, HOST, function(err)
    if err then
      assert(err)
    end
    client:on('data', function(data)
      assert(#data == 5)
      assert(data == 'hello')
      client:close()
      server:close()
    end)

    client:write('hello')
  end)
end)

server:on("error", function (err)
  assert(err)
end)
