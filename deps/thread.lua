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
--[[lit-meta
  name = "luvit/thread"
  version = "2.1.0"
  license = "Apache 2"
  homepage = "https://github.com/luvit/luvit/blob/master/deps/thread.lua"
  description = "thread module for luvit"
  tags = {"luvit", "thread","threadpool","work"}
  dependencies = {
    "luvit/core@1.0.5",
  }
]]

local uv = require('uv')
local bundlePaths = require('luvi').bundle.paths
local Object = require('core').Object

local function start(thread_func, ...)
  local dumped = type(thread_func)=='function'
    and string.dump(thread_func) or thread_func

  local function thread_entry(dumped, bundlePaths, ...)

    -- Convert paths back to table
    local paths = {}
    for path in bundlePaths:gmatch("[^;]+") do
      paths[#paths + 1] = path
    end

    -- Load luvit-loader environment
    local bundle = require('luvibundle').commonBundle(paths)
    loadstring(bundle.readfile("luvit-loader.lua"), "bundle:luvit-loader.lua")()

    -- Run thread in luvit environment
    require('init')(loadstring(dumped), ...)
  end
  return uv.new_thread(thread_entry, dumped, table.concat(bundlePaths, ";"), ...)
end

local function join(thread)
    return uv.thread_join(thread)
end

local function equals(thread1,thread2)
    return uv.thread_equals(thread1,thread2)
end

local function self()
    return uv.thread_self()
end

--- luvit threadpool
local Worker = Object:extend()

function Worker:queue(...)
    uv.queue_work(self.handler, self.dumped, self.bundlePaths, ...)
end

local function work(thread_func, notify_entry)
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
      local paths = {}
      for path in bundlePaths:gmatch("[^;]+") do
        paths[#paths + 1] = path
      end

      -- Load luvi environment
      local bundle = require('luvibundle').commonBundle(paths)
      loadstring(bundle.readfile("luvit-loader.lua"), "bundle:luvit-loader.lua")()

      -- Inject the global process table
      _G.process = _G.process or require('process').globalProcess()

      -- cache it
      _G._uv_works[dumped] = fn
    else
      fn = _G._uv_works[dumped]
    end
    -- Run function

    return fn(...)
  end

  worker.handler = uv.new_work(thread_entry,notify_entry)
  return worker
end

local function queue(worker, ...)
  worker:queue(...)
end

return {
  start = start,
  join = join,
  equals = equals,
  self = self,
  work = work,
  queue = queue,
}
