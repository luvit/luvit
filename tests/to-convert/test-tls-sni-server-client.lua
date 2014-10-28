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
local fs = require('fs')
local childprocess = require('childprocess')
local table = require('table')
local tls = require('tls')

local options = {
  key = fixture.loadPEM('agent2-key'),
  cert = fixture.loadPEM('agent2-cert')
}

local SNIContexts = {}
SNIContexts['a.example.com'] = {
  key = fixture.loadPEM('agent1-key'),
  cert = fixture.loadPEM('agent1-cert')
}
SNIContexts['asterisk.test.com'] = {
  key = fixture.loadPEM('agent3-key'),
  cert = fixture.loadPEM('agent3-cert')
}

local clientsOptions = {
  {
    port = fixture.commonPort,
    key = fixture.loadPEM('agent1-key'),
    cert = fixture.loadPEM('agent1-cert'),
    ca = fixture.loadPEM('ca1-cert'),
    servername = 'a.example.com'
  },{
    port = fixture.commonPort,
    key = fixture.loadPEM('agent2-key'),
    cert = fixture.loadPEM('agent2-cert'),
    ca = fixture.loadPEM('ca2-cert'),
    servername = 'b.test.com'
  },{
    port = fixture.commonPort,
    key = fixture.loadPEM('agent3-key'),
    cert = fixture.loadPEM('agent3-cert'),
    ca = fixture.loadPEM('ca1-cert'),
    servername = 'c.wrong.com'
  }
}

local serverResults = {}
local clientResults = {}

local server
server = tls.createServer(options)
server:on('secureConnection', function(conn)
  table.insert(serverResults, conn.serverName)
end)

function connectClient(options, callback)
  local client
  options.host = '127.0.0.1'
  client = tls.connect(options, function()
    table.insert(clientResults, client.authorized)
    client:destroy()
    callback()
  end)
end

server:addContext('a.example.com', SNIContexts['a.example.com'])
server:addContext('b.test.com', SNIContexts['asterisk.test.com']);
server:listen(fixture.commonPort, '127.0.0.1', function()
  connectClient(clientsOptions[1], function()
    connectClient(clientsOptions[2], function()
      connectClient(clientsOptions[3], function()
        server:close()
      end)
    end)
  end)
end)

process:on('exit', function()
  deep_equal(serverResults, {'a.example.com', 'b.test.com', 'c.wrong.com'})
  deep_equal(clientResults, {true, true, false})
end)
