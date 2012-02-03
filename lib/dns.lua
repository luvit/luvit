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

local uv = require('uv')
local constants = require('constants')
local Error = require('error')
local string = require('string')

local dns = {}

function dns.resolve4(domain, callback)
  uv.dnsQueryA(domain, callback)
end

function dns.resolve6(domain, callback)
  uv.dnsQueryAaaa(domain, callback)
end

function dns.resolveCname(domain, callback)
  uv.dnsQueryCname(domain, callback)
end

function dns.resolveNs(domain, callback)
  uv.dnsQueryNs(domain, callback)
end

function dns.resolveSrv(domain, callback)
  uv.dnsQuerySrv(domain, callback)
end

function dns.resolveTxt(domain, callback)
  uv.dnsQueryTxt(domain, callback)
end

function dns.resolveMx(domain, callback)
  uv.dnsQueryMx(domain, callback)
end

function dns.reverse(ip, callback)
  uv.dnsGetHostByAddr(ip, callback)
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

  uv.dnsGetAddrInfo(domain, family, function(err, addresses)
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

function dns.isIp(ip)
  return uv.dnsIsIp(ip)
end

function dns.isIpV4(ip)
  return uv.dnsIsIpV4(ip)
end

function dns.isIpV6(ip)
  return uv.dnsIsIpV6(ip)
end

return dns
