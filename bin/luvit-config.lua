#!/usr/bin/env luvit
local Table = require('table')
local command = process.argv[1]
if command == "--libs" then
  local flags = {
    "-shared",
    "-lm"
  }
  -- -pagezero_size 10000 -image_base 100000000 (for OSX 64bit?)
  print(Table.concat(flags, " "))
elseif command == "--cflags" then
  local Path = require('path')
  local UV = require('uv')
  local include_dir = Path.resolve(Path.dirname(UV.execpath()), "../include/luvit")
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
