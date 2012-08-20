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
local Path = require('path')

function unlink(pathname)
  pcall(FS.rmdirSync, pathname)
end

local tmpDir = __dirname .. '/tmp'

(function()
  local ncalls = 0
  local pathname = tmpDir .. '/test1'

  unlink(pathname)

  FS.mkdir(pathname, function(err)
    assert(err == null)
    assert(FS.existsSync(pathname) == true)
    ncalls = ncalls + 1
  end)

  process:on('exit', function()
    unlink(pathname)
    assert(ncalls == 1)
  end)
end)();

(function()
  local ncalls = 0
  local pathname = tmpDir .. '/test2'

  unlink(pathname)

  FS.mkdir(pathname, 511 --[[0777]], function(err)
    assert(err == null)
    assert(FS.existsSync(pathname) == true)
    ncalls = ncalls + 1
  end)

  process:on('exit', function()
    unlink(pathname)
    assert(ncalls == 1)
  end)
end)();

(function()
  local pathname = tmpDir .. '/test3'

  unlink(pathname)
  FS.mkdirSync(pathname)

  local exists = FS.existsSync(pathname)
  unlink(pathname)

  assert(exists == true)
end)()

-- Keep the event loop alive so the async mkdir() requests
-- have a chance to run (since they don't ref the event loop).
process.nextTick(function() end)
