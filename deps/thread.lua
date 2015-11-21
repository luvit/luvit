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

exports.name = "luvit/thread"
exports.version = "0.1.2"
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/thread.lua"
exports.description = "thread module for luvit"
exports.tags = {"luvit", "thread","threadpool","work"}
exports.dependencies = {
  "luvit/core@1.0.5",
}

local uv = require('uv')
local bundlePaths = require('luvi').bundle.paths
local Object = require('core').Object

exports.start = function(thread_func, ...)
  local dumped = type(thread_func)=='function'
    and string.dump(thread_func) or thread_func

  local function thread_entry(dumped, bundlePaths, ...)

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

--- luvit threadpool
local Worker = Object:extend()

function Worker:queue(...)
    uv.queue_work(self.handler, self.dumped, self.bundlePaths, ...)
end

exports.work = function(thread_func, notify_entry)
  local worker = Worker:new()
  worker.dumped = type(thread_func)=='function'
    and string.dump(thread_func) or thread_func
  worker.bundlePaths = table.concat(bundlePaths, ";")

  local function thread_entry(dumped, bundlePaths, ...)
    if not _G._uv_works then
      _G._uv_works = {}
    end

    --try to find cached function entry
    local fn
    if not _G._uv_works[dumped] then
      fn = loadstring(dumped)

      -- Convert paths back to table
      local paths = { require('uv').cwd() }
      for path in bundlePaths:gmatch("[^;]+") do
        paths[#paths + 1] = path
      end

      -- Load luvi environment
      local _, mainRequire = require('luvibundle').commonBundle(paths)
      -- require injected
      getfenv(fn).require = mainRequire

      -- cache it
      _G._uv_works[dumped] = fn
    else
      fn = _G._uv_works[dumped]
    end
    -- Run function
    if not _G.process then
      _G.process = require('process').globalProcess()
    end
    return fn(...)
  end

  worker.handler = uv.new_work(thread_entry,notify_entry)
  return worker
end

exports.queue = function(worker, ...)
  worker:queue(...)
end
