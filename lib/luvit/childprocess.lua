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
local uv = require('uv')
local Pipe = require('pipe').Pipe
local Handle = require('core').Handle
local table = require('table')

local process = {}

local Process = Handle:extend()
process.Process = Process

function Process:initialize(command, args, options)
  self.stdin = Pipe:new(0)
  self.stdout = Pipe:new(0)
  self.stderr = Pipe:new(0)
  args = args or {}
  options = options or {}

  self.userdata = uv.spawn(self.stdin, self.stdout, self.stderr, command, args, options)

  self.stdout:readStart()
  self.stderr:readStart()
  self.stdout:on('end', function ()
    self.stdout:close()
  end)
  self.stderr:on('end', function ()
    self.stderr:close()
  end)
  self:on('exit', function ()
    self.stdin:close()
    self:close()
  end)

end

function Process:kill(signal)
  return uv.processKill(self.userdata, signal)
end

function process.spawn(command, args, options)
  return Process:new(command, args, options)
end

function process.execFile(command, args, options, callback)
  local child = process.spawn(command, args, options)
  local stdout = {}
  local stderr = {}
  child.stdout:on('data', function (chunk)
    table.insert(stdout, chunk)
  end)
  child.stderr:on('data', function (chunk)
    table.insert(stderr, chunk)
  end)
  child:on('error', callback)
  child:on('exit', function (code, signal)
    callback(nil, table.concat(stdout, ""), table.concat(stderr, ""));
  end)
end

return process

