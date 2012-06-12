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

local native = require('uv_native')
local constants = require('constants')
local Error = require('core').Error
local string = require('string')

local dns = {}

function dns.resolve4(domain, callback)
  native.dnsQueryA(domain, callback)
end

function dns.resolve6(domain, callback)
  native.dnsQueryAaaa(domain, callback)
end

function dns.resolveCname(domain, callback)
  native.dnsQueryCname(domain, callback)
end

function dns.resolveNs(domain, callback)
  native.dnsQueryNs(domain, callback)
end

function dns.resolveSrv(domain, callback)
  native.dnsQuerySrv(domain, callback)
end

function dns.resolveTxt(domain, callback)
  native.dnsQueryTxt(domain, callback)
end

function dns.resolveMx(domain, callback)
  native.dnsQueryMx(domain, callback)
end

function dns.reverse(ip, callback)
  native.dnsGetHostByAddr(ip, callback)
end

function dns.resolve(domain, rrtype, callback)
  if type(rrtype) == 'function' then
    callback = rrtype
    rrtype = 'A'
  end
  if rrtype == 'A' then dns.resolve4(domain, callback)
  elseif rrtype == 'AAAA' then dns.resolve6(domain, callback)
  elseif rrtype == 'MX' then dns.resolveMx(domain, callback)
  elseif rrtype == 'TXT' then dns.resolveTxt(domain, callback)
  elseif rrtype == 'SRV' then dns.resolveSrv(domain, callback)
  elseif rrtype == 'NS' then dns.resolveNs(domain, callback)
  elseif rrtype == 'CNAME' then dns.resolveCname(domain, callback)
  elseif rrtype == 'PTR' then dns.reverse(domain, callback)
  else callback(Error:new('Unknown Type ' .. rrtype)) end
end

function dns.lookup(domain, family, callback)
  local response_family = nil

  if type(family) == 'function' then
    callback = family
    family = nil
  end

  if family == nil then
    family = constants.AF_UNSPEC
  elseif family == 4 then
    family = constants.AF_INET
    response_family = 4
  elseif family == 6 then
    family = constants.AF_INET6
    response_family = 6
  else
    callback(Error:new('Unknown family type ' .. family))
    return
  end

  native.dnsGetAddrInfo(domain, family, function(err, addresses)
    if err then
      callback(err)
      return
    end
    if response_family then
      callback(nil, addresses[1], family)
    else
      callback(nil, addresses[1], string.find(addresses[1], ':') and 6 or 4)
    end
  end)
end

function dns.isIP(ip)
  print('dns.isIP is deprecated, use net.isIP')
  local net = require('net')
  return net.isIP(ip)
end

function dns.isIPv4(ip)
  print('dns.isIPv4 is deprecated, use net.isIPv4')
  local net = require('net')
  return net.isIPv4(ip)
end

function dns.isIPv6(ip)
  print('dns.isIPv6 is deprecated, use net.isIPv6')
  local net = require('net')
  return net.isIPv6(ip)
end

return dns
