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

local successes = 0

local file = Path.join(__dirname, 'fixtures', 'a.lua')

p('open ' .. file)

FS.open(file, 'a', '0777', function(err, fd)
  p('fd ' .. fd)
  if err then
    return err
  end

  FS.fdatasyncSync(fd)
  p('fdatasync SYNC: ok')
  successes = successes + 1

  FS.fsyncSync(fd)
  p('fsync SYNC: ok')
  successes = successes + 1

  FS.fdatasync(fd, function(err)
    if err then
      return err
    end
    p('fdatasync ASYNC: ok')
    successes = successes + 1
    FS.fsync(fd, function(err)
      if err then
        return err
      end
      p('fsync ASYNC: ok')
      successes = successes + 1
    end)
  end)
end)

process:on('exit', function()
  assert(successes == 4)
end)
