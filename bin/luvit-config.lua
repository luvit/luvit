#!/usr/bin/env luvit
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

local Table = require('table')
local OS = require('os')
local command = process.argv[1]
if command == "--libs" then
  local flags = {
    "-shared",
    "-lm"
  }
  if OS.type() == "Darwin" then
    if false then -- TODO: check if 64 bit
      Table.insert(flags, "-pagezero_size 10000")
      Table.insert(flags, "-image_base 100000000")
    end
    Table.insert(flags, "-undefined dynamic_lookup")
  end
  print(Table.concat(flags, " "))
elseif command == "--cflags" then
  local Path = require('path')
  local UV = require('uv')
  local Fs = require('fs')
  -- calculate includes relative to the binary
  local include_dir = Path.resolve(Path.dirname(UV.execpath()), "../include/luvit")
  -- if not found...
  if not Fs.exists_sync(include_dir) then
    -- calculate includes relative to the symlink to the binary
    include_dir = Path.resolve(__dirname, "../include/luvit")
  end
  local flags = {
    "-I" .. include_dir,
    "-I" .. include_dir .. "/http_parser",
    "-I" .. include_dir .. "/uv",
    "-I" .. include_dir .. "/luajit",
    "-D_LARGEFILE_SOURCE",
    "-D_FILE_OFFSET_BITS=64",
    "-Wall -Werror",
    "-fPIC"
  }
  print(Table.concat(flags, " "))
elseif command == "--version" or command == "-v" then
  print(process.version)
else
  print "Usage: luvit-config [--version] [--cflags] [--libs]"
  -- Also note about rebase for OSX 64bit? <http://luajit.org/install.html#embed>
end
