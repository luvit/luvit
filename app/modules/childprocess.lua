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

local net = require('net')
local core = require('core')
local timer = require('timer')
local uv = require('uv')
local Readable = require('stream_readable').Readable
local Writable = require('stream_writable').Writable

local function spawn(command, args, options)
  local envPairs = {}, env, em, onCallback
  local stdout, stdin, stderr, stdio
  local onImmediate, kill, cleanup

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

  function kill(self, signal)
    uv.process_kill(em.handle, signal or 'sigterm')
    cleanup()
  end

  function cleanup()
    if em.handle then uv.close(em.handle) ; em.handle = nil end
    em.stdout:on('end', function()
      em.stdout:destroy()
    end)
    em.stdout:resume() -- drain stdout
    stderr:destroy()
    stdin:destroy()
  end

  em = core.Emitter:new()
  em.kill = kill
  em.stdin = stdin
  em.stdout = stdout
  em.stderr = stderr
  em.handle, em.pid = uv.spawn(command, {
    stdio = stdio,
    args = args,
    env = envPairs,
    detached = options.detached,
  }, function(code, signal)

    if signal then
       em.signal = signal
    else
       em.exitCode = code
    end

    cleanup()
    em:emit('exit', code, signal)
  end)

  return em
end

exports.spawn = spawn
