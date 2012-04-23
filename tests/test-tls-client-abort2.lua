require('helper')
local fixture = require('./fixture-tls')
local tls = require('tls')

local options = {
  cert = fixture.certPem,
  key = fixture.certKey,
  port = fixture.commonPort,
  host = '127.0.0.1'
}

local errors = 0

local conn = tls.connect(options, {}, function()
  assert(true)
end)

conn:on('error', function(err)
  p(err)
  errors = errors + 1
  doesnt_throw(function()
    conn:destroy()
  end)
end)

process:on('exit', function()
  assert(errors == 1)
end)
