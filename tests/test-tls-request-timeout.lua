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
]]--
require('helper')
local fixture = require('./fixture-tls')
local tls = require('tls')

local options = {
  key = fixture.loadPEM('agent1-key'),
  cert = fixture.loadPEM('agent1-cert')
}

local hadTimeout = false
local server
server = tls.createServer(options, function(socket)
  socket:on('timeout', function(err)
    hadTimeout = true
    socket:destroy()
    server:close()
  end)
  socket:setTimeout(100)
end)

server:listen(fixture.commonPort, function()
  local socket = tls.connect({host = '127.0.0.1', port = fixture.commonPort})
  socket:on('end', function()
    socket:destroy()
    assert(hadTimeout == true)
  end)
end)
