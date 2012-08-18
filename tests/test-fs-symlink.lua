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

local completed = 0
local expected_tests = 2

local is_windows = os.type() == 'win32'

local runtest = function(skip_symlinks)
  if not skip_symlinks then
    -- test creating and reading symbolic link
    local linkData = Path.join(__dirname, 'fixtures', '/cycles/root.lua')
    local linkPath = Path.join(__dirname, 'tmp', 'symlink1.js')

    -- Delete previously created link
    pcall(FS.unlinkSync, linkPath)

    FS.symlink(linkData, linkPath, function(err)
      if err then
        return err
      end
      p('symlink done')
      -- todo: FS.lstat?
      FS.readlink(linkPath, function(err, destination)
        if err then
          return err
        end
        assert(destination == linkData)
        completed = completed + 1
      end)
    end)
  end

  -- test creating and reading hard link
  local srcPath = Path.join(__dirname, 'fixtures', 'cycles', 'root.lua')
  local dstPath = Path.join(__dirname, 'tmp', 'link1.js')

  -- Delete previously created link
  pcall(FS.unlinkSync, dstPath)

  FS.link(srcPath, dstPath, function(err)
    if err then
      return err
    end
    p('hard link done')
    local srcContent = FS.readFileSync(srcPath, 'utf8')
    local dstContent = FS.readFileSync(dstPath, 'utf8')
    assert(srcContent == dstContent)
    completed = completed + 1
  end)
end

if is_windows then
  -- On Windows, creating symlinks requires admin privileges.
  -- We'll only try to run symlink test if we have enough privileges.
  exec('whoami /priv', function(err, o)
    if err or string.find(o, 'SeCreateSymbolicLinkPrivilege', 1, true) == nil then
      expected_tests = 1
      runtest(true)
    else
      runtest(false)
    end
  end)
else
  runtest(false)
end

process:on('exit', function()
  assert(completed == expected_tests)
end)

