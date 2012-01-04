local UV = require('uv')

local DNS = {}

function DNS.resolve4(domain, callback)
  UV.dns_queryA(domain, callback)
end

return DNS
