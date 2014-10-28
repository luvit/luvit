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
local string = require('string')
local bit = require('bit')
local os = require('os')

local got_error = false
local success_count = 0
local mode_async
local mode_sync
local is_windows = os.type() == 'win32'

local openCount = 0

function open(...)
  openCount = openCount + 1
  return FS._open(...)
end

function openSync(...)
  openCount = openCount + 1
  return FS._openSync(...)
end

function close(...)
  openCount = openCount - 1
  return FS._close(...)
end

function closeSync(...)
  openCount = openCount - 1
  return FS._closeSync(...)
end

-- Need to hijack FS.open/close to make sure that things
-- get closed once they're opened.
FS._open = FS.open
FS._openSync = FS.openSync
FS.open = open
FS.openSync = openSync
FS._close = FS.close
FS._closeSync = FS.closeSync
FS.close = close
FS.closeSync = closeSync


-- On Windows chmod is only able to manipulate read-only bit
-- TODO: test on windows
if is_windows then
  mode_async = 256 --[[tonumber('0400', 8)]] -- read-only
  mode_sync = 384  --[[tonumber('0600', 8)]] -- read-write
else
  mode_async = 511 --[[tonumber('0777', 8)]]
  mode_sync = 420 --[[tonumber('0644', 8)]]
end

local file1 = Path.join(__dirname, 'fixtures', 'a.lua')
local file2 = Path.join(__dirname, 'fixtures', 'a1.lua')

function maskMode(mode, mask)
  return bit.band(mode, mask or 511 --[[tonumber('0777',8)]])
end

FS.chmod(file1, string.format('%o', mode_async), function(err)
  if err then
    got_error = true
  else
    p(FS.statSync(file1).mode)

    if is_windows then
      assert(maskMode(maskMode(FS.statSync(file1).mode), mode_async))
    else
      assert(mode_async == maskMode(FS.statSync(file1).mode))
    end

    -- TODO: accept mode in number
    FS.chmodSync(file1, string.format('%o', mode_sync))
    if is_windows then
      assert(maskMode(maskMode(FS.statSync(file1).mode), mode_sync))
    else
      assert(mode_sync == maskMode(FS.statSync(file1).mode))
    end
    success_count = success_count + 1
  end
end)

FS.open(file2, 'a', '0666', function(err, fd)
  if err then
    got_error = true
    p(err.stack)
    return
  end
  FS.fchmod(fd, string.format('%o', mode_async), function(err)
    if err then
      got_error = true
    else
      p(FS.fstatSync(fd).mode)

      if is_windows then
        assert(maskMode(maskMode(FS.fstatSync(fd).mode), mode_async))
      else
        assert(mode_async == maskMode(FS.fstatSync(fd).mode))
      end

      -- TODO: accept mode in number
      FS.fchmodSync(fd, string.format('%o', mode_sync))
      if is_windows then
        assert(maskMode(maskMode(FS.fstatSync(fd).mode), mode_sync))
      else
        assert(mode_sync == maskMode(FS.fstatSync(fd).mode))
      end
      success_count = success_count + 1
      FS.close(fd)
    end
  end)
end)

-- lchmod
if FS.lchmod then
  local link = Path.join(__dirname, 'tmp', 'symbolic-link')

  pcall(function()
    FS.unlinkSync(link)
  end)
  FS.symlinkSync(file2, link)

  FS.lchmod(link, mode_async, function(err)
    if err then
      got_error = true
    else
      p(FS.lstatSync(link).mode)
      assert(mode_async == maskMode(FS.lstatSync(link).mode))

      -- TODO: accept mode in number
      FS.lchmodSync(link, string.format('%o', mode_sync))
      assert(mode_sync == maskMode(FS.lstatSync(link).mode))
      success_count = success_count + 1
    end
  end)
else
  success_count = success_count + 1
end


process:on('exit', function()
  assert(3 == success_count)
  assert(0 == openCount)
  assert(false == got_error)
end)

