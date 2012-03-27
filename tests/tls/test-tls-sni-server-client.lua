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

function filenamePEM(n)
  return require('path').join(__dirname, '..', 'fixtures', 'keys', n .. '.pem')
end

function loadPEM(n)
  return fs.readFileSync(filenamePEM(n))
end

local options = {
  key = loadPEM('agent2-key'),
  cert = loadPEM('agent2-cert')
}

local SNIContexts = {}
SNIContexts['a.example.com'] = {
  key = loadPEM('agent1-key'),
  cert = loadPEM('agent1-cert')
}
SNIContexts['asterisk.test.com'] = {
  key = loadPEM('agent3-key'),
  cert = loadPEM('agent3-cert')
}

local clientsOptions = {
  {
    port = fixture.commonPort,
    key = loadPEM('agent1-key'),
    cert = loadPEM('agent1-cert'),
    ca = loadPEM('ca1-cert'),
    servername = 'a.example.com'
  },{
    port = fixture.commonPort,
    key = loadPEM('agent2-key'),
    cert = loadPEM('agent2-cert'),
    ca = loadPEM('ca2-cert'),
    servername = 'b.test.com'
  },{
    port = fixture.commonPort,
    key = loadPEM('agent3-key'),
    cert = loadPEM('agent3-cert'),
    ca = loadPEM('ca1-cert'),
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

server:addContext('a.example.com', SNIContexts['a.example.com'])
server:addContext('b.test.com', SNIContexts['asterisk.test.com']);
server:listen(fixture.commonPort, '127.0.0.1')

function connectClient(options, callback)
  local client
  client = tls.connect(options, function()
    table.insert(clientResults, client.authorized)
    client:close()
    callback()
  end)
end

connectClient(clientsOptions[1], function()
  connectClient(clientsOptions[2], function()
    connectClient(clientsOptions[3], function()
      server:close()
      deep_equal(serverResults, {'a.example.com', 'b.test.com', 'c.wrong.com'})
      deep_equal(clientResults, {true, true, false})
    end)
  end)
end)
