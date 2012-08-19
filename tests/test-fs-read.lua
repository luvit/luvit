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

require("helper")

local math = require('math')
local string = require('string')
local FS = require('fs')
local Path = require('path')

local filepath = Path.join(__dirname, 'fixtures', 'x.txt')
local fd = FS.openSync(filepath, 'r')
local expected = 'xyz\n'
local readCalled = 0

FS.read(fd, 0, #expected, function(err, str, bytesRead)
  readCalled = readCalled + 1

  assert(not err)
  assert(str == expected)
  assert(bytesRead == #expected)
end)

local r, bytesRead = FS.readSync(fd, 0, #expected)
assert(r == expected)
assert(bytesRead == #expected)

process:on('exit', function()
  assert(readCalled == 1)
end)
