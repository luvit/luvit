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

dns.reverse('8.8.8.8', function(err, addresses)
  assert(type(err) == 'nil')
  assert(type(addresses) == 'table')
  for i=1,#addresses do
    assert(type(addresses[i]) == 'string')
  end
end)

dns.reverse('2001:4860:4860::8888', function(err, addresses)
  assert(type(err) == 'nil')
  assert(type(addresses) == 'table')
  for i=1,#addresses do
    assert(type(addresses[i]) == 'string')
  end
end)

dns.reverse('bogus ip', function(err, addresses)
  assert(type(err) ~= 'nil')
  assert(type(addresses) == 'nil')
end)

dns.resolveMx('gmail.com', function(err, addresses)
  assert(type(err) == 'nil')
  assert(type(addresses) == 'table')
  for i=1,#addresses do
    assert(addresses[i].priority)
    assert(addresses[i].exchange)
  end
end)

dns.resolveNs('rackspace.com', function(err, addresses)
  assert(type(err) == 'nil')
  assert(type(addresses) == 'table')
  for i=1,#addresses do
    assert(type(addresses[i]) == 'string')
  end
end)

dns.resolveSrv('_jabber._tcp.google.com', function(err, addresses)
  assert(type(err) == 'nil')
  assert(type(addresses) == 'table')
  for i=1,#addresses do
    assert(type(addresses[i].name) == 'string')
    assert(type(addresses[i].port) == 'number')
    assert(type(addresses[i].priority) == 'number')
    assert(type(addresses[i].weight) == 'number')
  end
end)

dns.resolveCname('www.google.com', function(err, names)
  assert(type(err) == 'nil')
  assert(type(names) == 'table')
  assert(#names == 1)
end)

dns.resolveTxt('google.com', function(err, records)
  assert(type(err) == 'nil')
  assert(type(records) == 'table')
  for i=1,#records do
    assert(type(records[i]) == 'string')
  end
end)

dns.lookup('::1', function(err, ip, family)
  assert(type(err) == 'nil')
  assert(type(ip) == 'string')
  assert(type(family) == 'number')
end)

assert(dns.isIP('127.0.0.1') == 4)
assert(dns.isIP('::1') == 6)
assert(dns.isIPv4('127.0.0.1') == 4)
assert(dns.isIPv4('::1') == 0)
assert(dns.isIPv6('127.0.0.1') == 0)
assert(dns.isIPv6('::1') == 6)
