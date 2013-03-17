load('helper')
local fixture = load('./fixture-tls')
local tls = load('tls')

local options = {
  cert = fixture.certPem,
  key = fixture.certKey,
  port = fixture.commonPort,
  host = '127.0.0.1'
}

local conn = tls.connect(options, {}, function()
  assert(true)
end)

conn:on('error', function(err)
end)

doesnt_throw(function()
  conn:destroy()
end)
