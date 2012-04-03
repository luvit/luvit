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
      client:destroy()
    end)
  end)
end)

server:listen(PORT, HOST, function(err)
  local client
  local receivedMessage = false
  local msg= 'hello world'
  client = net.Socket:new()
  client:connect(PORT, HOST)
  client:write(msg)
  client:on('data', function(data)
    receivedMessage = true
    server:close()
    assert(data == msg)
  end)
  client:on('end', function()
    assert(receivedMessage == true)
    client:destroy()
  end)
  client:on('error', function(err)
    assert(err)
  end)
end)

server:on("error", function(err)
  assert(err)
end)
