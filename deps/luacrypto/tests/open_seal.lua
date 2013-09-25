require 'crypto'

assert(crypto.pkey, "crypto.pkey is unavaliable")

k = crypto.pkey.generate('rsa', 1024)
assert(k, "no key generated")

k:write('pub.pem', 'priv.pem')

kpub = assert(crypto.pkey.read('pub.pem'))
kpriv = assert(crypto.pkey.read('priv.pem', true))

assert(crypto.open, "crypto.open is unavaliable")
assert(crypto.seal, "crypto.seal is unavaliable")

message = string.rep('This message will be signed', 122)

data, ek, iv = assert(crypto.seal("aes128", message, kpub))

assert(crypto.open("aes128", data, kpriv, ek, iv) == message)

local ctx = crypto.seal.new("aes128", kpub)
local p1 = ctx:update(message)
local p2, ek_2, iv_2 = ctx:final()
assert(crypto.open("aes128", p1..p2, kpriv, ek_2, iv_2) == message)

local ctx = crypto.open.new("aes128", kpriv, ek_2, iv_2)
p3 = ctx:update(p1..p2)
p4 = ctx:final()
assert(message == (p3 .. p4))

print("OK")
