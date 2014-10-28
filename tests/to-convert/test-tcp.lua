--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

require("helper")

local Tcp = require('uv').Tcp
local net = require('net')

local PORT = process.env.PORT or 10082

local server = net.createServer(function (client)
  client:on("data", function (chunk)
    p('server:client:on("data")', chunk)
    assert(chunk == "ping")

    client:write("pong", function (err)
      p("server:client:write")
      assert(err == nil)

      client:destroy()
    end)
  end)
end)

server:listen(PORT, "127.0.0.1")

server:on("error", function (err)
  p('server:on("error")')
  assert(false)
end)

local client = Tcp:new()
client:connect("127.0.0.1", PORT)

client:on("connect", function ()
  p('client:on("complete")')
  client:readStart()

  client:write("ping", function (err)
    p("client:write")
    assert(err == nil)

    client:on("data", function (data)
      p('client:on("data")', data)
      assert(data == "pong")

      client:close()

      -- This test is done, let's exit
      process.exit()
    end)
  end)
end)

client:on("error", function (err)
  p('client:on("error")', err)
  assert(false)
end)

