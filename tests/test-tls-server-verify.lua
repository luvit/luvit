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

if require('os').type() == 'win32' then
  return
end

--[[
 This is a rather complex test which sets up various TLS servers with node
 and connects to them using the 'openssl s_client' command line utility
 with various keys. Depending on the certificate authority and other
 parameters given to the server, the various clients are
 - rejected,
 - accepted and "unauthorized", or
 - accepted and "authorized".
]]--

local testCases = {
  {
    title = 'Do not request certs. Everyone is unauthorized.',
    requestCert = false,
    rejectUnauthorized = false,
    CAs = {'ca1-cert'},
    clients = {
      { name = 'agent1', shouldReject = false, shouldAuth = false },
      { name = 'agent2', shouldReject = false, shouldAuth = false },
      { name = 'agent3', shouldReject = false, shouldAuth = false },
      { name = 'nocert', shouldReject = false, shouldAuth = false }
    }
  },
  {
    title = 'Allow both authed and unauthed connections with CA1',
    requestCert = true,
    rejectUnauthorized = false,
    CAs = {'ca1-cert'},
    clients = {
      { name = 'agent1', shouldReject = false, shouldAuth = true },
      { name = 'agent2', shouldReject = false, shouldAuth = false },
      { name = 'agent3', shouldReject = false, shouldAuth = false },
      { name = 'nocert', shouldReject = false, shouldAuth = false }
    },
    {
      title = 'Allow only authed connections with CA1',
      requestCert = true,
      rejectUnauthorized = true,
      CAs = {'ca1-cert'},
      clients = {
        { name = 'agent1', shouldReject = false, shouldAuth = true },
        { name = 'agent2', shouldReject = true },
        { name = 'agent3', shouldReject = true },
        { name = 'nocert', shouldReject = true }
      }
    }
  },
  {
    title = 'Allow only authed connections with CA1 and CA2',
    requestCert = true,
    rejectUnauthorized = true,
    CAs = {'ca1-cert', 'ca2-cert'},
    clients = {
      { name = 'agent1', shouldReject = false, shouldAuth = true },
      { name = 'agent2', shouldReject = true },
      { name = 'agent3', shouldReject = false, shouldAuth = true },
      { name = 'nocert', shouldReject = true }
    }
  },
  {
    title = 'Allow only certs signed by CA2 but not in the CRL',
    requestCert = true,
    rejectUnauthorized = true,
    CAs = {'ca2-cert'},
    crl = {'ca2-crl'},
    clients = {
      { name = 'agent1', shouldReject = true, shouldAuth = false },
      { name = 'agent2', shouldReject = true, shouldAuth = false },
      { name = 'agent3', shouldReject = false, shouldAuth = true },
      { name = 'agent4', shouldReject = true, shouldAuth = false },
      { name = 'nocert', shouldReject = true }
    }
  }
}

local serverKey = fixture.loadPEM('agent2-key');
local serverCert = fixture.loadPEM('agent2-cert');

function runClient(options, callback)
  local args = { 's_client', '-connect', '127.0.0.1:' .. fixture.commonPort}
  print('  connecting with ' .. options.name)

  if options.name == 'agent1' then
    -- signed by CA1
    table.insert(args, '-key')
    table.insert(args, fixture.filenamePEM('agent1-key'))
    table.insert(args, '-cert')
    table.insert(args, fixture.filenamePEM('agent1-cert'))
  elseif options.name == 'agent2' then
    -- self-signed
    table.insert(args, '-key')
    table.insert(args, fixture.filenamePEM('agent2-key'))
    table.insert(args, '-cert')
    table.insert(args, fixture.filenamePEM('agent2-cert'))
  elseif options.name == 'agent3' then
    -- signed by CA2
    table.insert(args, '-key')
    table.insert(args, fixture.filenamePEM('agent3-key'))
    table.insert(args, '-cert')
    table.insert(args, fixture.filenamePEM('agent3-cert'))
  elseif options.name == 'agent4' then
    table.insert(args, '-key')
    table.insert(args, fixture.filenamePEM('agent4-key'))
    table.insert(args, '-cert')
    table.insert(args, fixture.filenamePEM('agent4-cert'))
  elseif options.name == 'nocert' then
  else
    error('Unknown agent name')
  end

  local rejected = true
  local authed = false
  local out = ''
  local child = childprocess.spawn('openssl', args)
  child.stdout:on('data', function(chunk)
    out = out .. chunk
    if out:find('_unauthed') then
      print('  * unauthed')
      authed = false
      rejected = false
      child.stdin:write('goodbye\n')
    end
    if out:find('_authed') then
      print('  * authed')
      authed = true
      rejected = false
      child.stdin:write('goodbye\n')
    end
  end)
  child:on('exit', function(exit_status, term_signal)
    if options.shouldReject == true then
      assert(rejected == true, options.name .. ' NOT rejected, but should have been')
    else
      assert(rejected == false, options.name .. ' rejected, but should NOT have been')
      assert(options.shouldAuth == authed)
    end
    callback()
  end)
end

local successfulTests = 0
function runTest(testIndex, done)
  local tcase = testCases[testIndex]
  local cas = {}
  local crl = {}

  if not tcase then 
    done()
    return 
  end

  -- load CAs
  for _, v in pairs(tcase.CAs) do
    cas[v] = fixture.loadPEM(v)
  end

  -- load CRLs
  if tcase.crl then
    for _, v in pairs(tcase.crl) do
      crl[v] = fixture.loadPEM(v)
    end
  else
    crl = nil
  end

  -- setup options
  local serverOptions = {
    key = serverKey,
    cert = serverCert,
    ca = cas,
    crl = crl,
    requestCert = tcase.requestCert,
    rejectUnauthorized = tcase.rejectUnauthorized
  }

  local connections = 0
  local server

  function runNextClient(clientIndex)
    local options = tcase.clients[clientIndex]
    if options then
      runClient(options, function()
        runNextClient(clientIndex + 1)
      end)
    else
      server:close()
      successfulTests = successfulTests + 1
      runTest(testIndex + 1, done)
    end
  end

  server = tls.createServer(serverOptions, function(c)
    connections = connections + 1
    if c.authorized == true then
      print('- authed connection: ' .. c:getPeerCertificate().subject.CN)
      c:write('\n_authed\n')
    else
      print('- unauthed connection: ' .. (c.authorizationError or 'undefined'))
      c:write('\n_unauthed\n')
    end
    c:on('data', function(chunk)
      if chunk:find('goodbye') then
        c:destroy()
      end
    end)
  end)

  server:listen(fixture.commonPort, function()
    runNextClient(1)
  end)
end

runTest(1, function()
  assert(#testCases == successfulTests)
end)
