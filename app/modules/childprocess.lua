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

local core = require('core')
local timer = require('timer')
local uv = require('uv')
local Readable = require('stream_readable').Readable
local Writable = require('stream_writable').Writable

local function spawn(command, args, options)
  local envPairs = {}, env, em, onCallback
  local stdout, stdin, stderr, stdio
  local onImmediate

  args = args or {}
  options = options or {}
  options.detached = options.detached or false

  if options.env then
    for k, v in pairs(options.env) do
      table.insert(envPairs, k .. '=' .. v)
    end
  end

  stdout = core.Stream:new(uv.new_pipe(false))
  stdin = core.Stream:new(uv.new_pipe(false))
  stderr = core.Stream:new(uv.new_pipe(false))

  stdio = { stdin.handle, stdout.handle, stderr.handle}

  em = core.Emitter:new()
  em.stdin = Writable:new():wrap(stdin)
  em.stdout = Readable:new():wrap(stdout)
  em.stderr = Readable:new():wrap(stderr)
  em.stdout:once('end', function()
    stdout:close()
  end)
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

    function onImmediate()
      em.stdout:resume() -- drain stdout
      stderr:close()
      stdin:close()
      em:emit('exit', code, signal)
    end

    uv.close(em.handle)
    timer.setImmediate(onImmediate)
  end)

  for _, v in pairs({stdin, stdout, stderr}) do
    v:readStart()
  end

  return em
end

exports.spawn = spawn
