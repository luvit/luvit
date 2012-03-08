local fixture = require('./fixture-tls')
local tls = require('tls')

local options = {
  cert = fixture.certPem,
  key = fixture.certKey,
  port = fixture.commonPort
}
local conn = tls.connect(options, function()
  assert(true)
end)
conn:on('error', function()
end)
conn:destroy()
