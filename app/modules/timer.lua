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
local uv = require('uv')
local bind = require('utils').bind

function exports.setTimeout(delay, callback, ...)
  local timer = uv.new_timer()
  local args = {...}
  uv.timer_start(timer, delay, 0, function ()
    uv.timer_stop(timer)
    uv.close(timer)
    callback(unpack(args))
  end)
  return timer
end

function exports.setInterval(interval, callback, ...)
  local timer = uv.new_timer()
  uv.timer_start(timer, interval, interval, bind(callback, ...))
  return timer
end

function exports.clearInterval(timer)
  uv.timer_stop(timer)
  uv.close(timer)
end

exports.clearTimeout = exports.clearInterval

local checker = uv.new_check()
local idler = uv.new_idle()
local immediateQueue = {}

local function onCheck()
  local queue = immediateQueue
  immediateQueue = {}
  for i = 1, #queue do
    queue[i]()
  end
  -- If the queue is still empty, we processed them all
  -- Turn the check hooks back off.
  if #immediateQueue == 0 then
    uv.check_stop(checker)
    uv.idle_stop(idler)
  end
end

function exports.setImmediate(callback, ...)

  -- If the queue was empty, the check hooks were disabled.
  -- Turn them back on.
  if #immediateQueue == 0 then
    uv.check_start(checker, onCheck)
    uv.idle_start(idler, onCheck)
  end

  immediateQueue[#immediateQueue + 1] = bind(callback, ...)

end
