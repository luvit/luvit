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
local fs  = require('fs')

local PORT = 8081
local HOST = '127.0.0.1'
local server

server = net.createServer(function(client)
  client:on('finish', function()
    client:close()
    server:close()
  end)
end)

server:listen(PORT, HOST, function(err)
  local client
  client = net.createConnection(PORT, HOST, function(err)
    if err then
      assert(err)
    end

    fs.createReadStream(__dirname .. '/fixtures/test-pipe.txt'):pipe(client)
  end)
end)
