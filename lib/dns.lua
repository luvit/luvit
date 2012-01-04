local UV = require('uv')
local Error = require('error')
local string = require('string')

local DNS = {}

function DNS.resolve4(domain, callback)
  UV.dns_queryA(domain, callback)
end

function DNS.resolve6(domain, callback)
  UV.dns_queryAAAA(domain, callback)
end

function DNS.resolveCname(domain, callback)
  UV.dns_queryCNAME(domain, callback)
end

function DNS.resolveNs(domain, callback)
  UV.dns_queryNS(domain, callback)
end

function DNS.resolveSrv(domain, callback)
  UV.dns_querySRV(domain, callback)
end

function DNS.resolveTxt(domain, callback)
  UV.dns_queryTXT(domain, callback)
end

function DNS.resolveMx(domain, callback)
  UV.dns_queryMX(domain, callback)
end

function DNS.reverse(ip, callback)
  UV.dns_getHostByAddr(ip, callback)
end

function DNS.resolve(domain, rrtype, callback)
  if type(rrtype) == 'function' then
    callback = rrtype
    rrtype = 'A'
  end
  if rrtype == 'A' then DNS.resolve4(domain, callback)
  elseif rrtype == 'AAAA' then DNS.resolve6(domain, callback)
  elseif rrtype == 'MX' then DNS.resolveMx(domain, callback)
  elseif rrtype == 'TXT' then DNS.resolveTxt(domain, callback)
  elseif rrtype == 'SRV' then DNS.resolveSrv(domain, callback)
  elseif rrtype == 'NS' then DNS.resolveNs(domain, callback)
  elseif rrtype == 'CNAME' then DNS.resolveCname(domain, callback)
  elseif rrtype == 'PTR' then DNS.reverse(domain, callback)
  else callback(Error.new('Unknown Type ' .. rrtype)) end
end

function DNS.lookup(domain, family, callback)
  local response_family = nil
  
  if type(family) == 'function' then
    callback = family
    family = nil
  end

  if family == nil then
    family = UV.AF_UNSPEC
  elseif family == 4 then
    family = UV.AF_INET
    response_family = 4
  elseif family == 6 then
    family = UV.AF_INET6
    response_family = 6
  else
    callback(Error.new('Unknown family type ' .. family))
    return
  end

  UV.dns_getAddrInfo(domain, family, function(err, addresses)
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

return DNS
