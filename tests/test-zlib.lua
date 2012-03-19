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

require("helper")

local Zlib = require("zlib_native")

--
-- smoke test: low level inflate/deflate
--

assert(Zlib.new('inflate'):write(Zlib.new('deflate',6):write('test\n','finish')) == 'test\n')

local test_str = require("fs").readFileSync("./fixtures/test.gz")
--assert(#test_str == 30)
local inflated = Zlib.new('inflate'):write(test_str, "finish")
assert(inflated == "test\n")

test_str = "we want packed modules, as zipballs!"
local deflated = Zlib.new('deflate'):write(test_str, "finish")
inflated = Zlib.new('inflate'):write(deflated, "finish")
assert(inflated == test_str)

-- in chunks
test_str = "we want packed modules, as zipballs!"
local packer = Zlib.new('deflate')
local deflated1, err = packer:write(test_str:sub(1, 3), "none")
local deflated2, err = packer:write(test_str:sub(4), "finish")
deflated = deflated1 .. deflated2
local unpacker = Zlib.new('inflate')
inflated = unpacker:write(deflated:sub(1, 6)) .. unpacker:write(deflated:sub(7), "finish")
assert(inflated == test_str)

--
-- TODO: inside worker
--

--
-- stream interface
--

local Table = require('table')
local Zlib = require("zlib")

local file = require('fs').createReadStream('./fixtures/test.gz', {
  chunk_size = 3,
})
local gunzip = Zlib.Zlib:new('inflate')
local buf = {}
gunzip:on('data', function (text)
  buf[#buf + 1] = text
end)
gunzip:on('end', function ()
  assert(Table.concat(buf) == 'test\n')
end)
file:pipe(gunzip)

--
-- TODO: unzip a zipball
--
