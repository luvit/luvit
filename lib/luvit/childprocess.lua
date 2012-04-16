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
local Process = require('uv').Process
local table = require('table')

local childProcess = {}

function childProcess.spawn(command, args, options)
  local env
  local envPairs = {}
  options = options or {}
  args = args or {}
  if options and options.env then
    env = options.env
  else
    env = process.env
  end

  for k, v in pairs(env) do
    table.insert(envPairs, k .. '=' .. v)
  end

  options.envPairs = envPairs

  return Process:new(command, args, options)
end

function childProcess.execFile(command, args, options, callback)
  local child = childProcess.spawn(command, args, options)
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

return childProcess

