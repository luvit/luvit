require('helper')
local fixture = require('./fixture-tls')
local childprocess = require('childprocess')
local os = require('os')
local tls = require('tls')

local options = {
  cert = fixture.certPem,
  key = fixture.keyPem,
  port = fixture.commonPort,
  ciphers = 'NULL-MD5'
}

local reply = 'I AM THE WALRUS'
local nconns = 0
local response = ''

local server = tls.createServer(options, function(conn)
  conn:write(reply)
  conn.socket:destroy()
  nconns = nconns + 1
end)
server:listen(fixture.commonPort, '127.0.0.1', function()
  local args = {
    's_client',
    '-cipher', 'NULL-MD5',
    '-connect', '127.0.0.1:' .. fixture.commonPort
  }
  local child = childprocess.spawn('openssl', args)
  child:on('error', function(err)
    p(err)
  end)
  child:on('exit', function(exit_status)
    assert(nconns == 1)
    assert(response:find(reply) ~= -1)
    server:close()
  end)
  child.stdout:on('data', function(data)
    response = response .. data
  end)
end)

