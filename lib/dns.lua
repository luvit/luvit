local UV = require('uv')

local DNS = {}

function DNS.resolve4(domain, callback)
  UV.dns_queryA(domain, callback)
end

function DNS.resolve6(domain, callback)
  UV.dns_queryAAAA(domain, callback)
end

function DNS.reverse(ip, callback)
  UV.dns_getHostByAddr(ip, callback)
end

return DNS
