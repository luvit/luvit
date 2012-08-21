require('helper')
local fixture = require('./fixture-tls')
local childprocess = require('childprocess')
local os = require('os')
local tls = require('tls')
local timer = require('timer')

local args = {
  's_server',
  '-accept', fixture.commonPort,
  '-key', 'fixtures/keys/agent1-key.pem',
  '-cert', 'fixtures/keys/agent1-cert.pem',
}

local child = childprocess.spawn('openssl', args)
child:on('error', function(err)
  p(err)
end)
child:on('exit', function(exit_status)
  print('server exited')
end)
child:on('error', function(err)
  p(err)
end)
child.stdout:on('data', function(data)
  print('server: ' .. data)
end)
child.stderr:on('data', function(data)
  print('server: ' .. data)
end)

interval = timer.setInterval(100, function()
  local success, err = pcall(child.stdin.write, child.stdin, "Hello world")
end)

timer.setTimeout(200,function ()
  local c
  c = tls.connect({port = fixture.commonPort, host = '127.0.0.1'})
  c:on('error', function(err)
    print("got connection error")
    p(err)
  end)
  c:on('closed', function()
    print('got closed signal')
  end)
  c:on('data', function(data)
    print('client got: ' .. data)
  end)
  c:on('end', function()
    c:destroy()
  end)
end)

timer.setTimeout(1000, function()
  child:kill(9)
end)

timer.setTimeout(1010, function()
  process.exit(0)
end)

process:on('error', function(err)
  assert(false)
  p(err)
end)
