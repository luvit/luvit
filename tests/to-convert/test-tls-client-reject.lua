require('helper')
local fixture = require('./fixture-tls')
local tls = require('tls')

local options = {
  cert = fixture.certPem,
  key = fixture.keyPem
}
local client_options = {
  port = fixture.commonPort,
  host = '127.0.0.1'
}
p(options)

local connectCount = 0

local server
server = tls.createServer(options, function(socket)
  connectCount = connectCount + 1
  p(connectCount)
  socket:on('data', function(data)
    print(data)
    assert(data == 'ok')
  end)
end)

server:on('clientError', function(err)
  print('got client error!')
  p(err)
  assert(false)
end)

local authorized = function()
  local socket
  local options = {
    host = '127.0.0.1',
    rejectUnauthorized = true,
    ca = fixture.caPem,
  }

  socket = tls.connect(fixture.commonPort, options, function()
    print("authorized() OK")
    assert(socket.authorized == true)
    socket:destroy()
    server:close()
  end)

  socket:on('error', function(err)
    print("authorized() error!\n")
    print(err)
    assert(false)
  end)
  socket:write('ok')
end

local rejectUnauthorized = function()
  local socket
  socket = tls.connect(fixture.commonPort, {
    rejectUnauthorized = true,
    host = '127.0.0.1'
  }, function()
    assert(false)
  end)

  socket:on('error', function(err)
    assert(err == 'DEPTH_ZERO_SELF_SIGNED_CERT')
    print('rejectUnauthorized() finished, now authorized()')
    authorized()
  end)

  socket:write('ng')
end

local unauthorized = function()
  local socket
  socket = tls.connect(fixture.commonPort, { host = '127.0.0.1' }, function()
    assert(socket.authorized == false)
    socket:destroy()
    print('unauthorized() finished, now rejectUnauthorized()')
    rejectUnauthorized()
  end)

  socket:on('error', function(err)
    print(err)
    assert(false)
  end)

  socket:write('ok')
end

server:listen(fixture.commonPort, function()
  unauthorized()
end)

process:on('exit', function()
  assert(connectCount == 3)
end)
