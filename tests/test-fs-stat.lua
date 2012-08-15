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
local JSON = require('json')

local got_error = false
local success_count = 0

FS.stat('.', function(err, stats)
  if err then
    got_error = true
  else
    p(JSON.stringify(stats))
    assert(type(stats.mtime) == 'number')
    success_count = success_count + 1
  end
end)

FS.lstat('.', function(err, stats)
  if err then
    got_error = true
  else
    p(JSON.stringify(stats))
    assert(type(stats.mtime) == 'number')
    success_count = success_count + 1
  end
end)

-- fstat
--FS.open('.', 'r', nil, function(err, fd)
FS.open('.', 'r', function(err, fd)
  assert(not err)
  assert(fd)

  FS.fstat(fd, function(err, stats)
    if err then
      got_error = true
    else
      p(JSON.stringify(stats))
      assert(type(stats.mtime) == 'number')
      success_count = success_count + 1
      FS.close(fd)
    end
  end)

end)

-- fstatSync
--FS.open('.', 'r', nil, function(err, fd)
FS.open('.', 'r', function(err, fd)
  local ok, stats
  ok, stats = pcall(FS.fstatSync, fd)
  if not ok then
    got_error = true
  end
  if stats then
    p(JSON.stringify(stats))
    assert(type(stats.mtime) == 'number')
    success_count = success_count + 1
  end
  FS.close(fd)
end)

p('stating: ' .. __filename)
FS.stat(__filename, function(err, s)
  if err then
    got_error = true
  else
    p(JSON.stringify(s))
    success_count = success_count + 1

    p('is_directory: ' .. JSON.stringify(s.is_directory))
    assert(false == s.is_directory)

    p('is_file: ' .. JSON.stringify(s.is_file))
    assert(true == s.is_file)

    p('is_socket: ' .. JSON.stringify(s.is_socket))
    assert(false == s.is_socket)

    p('is_block_device: ' .. JSON.stringify(s.is_block_device))
    assert(false == s.is_block_device)

    p('is_character_device: ' .. JSON.stringify(s.is_character_device))
    assert(false == s.is_character_device)

    p('is_fifo: ' .. JSON.stringify(s.is_fifo))
    assert(false == s.is_fifo)

    p('is_symbolic_link: ' .. JSON.stringify(s.is_symbolic_link))
    assert(false == s.is_symbolic_link)

    assert(type(s.mtime) == 'number')
  end
end)

process:on('exit', function()
  assert(5 == success_count)
  assert(false == got_error)
end)

