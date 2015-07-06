
require('tap')(function (test)
  local fixture = require('./fixture-tls')
  local tls = require('tls')
  local timer = require('timer')
  local options = {
    cert = fixture.certPem,
    key = fixture.keyPem
  }

  local serverConnected = 0
  local clientConnected = 0

  local server
  local client1, client2
  local session1,session2
  local conns={}
  test("tls connect session reuse test", function()
    server = tls.createServer(options, function(conn)
      serverConnected = serverConnected + 1
      p('server accepted',serverConnected)
      conns[serverConnected] = conn
      if (serverConnected == 2) then
        timer.setTimeout(1000,function()
          server:close()
          p('server closed')
          assert(session1:id()==session2:id())
          conns[1]:destroy()
          conns[2]:destroy()
          client1:destroy()
          client2:destroy()
        end)
      end
    end)

    server:listen(fixture.commonPort, function()
      p('server listening at:',fixture.commonPort)

      local options = {
        port = fixture.commonPort,
        host = '127.0.0.1',
        rejectUnauthorized=false
      }

      options.secureContext = tls.createCredentials(options)
      local calltwo
      client1 = tls.connect(options)
      client1:on('secureConnection', function()
        session1 = client1.ssl:session()
        assert(client1.ssl:session_reused()==false)
        p('client connected')
        clientConnected = clientConnected + 1
        session1 = client1.ctx.session
        timer.setTimeout(500,calltwo)
      end)

      client1:on('error', function(err)
        p(err)
        client1:destroy()
      end)
      client1:on('end', function()
        p('client end')
      end)

      calltwo = function()
        client2 = tls.connect(options)
        client2:on('secureConnection', function()
          session2 = client2.ssl:session()
          assert(client2.ssl:session_reused()==true)
          p('client2 connected')
          clientConnected = clientConnected + 1
        end)
        client2:on('error', function(err)
          p(err)
          client2:destroy()
        end)
        client2:on('end', function()
          p('client end')
        end)
      end
      --]]
    end)
  end)
end)
