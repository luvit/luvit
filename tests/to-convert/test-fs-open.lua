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

local FS = require('fs')

-- should throw ENOENT, not EBADF
-- see https://github.com/joyent/node/pull/1228
local ok, err = pcall(FS.openSync, '/path/to/file/that/does/not/exist', 'r')
assert(not ok)
assert(err.code == 'ENOENT')
assert(err.path == '/path/to/file/that/does/not/exist')
assert(err.source == 'open')

local openFd
FS.open(__filename, 'r', function(err, fd)
  if err then
    return err
  end
  openFd = fd
end)

-- TODO: Support file open flag 's'
--[[
local openFd2
FS.open(__filename, 'rs', function(err, fd)
  if err then
    return err
  end
  openFd2 = fd
end)
--]]

process:on('exit', function()
  assert(openFd)
--  assert(openFd2)
end)
