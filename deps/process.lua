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

--[[lit-meta
  name = "luvit/process"
  version = "2.0.0"
  dependencies = {
    "luvit/hooks@2.0.0",
    "luvit/timer@2.0.0",
    "luvit/utils@2.0.0",
    "luvit/core@2.0.0",
    "luvit/stream@2.0.0",
    "luvit/pretty-print@2.0.0",
  }
  license = "Apache 2"
  homepage = "https://github.com/luvit/luvit/blob/master/deps/process.lua"
  description = "Node-style global process table for luvit"
  tags = {"luvit", "process"}
]]

local env = require('env')
local hooks = require('hooks')
local os = require('os')
local timer = require('timer')
local utils = require('utils')
local uv = require('uv')
local Emitter = require('core').Emitter
local Readable = require('stream').Readable
local Writable = require('stream').Writable
local pp = require('pretty-print')

local function nextTick(...)
  timer.setImmediate(...)
end

local function cwd()
  return uv.cwd()
end

local lenv = {}
function lenv.get(key)
  return lenv[key]
end
setmetatable(lenv, {
  __pairs = function(table)
    local keys = env.keys()
    local index = 0
    return function(...)
      index = index + 1
      local name = keys[index]
      if name then
        return name, table[name]
      end
    end
  end,
  __index = function(table, key)
    return env.get(key)
  end,
  __newindex = function(table, key, value)
    if value then
      env.set(key, value, 1)
    else
      env.unset(key)
    end
  end
})

local function kill(pid, signal)
  uv.kill(pid, signal or 'sigterm')
end

local signalWraps = {}

local function on(self, _type, listener)
  if _type == "error" or _type == "exit" then
    Emitter.on(self, _type, listener)
  else
    if not signalWraps[_type] then
      local signal = uv.new_signal()
      signalWraps[_type] = signal
      uv.unref(signal)
      uv.signal_start(signal, _type, function() self:emit(_type) end)
    end
    Emitter.on(self, _type, listener)
  end
end

local function removeListener(self, _type, listener)
  local signal = signalWraps[_type]
  if not signal then return end
  signal:stop()
  uv.close(signal)
  signalWraps[_type] = nil
  Emitter.removeListener(self, _type, listener)
end

local function exit(self, code)
  local left = 2
  code = code or 0
  local function onFinish()
    left = left - 1
    if left > 0 then return end
    self:emit('exit', code)
    os.exit(code)
  end
  process.stdout:once('finish', onFinish)
  process.stdout:_end()
  process.stderr:once('finish', onFinish)
  process.stderr:_end()
end

local UvStreamWritable = Writable:extend()
function UvStreamWritable:initialize(handle)
  Writable.initialize(self)
  self.handle = handle
end

function UvStreamWritable:_write(data, callback)
  uv.write(self.handle, data, callback)
end

local UvStreamReadable = Readable:extend()
function UvStreamReadable:initialize(handle)
  Readable.initialize(self, { highWaterMark = 0 })
  self._readableState.reading = false
  self.reading = false
  self.handle = handle
  self:on('pause', utils.bind(self._onPause, self))
end

function UvStreamReadable:_onPause()
  self._readableState.reading = false
  self.reading = false
  uv.read_stop(self.handle)
end

function UvStreamReadable:_read(n)
  local function onRead(err, data)
    if err then
      return self:emit('error', err)
    end
    self:push(data)
  end
  if not uv.is_active(self.handle) then
    self.reading = true
    uv.read_start(self.handle, onRead)
  end
end

local function globalProcess()
  local process = Emitter:new()
  process.argv = args
  process.exitCode = 0
  process.nextTick = nextTick
  process.env = lenv
  process.cwd = cwd
  process.kill = kill
  process.pid = uv.getpid()
  process.on = on
  process.exit = exit
  process.removeListener = removeListener
  process.stdin = UvStreamReadable:new(pp.stdin)
  process.stdout = UvStreamWritable:new(pp.stdout)
  process.stderr = UvStreamWritable:new(pp.stderr)
  hooks:on('process.exit', utils.bind(process.emit, process, 'exit'))
  return process
end

return { globalProcess = globalProcess }
