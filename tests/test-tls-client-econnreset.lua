require('tap')(function (test)
  local fixture = require('./fixture-tls')
  local childprocess = require('childprocess')
  local los = require('los')
  local tls = require('tls')
  local timer = require('timer')
  local uv = require('uv')

  local args = {
    's_server',
    '-accept', fixture.commonPort,
    '-key', 'tests/fixtures/keys/agent1-key.pem',
    '-cert', 'tests/fixtures/keys/agent1-cert.pem',
  }

  test("tls client econnreset", function()
    if los.type() == 'win32' then return end
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

    timer.setTimeout(200,function ()
      local c = tls.connect({port = fixture.commonPort, host = '127.0.0.1'})
      c:on('error', function(err)
        print("got connection error")
      end)
      c:on('close', function()
        print('got close signal')
      end)
      c:on('data', function(data)
        print('client got: ' .. data)
      end)
      c:on('end', function()
        c:destroy()
      end)
    end)

    timer.setTimeout(1000, function()
      child:kill()
    end)
  end)
end)
