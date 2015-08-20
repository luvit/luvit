--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

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

--- luvit thread management
local uv = require('uv')
local bundlePaths = require('luvi').bundle.paths

exports.name = "luvit/thread"
exports.version = "0.1.0"
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/thread.lua"
exports.description = "thread module for luvit"
exports.tags = {"luvit", "thread"}

exports.start = function(thread_func, ...)
  local dumped = string.dump(thread_func)

  local function thread_entry(dumped, bundlePaths, ...)
    local luvi = require('luvi')
    --set is Windows
    if _G.jit then
      luvi.isWindows = _G.jit.os == "Windows"
    else
      luvi.isWindows = not not package.path:match("\\")
    end
    -- Convert paths back to table
    local paths = {}
    for path in bundlePaths:gmatch("[^;]+") do
      paths[#paths + 1] = path
    end

    -- Load luvi environment
    local _, mainRequire = require('luvibundle').commonBundle(paths)

    -- Run function with require injected
    local fn = loadstring(dumped)
    getfenv(fn).require = mainRequire
    fn(...)

    -- Start new event loop for thread.
    require('uv').run()
  end
  return uv.new_thread(thread_entry, dumped, table.concat(bundlePaths, ";"), ...)
end

exports.join = function(thread)
    return uv.thread_join(thread)
end

exports.equals = function(thread1,thread2)
    return uv.thread_equals(thread1,thread2)
end

exports.self = function()
    return uv.thread_self()
end
