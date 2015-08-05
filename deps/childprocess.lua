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
exports.version = "1.0.8-1"
exports.dependencies = {
  "luvit/core@1.0.5",
  "luvit/net@1.2.0",
  "luvit/timer@1.0.0",
}
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/childprocess.lua"
exports.description = "A port of node.js's childprocess module for luvit."
exports.tags = {"luvit", "spawn", "process"}

local core = require('core')
local net = require('net')
local timer = require('timer')
local uv = require('uv')

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
  if self.handle and not uv.is_closing(self.handle) then uv.process_kill(self.handle, signal or 'sigterm') end
end

function Process:close(err)
  if self.handle and not uv.is_closing(self.handle) then uv.close(self.handle) end
  self:destroy(err)
end

function Process:destroy(err)
  self:_cleanup(err)
  if err then
    timer.setImmediate(function() self:emit('error', err) end)
  end
end

function Process:_cleanup(err)
  timer.setImmediate(function()
    if self.stdout then
      self.stdout:_end(err) -- flush
      self.stdout:destroy(err) -- flush
    end
    if self.stderr then self.stderr:destroy(err) end
    if self.stdin then self.stdin:destroy(err) end
  end)
end

local function spawn(command, args, options)
  local envPairs = {}
  local em, onExit, handle, pid
  local stdout, stdin, stderr, stdio, closesGot

  args = args or {}
  options = options or {}
  options.detached = options.detached or false

  if options.env then
    for k, v in pairs(options.env) do
      table.insert(envPairs, k .. '=' .. v)
    end
  end

  local function maybeClose()
    closesGot = closesGot - 1
    if closesGot == 0 then
      em:emit('close', em.exitCode, em.signal)
    end
  end

  local function countStdio(stdio)
    local count = 0
    if stdio[1] then count = count + 1 end
    if stdio[2] then count = count + 1 end
    if stdio[3] then count = count + 1 end
    return count + 1 -- for exit call
  end

  if options.stdio then
    stdio = {}
    stdin = options.stdio[1]
    stdout = options.stdio[2]
    stderr = options.stdio[3]
    stdio[1] = options.stdio[1] and options.stdio[1]._handle
    stdio[2] = options.stdio[2] and options.stdio[2]._handle
    stdio[3] = options.stdio[3] and options.stdio[3]._handle
    if stdio[1] then options.stdio[1]:once('close', maybeClose) end
    if stdio[2] then options.stdio[2]:once('close', maybeClose) end
    if stdio[3] then options.stdio[3]:once('close', maybeClose) end
    closesGot = countStdio(stdio)
  else
    stdin = net.Socket:new({ handle = uv.new_pipe(false) })
    stdout = net.Socket:new({ handle = uv.new_pipe(false) })
    stderr = net.Socket:new({ handle = uv.new_pipe(false) })
    stdio = { stdin._handle, stdout._handle, stderr._handle}
    stdin:once('close', maybeClose)
    stdout:once('close', maybeClose)
    stderr:once('close', maybeClose)
    closesGot = countStdio(stdio)
  end

  function onExit(code, signal)
    em.exitCode = code
    em.signal = signal
    em:emit('exit', code, signal)
    maybeClose()
    em:close()
  end

  handle, pid = uv.spawn(command, {
    cwd = options.cwd or nil,
    stdio = stdio,
    args = args,
    env = envPairs,
    detached = options.detached,
    uid = options.uid,
    gid = options.gid
  }, onExit)

  em = Process:new(stdin, stdout, stderr)
  em:setHandle(handle)
  em:setPid(pid)

  if not em.handle then
    timer.setImmediate(function()
      em.exitCode = -127
      em:emit('exit', em.exitCode)
      em:destroy(Error:new(pid))
      maybeClose()
    end)
  end

  return em
end

exports.spawn = spawn
