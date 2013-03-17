--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License")
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

load("helper")

local FS = load('fs')
local Path = load('path')
local Buffer = load('buffer').Buffer

local fn = Path.join(__dirname, 'tmp', 'write.txt')

local foo = 'foo'
local fd = FS.openSync(fn, 'w')

local written = FS.writeSync(fd, -1, '')
assert(written == 0)

FS.writeSync(fd, -1, foo)

local bar = 'bár'
-- TODO: Support buffer argument
written = FS.writeSync(fd, -1, Buffer:new(bar):toString())
assert(written > 3)
FS.closeSync(fd)

assert(FS.readFileSync(fn) == 'foobár')
