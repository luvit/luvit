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
local net = require('net')

local PORT = process.env.PORT or 10081
local HOST = '127.0.0.1'

local server = net.createServer(function(client)
  client:on("data", function (chunk)
    client:write(chunk, function(err)
      assert(err == nil)
    end)
  end)

  client:on("end", function()
    client:destroy()
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

      client:destroy()
      -- Ensure double destroy doesn't return an error
      client:destroy()

      server:close()
      -- Ensure double close returns an error
      local success, err = pcall(server.close, server)
      assert(success == false)
      assert(err)
    end)

    client:write('hello')
  end)
end)

server:on("error", function(err)
  assert(err)
end)
