local TCP = require('tcp')

local PORT = 8080

local server = TCP.create_server("127.0.0.1", PORT, function (client)
  client:on("data", function (chunk)
    p('server:client:on("data")', chunk)
    assert(chunk == "ping")

    client:write("pong", function (err)
      p("server:client:write")
      assert(err == nil)

      client:close()
    end)
  end)
end)

server:on("error", function (err)
  p('server:on("error")')
  assert(false)
end)

local client = TCP.new()
client:connect("127.0.0.1", PORT)

client:on("complete", function ()
  p('client:on("complete")')
  client:read_start()

  client:write("ping", function (err)
    p("client:write")
    assert(err == nil)

    client:on("data", function (data)
      p('client:on("data")', data)
      assert(data == "pong")

      client:close()
      server:close()
      -- `server:close()` is needed only in this test case, to ensure that
      -- process exits after it's done.
    end)
  end)
end)

client:on("error", function (err)
  p('client:on("error")', err)
  assert(false)
end)

