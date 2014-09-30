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

require("helper")

local path = require('path')
local path_base = require('path_base')
local os = require('os')

-- test `path.dirname`
if (os.type() ~= "win32") then
  assert(path.dirname('/usr/bin/vim') == '/usr/bin')
  assert(path.dirname('/usr/bin/') == '/usr')
  assert(path.dirname('/usr/bin') == '/usr')
else
  assert(path.dirname('C:\\Users\\philips\\vim.exe') == 'C:\\Users\\philips')
  assert(path.dirname('C:\\Users\\philips\\') == 'C:\\Users')
  assert(path.dirname('C:\\Users\\philips\\') == 'C:\\Users')
end

-- Test out the OS path objects
assert(path_base.posix:dirname('/usr/bin/vim') == '/usr/bin')
assert(path_base.posix:dirname('/usr/bin/') == '/usr')
assert(path_base.posix:dirname('/usr/bin') == '/usr')
assert(path_base.nt:dirname('C:\\Users\\philips\\vim.exe') == 'C:\\Users\\philips')
assert(path_base.nt:dirname('C:\\Users\\philips\\') == 'C:\\Users')
assert(path_base.nt:dirname('C:\\Users\\philips\\') == 'C:\\Users')

assert(path_base.posix:join('foo', '/bar') == "foo/bar")
assert(path_base.posix:join('foo', 'bar') == "foo/bar")
assert(path_base.posix:join('foo/', 'bar') == "foo/bar")
assert(path_base.posix:join('foo/', '/bar') == "foo/bar")
assert(path_base.posix:join('/foo', '/bar') == "/foo/bar")
assert(path_base.posix:join('/foo', 'bar') == "/foo/bar")
assert(path_base.posix:join('/foo/', 'bar') == "/foo/bar")
assert(path_base.posix:join('/foo/', '/bar') == "/foo/bar")
assert(path_base.posix:join('foo', '/bar/') == "foo/bar/")
assert(path_base.posix:join('foo', 'bar/') == "foo/bar/")
assert(path_base.posix:join('foo/', 'bar/') == "foo/bar/")
assert(path_base.posix:join('foo/', '/bar/') == "foo/bar/")

assert(path.basename('bar.lua') == 'bar.lua')
assert(path.basename('bar.lua', '.lua') == 'bar')
assert(path.basename('bar.lua.js', '.lua') == 'bar.lua.js')
assert(path.basename('.lua', 'lua') == '.')
assert(path.basename('bar', '.lua') == 'bar')

-- test path.basename os specifics
assert(path_base.posix:basename('/foo/bar.lua') == 'bar.lua')
assert(path_base.posix:basename('/foo/bar.lua', '.lua') == 'bar')
assert(path_base.nt:basename('c:\\foo\\bar.lua') == 'bar.lua')
assert(path_base.nt:basename('c:\\foo\\bar.lua', '.lua') == 'bar')

-- test path.isAbsolute
assert(path_base.posix:isAbsolute('/foo/bar.lua'))
assert(not path_base.posix:isAbsolute('foo/bar.lua'))
assert(path_base.nt:isAbsolute('C:\\foo\\bar.lua'))
assert(path_base.nt:isAbsolute('D:\\foo\\bar.lua'))
assert(not path_base.nt:isAbsolute('foo\\bar.lua'))
