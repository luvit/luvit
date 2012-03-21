local crypto = require('_crypto')
local fs = require('fs')
local path = require('path')

local message1 = 'This message '
local message2 = 'will be signed'
local message = message1 .. message2

local ca_path = path.join(__dirname, 'ca')
local RSA_PUBLIC_KEY = fs.readFileSync(path.join(ca_path, 'server.pub'))
local RSA_PRIV_KEY = fs.readFileSync(path.join(ca_path, 'server.key.insecure'))
local kpriv = crypto.pkey.from_pem(RSA_PRIV_KEY, true)
local kpub = crypto.pkey.from_pem(RSA_PUBLIC_KEY)

-- TODO: FIX the private key output is wrong in luvit,
-- it was fine in virgo
--assert(kpriv:to_pem(true) == RSA_PRIV_KEY)
assert(kpub:to_pem() == RSA_PUBLIC_KEY)

-- Test digests

local hash = 'da0fd2505f0fc498649d6cf9abc7513be179b3295bb1838091723b457febe96a'

local d = crypto.digest.new("sha256")
d:update(message1)
d:update(message2)
local ret = d:final()
assert(hash == ret)

d:reset(d)
d:update(message1)
ret = d:final()
assert(hash ~= ret)

-- Test Signing
sig = crypto.sign('sha256', message, kpriv)

local v = crypto.verify.new('sha256')
v:update(message1)
v:update(message2)
local verified = v:final(sig, kpub)
assert(verified)
local sig = crypto.sign('sha256', message, kpriv)

-- Test streaming verification
local v = crypto.verify.new('sha256')
v:update(message1)
v:update(message2)
local verified = v:final(sig, kpub)
assert(verified)

local nv = crypto.verify.new('sha256')
nv:update(message1)
nv:update(message2 .. 'x')
local nverified = nv:final(sig, kpub)
assert(not nverified)

-- Test full buffer verify
verified = crypto.verify('sha256', message, sig, kpub)
assert(verified)

nverified = crypto.verify('sha256', message..'x', sig, kpub)
assert(not nverified)

-- Test bogus RSA
local bogus = crypto.pkey.from_pem(1)
assert(bogus == nil)


