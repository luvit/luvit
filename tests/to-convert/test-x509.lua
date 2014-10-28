local crypto = require('_crypto')
local fs = require('fs')
local path = require('path')

local ca_path = path.join(__dirname, 'ca')
local ca_cert = fs.readFileSync(path.join(ca_path, 'ca.crt'))
local cert_to_verify = fs.readFileSync(path.join(ca_path, 'server.crt'))

local bad_cert = [[-----BEGIN CERTIFICATE-----
MIIFxTCCA60CAQEwDQYJKoZIhvcNAQEFBQAwgaIxCzAJBgNVBAYTAlVTMRMwEQYD
VQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1TYW4gRnJhbmNpc2NvMQ4wDAYDVQQK
EwVWaXJnbzEQMA4GA1UECxMHSGFja2VyczEYMBYGA1UEAxMPQnJhbmRvbiBQaGls
aXBzMSowKAYJKoZIhvcNAQkBFhticmFuZG9uLnBoaWxpcHNAZXhhbXBsZS5jb20w
HhcNMTIwMTI2MjIwMjI0WhcNMjIwMTIzMjIwMjI0WjCBrTELMAkGA1UEBhMCVVMx
EzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcTDVNhbiBGcmFuY2lzY28xGjAY
BgNVBAoTEVZpcmdvIFRlc3QgU2lnbmVyMQ8wDQYDVQQLEwZIYWNrZXIxGDAWBgNV
BAMTD0JyYW5kb24gUGhpbGlwczEqMCgGCSqGSIb3DQEJARYbYnJhbmRvbi5waGls
aXBzQGV4YW1wbGUuY29tMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
0Py2Gaq9lsxS7gN4UoF17iV9fI/NW+tgtfgjLqDrNpyvFqlBchhKVeoA2wdaRWpH
uDPWLnwUQNRYu4YVLuAt/32oG9AYzgBEjNMLGdAaqGGSl8HCdnXQh2hJD24WRa1O
dcj+o1kIoUKi5BklBZd+HzTEjbinLUZgCAYxohaIC8yLsZGy6Ez35pAu4XokP9HM
xVM9tZN6HwHI//givYkKv7R6a9iY0fLIHwmEoc4yVw7zNtBqzLLUHROjLCqqvIoi
Zkn7Z4k3080WCD1Q0hQt0SKsf+DCDGS3zaE5EeyVvfBVelqz2v4kFzNf+0lEA411
UnPEMkfZt+x2Gwr2UAObag961p46Ba+QgifQpyXNQ3bCapqMghfSz6PHeGYeFPNW
QKzVLNQSjnPBc0i0h+AckAFJRzYXWZsh1Jq2TCvTiw+1Irm1m9Ltuv+W85hvhLuB
1AY3runMLQN0eQ0gvjbkcKCKtpoKy4rHtVTiy+8hzL1zaWYu3Bny7BgPiKciiMbo
7TkDzWVX0hIfjcgJAzVogLC1/TVEQkoImomAvzPGXQpbLlX843juVeBCSwdkBAjj
lMoJyGcv6wfO91tkG8PWxUjPQQcJCr8/VSoK10jdUjrQocb3u+ud27n/6eQZOpvw
sbn5q3mr2+zUIon/9k8DbgPEhk6nrCq5rN6A7eCcdwMCAwEAATANBgkqhkiG9w0B
AQUFAAOCAgEAOJfGCRbeByGWHxU1DWTmkqG97NoROUw0Gq9BO3WvxbFCvMettDPz
SF6uUu+C7u5uQ5rCqAB1nDe2uCDljvB6XKBjfk/jbhFBa+56JDKmXxjXRaSLFpX2
NxByCb48Hir5021Qcebz+ojScwS6O/jpj/sOlGipssICJExBQs0ywlFKbLsM7zRs
v+s0MO5C8cgFO5Yz0KdOXep8rXStaM9N0IZApG+bywBI+1yQbOqP+BUJ95drmXfe
meDJR1/srhxRUicgq1psE2xsd9UEx6AdoakUDv7T2owtVw3PJavNQCW+8ql67DQj
7epQTQ5wVty1ED5PyfHYOlC0LNlUNmoADegUwyYcQ4246ayfqcnJxacQXIpWylF/
mGHQcR4AmVYsr26UkDYXcwb7BDxH0eb3w5s7X0hwtFzd8jwx3Vagdf4fafm4Vahz
XDiDXVMTZqyncIBu4/8PFfgqgLra/MhHODbLamndPMeHAn0zNXk5HEkiNRhHymSe
oTKkB4Ol10/kEWvOswU/LS69w7HDFgJAnnEi2+XCTHMim8kDcbhoGr3rlL1cT7yL
B3P11S3lepH+PFTFfU19IlrDGfXDxlKNWR9XNVqtQw/qnN+T7XZFW2tuDiMecCYj
64Qm7mwOJZDp1eFU0GiTuF7r7ZMBWTDDe98eOFOOiUZ3m+m43SGVb+U=
-----END CERTIFICATE-----]]

-- test_x509_verify
ca = assert(crypto.x509_ca())

assert(ca.add_pem)
assert(ca:add_pem(ca_cert))
assert(ca:add_pem("FOBAR") == nil)

assert(ca:verify_pem(cert_to_verify))
assert(ca:verify_pem(bad_cert) == false)

local ca_path = path.join(__dirname, 'ca')
local ca_cert = fs.readFileSync(path.join(ca_path, "ca.crt"))
local cert_to_verify = fs.readFileSync(path.join(ca_path, "server.crt"))
local signature = fs.readFileSync(path.join(ca_path, "server.pub.sig"))
local message = fs.readFileSync(path.join(ca_path, "server.pub"))

-- Verify the CA signed the server key
local ca, err = assert(crypto.x509_ca())
ca:add_pem(ca_cert)
assert(ca:verify_pem(cert_to_verify) == true)

local x509 = crypto.x509_cert()
x509:from_pem(cert_to_verify)

local kpub = x509:pubkey()

-- test_x509_sig_fails_on_bad_message

-- Test streaming verification fails on bad message
v = crypto.verify.new('sha256')
v:update(message .. 'x')
verified = v:final(signature, kpub)
assert(not verified)

-- test_x509_sig_fails_on_bad_sig
-- Test streaming verification fails on bad sig
v = crypto.verify.new('sha256')
v:update(message)
verified = v:final(signature .. 'x', kpub)
assert(not verified)

-- test_x509_sig_verify_works
-- Test streaming verification
v = crypto.verify.new('sha256')
v:update(message)
verified = v:final(signature, kpub)
assert(verified)
