require('helper')
local fixture = require('./fixture-tls')
local childprocess = require('childprocess')
local tls = require('tls')

local options = {
  cert = fixture.certPem,
  key = fixture.keyPem,
  port = fixture.commonPort,
--  ciphers = 'NULL-MD5'
}

local reply = 'I AM'
local nconns = 0
local response = ''

--process:on('exit', function()
--  p('test' .. response)
--end)

local server = tls.createServer(options, function(conn)
  conn:write(reply)
  conn.socket:close()
  nconns = nconns + 1
end)

server:listen(fixture.commonPort, '127.0.0.1', function()
--  local cmd = {
--    's_client',
--    '-debug', '-cipher', 'NULL-MD5',
--    '-connect', '127.0.0.1:' .. fixture.commonPort
--  }
--  local child = childprocess.spawn('openssl', cmd, {})
--  child:on('error', function(err)
--    p(err)
--  end)
--  child:on('exit', function(exit_status)
--    p(response)
--     server:close()
--  end)
--  child.stderr:on('data', function(data)
--    p(data)
--  end)
--  child.stdout:on('data', function(data)
--    p(data)
--    response = response .. data
--  end)
end)

