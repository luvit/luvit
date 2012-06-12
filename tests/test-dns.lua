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

--]]

require("helper")

local dns = require('dns')
local net = require('net')

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

assert(net.isIP('127.0.0.1') == 4)
assert(net.isIP('::1') == 6)
assert(net.isIP('bogus_ip') == 0)
assert(net.isIPv4('127.0.0.1') == 4)
assert(net.isIPv4('::1') == 0)
assert(net.isIPv6('127.0.0.1') == 0)
assert(net.isIPv6('::1') == 6)

assert(dns.isIP('127.0.0.1') == 4)
assert(dns.isIP('::1') == 6)
assert(dns.isIP('bogus_ip') == 0)
assert(dns.isIPv4('127.0.0.1') == 4)
assert(dns.isIPv4('::1') == 0)
assert(dns.isIPv6('127.0.0.1') == 0)
assert(dns.isIPv6('::1') == 6)
