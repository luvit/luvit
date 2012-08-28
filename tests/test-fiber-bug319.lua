--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License")
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
local fiber = require("fiber")
local timer = require("timer")
local count = 0

fiber.new(function(wrap, wait)
  for i = 1, 10 do
		timer.setTimeout(100, function()
			count = count + 1
		end)
  end
end)

collectgarbage()

local net = require('net')
local PORT = process.env.PORT or 10082
local messages = {'a','b','c'}

fiber.new(function(wrap, wait)
  local server
  server = net.createServer(function(client)
    client:on("data", function(data)
      fiber.new(function(wrap, wait)
        for _, message in ipairs(messages) do
          wait(function(resume)
            client:write(message, function(err)
              timer.setTimeout(1, resume)
            end)
          end)
        end
        client:destroy()
        server:close()
      end)
    end)
  end)
  server:listen(PORT, "127.0.0.1")
  server:on("error", function(err)
    assert(false)
  end)
  wait(function(resume) process.nextTick(resume) end)
end)
collectgarbage()

local client = require("uv").Tcp:new()
client:connect("127.0.0.1", PORT)
client:on("connect", function()
  client:write("hi")
  local received = {} 
  client:on("data", function(data)
    received[#received+1] = data
    if data == "3:c" then
      client:close()
      assert(received[1] == messages[1])
      assert(received[2] == messages[2])
      assert(received[3] == messages[3])
    end
  end)
end)
client:on("error", function()
  assert(false)
end)

process:on('exit', function()
  assert(count == 10)
end)
