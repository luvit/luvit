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

dns.reverse('173.203.44.122', function(err, domains)
  assert(type(err) == 'nil')
  p(domains)
end)
