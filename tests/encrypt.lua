function tohex(s)
	return (s:gsub('.', function (c) return string.format("%02x", string.byte(c)) end))
end
function hexprint(s)
	print(crypto.hex(s))
end

require 'crypto'

-- TESTING HEX

local tst = 'abcd'
assert(crypto.hex, "missing crypto.hex")
local actual = crypto.hex(tst)
local expected = tohex(tst)
assert(actual == expected, "different hex results")

-- TESTING ENCRYPT

assert(crypto.encrypt, "missing crypto.encrypt")

local cipher = 'aes128'
local text = 'Hello world!'
local key = 'abcd'
local iv = '1234'

local res = assert(crypto.encrypt(cipher, text, key, iv))
assert(type(res) == "string", "wrong result type, expecting string")
assert(#res % 16 == 0, "unexpected result size") -- aes128 block size is 16bytes
assert(crypto.hex(res) == "9bac9a71dd600824706096852e7282df", "unexpected result")

local res2 = crypto.encrypt(cipher, text, key, iv)
assert(res == res2, "the results are different!")

assert(crypto.encrypt.new, "missing crypto.encrypt.new")
local ctx = crypto.encrypt.new(cipher, key, iv)
local p1 = ctx:update(text)
local p2 = ctx:final()
local res3 = p1 .. p2
assert(res == res3, "constructed result is different from direct")

-- TESTING DECRYPT

assert(crypto.decrypt, "missing crypto.decrypt")

local dec = crypto.decrypt(cipher, res, key, iv)
assert(dec == text, "different direct result")

print(dec)

assert(crypto.decrypt.new, "missing crypto.decrypt.new")

local ctx = crypto.decrypt.new(cipher, key, iv)
local p1 = ctx:update(res)
local p2 = ctx:final()
local dec2 = p1 .. p2

assert(dec2 == text, "different partial result")

-- Testing errors when decrypting
local ctx, err = crypto.decrypt("aes128", res, key.."improper key", iv)
assert(not ctx and err, "should have failed")

-- wrong iv, will result in garbage
local ctx, err = crypto.decrypt("aes128", res, key, iv .. "foo")
assert(ctx ~= text, "should have failed")

local ctx, err = crypto.decrypt("aes128", res .. "foo", key, iv)
assert(not ctx and err, "should have failed")

-- don't crash on an invalid iv
local ok, ctx, err = pcall(crypto.decrypt, "aes128", res, key, iv .. "123456123456123456")
assert(not ok and ctx, "should have failed")
local ok, ctx = pcall(crypto.decrypt.new, "aes128", key, iv .. "123456123456123456")
assert(not ok and ctx, "should have failed")

-- don't crash on an invalid key
local ok, ctx, err = pcall(crypto.decrypt, "aes128", res, string.rep(key, 100), iv)
assert(not ok and ctx, "should have failed")
local ok, ctx = pcall(crypto.decrypt.new, "aes128", string.rep(key, 100), iv)
assert(not ok and ctx, "should have failed")


-- Testing errors when encrypting

-- don't crash on an invalid iv
local ok, res, err = pcall(crypto.encrypt, "aes128", text, key, iv .. "123456123456123456")
assert(not ok and res)
local ok, res, err = pcall(crypto.encrypt.new, "aes128", key, iv .. "123456123456123456")
assert(not ok and res)

-- don't crash on an invalid key
local ok, res, err = pcall(crypto.encrypt, "aes128", text, string.rep(key, 100), iv)
assert(not ok and res)
local ok, res, err = pcall(crypto.encrypt.new, "aes128", string.rep(key, 100), iv)
assert(not ok and res)

local res = crypto.decrypt("aes128", crypto.encrypt("aes128", "", key, iv), key, iv)
assert(res == "")