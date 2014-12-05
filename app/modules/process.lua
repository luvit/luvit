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

local timer = require('timer')
local utils = require('utils')
local hooks = require('hooks')
local Emitter = require('core').Emitter

local function nextTick(...)
  timer.setImmediate(...)
end

local function globalProcess()
  local process = Emitter:new()
  process.exitCode = 0
  process.nextTick = nextTick
  hooks:on('process.exit', utils.bind(process.emit, process, 'exit'))
  return process
end
exports.globalProcess = globalProcess
