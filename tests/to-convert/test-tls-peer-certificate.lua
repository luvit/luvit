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
  key = fixture.loadFile('agent.key'),
  cert = fixture.loadFile('alice.crt')
}

local verified = false

local server
server = tls.createServer(options, function(cleartext)
  cleartext:write('world')
  cleartext:destroy()
end)

server:listen(fixture.commonPort, function()
  local socket
  socket = tls.connect({host = '127.0.0.1', port = fixture.commonPort}, function()
    local peercert = socket:getPeerCertificate()
    assert(peercert.subject.subjectAltName == 'uniformResourceIdentifier:http://localhost:8000/alice.foaf#me')
    verified = true
    socket:write('Hello')
    socket:destroy()
    server:close()
  end)
end)

process:on('exit', function()
  assert(verified == true)
end)
