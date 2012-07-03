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
  local function test_keepalive(on_done)    -- test :keepalive(enable, delay)
    local client
    client = net.createConnection(PORT, HOST, function(err)
      client:keepalive(true, 10)
      if err then
        assert(err)
      end
      client:on('data', function(data)
        assert(#data == 5)
        assert(data == 'hello')
        client:destroy()
        if on_done then on_done() end
      end)

      client:write('hello')
    end)
  end

  local function test_nodelay(on_done)    -- test :nodelay(enable) function
    local client
    client = net.createConnection(PORT, HOST, function(err)
      client:nodelay(true)
      if err then
        assert(err)
      end
      client:on('data', function(data)
        assert(#data == 5)
        assert(data == 'hello')
        client:destroy()
        if on_done then on_done() end
      end)

      client:write('hello')
    end)
  end

  local client
  client = net.createConnection(PORT, HOST, function(err)
    if err then
      assert(err)
    end
    client:on('data', function(data)
      assert(#data == 5)
      assert(data == 'hello')
      client:destroy()
      test_nodelay(function()
		test_keepalive(function()
		  server:close()
		end)
      end)
    end)

    client:write('hello')
  end)
end)

server:on("error", function(err)
  assert(err)
end)
