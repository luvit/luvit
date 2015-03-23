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

exports.name = "luvit/childprocess"
exports.version = "1.0.2"

local core = require('core')
local net = require('net')
local timer = require('timer')
local uv = require('uv')
local utils = require('utils')

local Error = core.Error

local Process = core.Emitter:extend()
function Process:initialize(stdin, stdout, stderr)
  self.stdout = stdout
  self.stdin = stdin
  self.stderr = stderr
end

function Process:setHandle(handle)
  self.handle = handle
end

function Process:setPid(pid)
  self.pid = pid
end

function Process:kill(signal)
  if self.handle then uv.process_kill(self.handle, signal or 'sigterm') end
  self:destroy()
end

function Process:close()
  if self.handle then uv.close(self.handle) end
  self:destroy()
end

function Process:destroy(err)
  self:_cleanup()
  if err then
    timer.setImmediate(utils.bind(self.emit, self, 'error', err))
  end
end

function Process:_cleanup()
  self.stdout:on('end', function() self.stdout:destroy() end)
  self.stdout:resume()
  self.stderr:destroy()
  self.stdin:destroy()
end

local function spawn(command, args, options)
  local envPairs = {}
  local em, onExit, handle, pid
  local stdout, stdin, stderr, stdio

  args = args or {}
  options = options or {}
  options.detached = options.detached or false

  if options.env then
    for k, v in pairs(options.env) do
      table.insert(envPairs, k .. '=' .. v)
    end
  end

  stdout = net.Socket:new({ handle = uv.new_pipe(false) })
  stderr = net.Socket:new({ handle = uv.new_pipe(false) })
  stdin = net.Socket:new({ handle = uv.new_pipe(false) })
  stdio = { stdin._handle, stdout._handle, stderr._handle}

  function onExit(code, signal)
    if signal then
       em.signal = signal
    else
       em.exitCode = code
    end
    em:emit('exit', code, signal)
    em:close()
  end

  handle, pid = uv.spawn(command, {
    stdio = stdio,
    args = args,
    env = envPairs,
    detached = options.detached,
  }, onExit)

  em = Process:new(stdin, stdout, stderr)
  em:setHandle(handle)
  em:setPid(pid)

  if em.handle == nil then
    process.nextTick(utils.bind(em.emit, em, 'exit', -127))
    em:destroy(Error:new(pid))
  end

  return em
end

exports.spawn = spawn
