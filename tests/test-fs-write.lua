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
local os = require('os')
local string = require('string')

local fn = Path.join(__dirname, 'tmp', 'write.txt')
local fn2 = Path.join(__dirname, 'tmp', 'write2.txt')
local expected = 'ümlaut.'
local found, found2

FS.open(fn, 'w', tonumber('0644', 8), function(err, fd)
  if err then
    return err
  end
  p('open done')
  -- TODO: support same arguments as fs.write in node.js
  FS.write(fd, 0, '', function(err, written)
    assert(0 == written)
  end)
  FS.write(fd, 0, expected, function(err, written)
    p('write done')
    if err then
      return err
    end
    assert(#expected == written)
    FS.closeSync(fd)
    found = FS.readFileSync(fn)
    p(string.format('expected: "%s"', expected))
    p(string.format('found: "%s"', found))
    FS.unlinkSync(fn)
  end)
end)


FS.open(fn2, 'w', tonumber('0644', 8),
  function(err, fd)
    if err then
      return err
    end
    p('open done')
    FS.write(fd, 0, '', function(err, written)
      assert(0 == written)
    end)
    FS.write(fd, 0, expected, function(err, written)
      p('write done')
      if err then
        return err
      end
      assert(#expected == written)
      FS.closeSync(fd)
      found2 = FS.readFileSync(fn2)
      p(string.format('expected: "%s"', expected))
      p(string.format('found: "%s"', found2))
      FS.unlinkSync(fn2)
    end)
  end
)


process:on('exit', function()
  assert(expected == found)
  assert(expected == found2)
end)

