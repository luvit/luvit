local pem = require('fs').readFileSync("certs.pem")
local x509 = require('openssl').x509
local out = {}
for cert in pem:gmatch("%-%-%-%-%-BEGIN CERTIFICATE%-%-%-%-%-[^-]+%-%-%-%-%-END CERTIFICATE%-%-%-%-%-") do
  p(cert)
  cert = x509.read(cert)
  local der = cert:export("der")
  local len = #der
  out[#out + 1] = string.char(
    bit.rshift(len, 24),
    bit.band(bit.rshift(len, 16), 0xff),
    bit.band(bit.rshift(len, 8), 0xff),
    bit.band(len, 0xff)
  )
  out[#out + 1] = der
end
require('fs').writeFileSync("certs.dat", table.concat(out))
