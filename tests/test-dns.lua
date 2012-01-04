require("helper")

local dns = require('dns')

dns.resolve4('www.google.com', function(err, addresses)
  assert(type(err) == 'nil')
  assert(type(addresses) == 'table')
  assert(#addresses > 0)
end)

dns.resolve6('ipv6.google.com', function(err, addresses)
  assert(type(err) == 'nil')
  assert(type(addresses) == 'table')
  assert(#addresses > 0)
end)

dns.lookup('google.com', function(err, addresses)
  assert(type(err) == 'nil')
  assert(type(addresses) == 'string')
end)
