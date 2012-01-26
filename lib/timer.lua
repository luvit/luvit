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
local UV = require('uv')
local Handle = require('handle')

local Timer = Handle:extend()

function Timer.prototype:initialize()
  self.userdata = UV.new_timer()
end

function Timer.prototype:start(timeout, interval, callback)
  return UV.timer_start(self.userdata, timeout, interval, callback)
end

function Timer.prototype:stop()
  return UV.timer_stop(self.userdata)
end

function Timer.prototype:again()
  return UV.timer_again(self.userdata)
end

function Timer.prototype:set_repeat(interval)
  return UV.timer_set_repeat(self.userdata, interval)
end

function Timer.prototype:get_repeat()
  return UV.timer_get_repeat(self.userdata)
end

function Timer:set_timeout(duration, callback, ...)
  local args = {...}
  local timer = Timer:new()
  timer:start(duration, 0, function (status)
    timer:close()
    callback(unpack(args))
  end)
  return timer
end

function Timer:set_interval(period, callback, ...)
  local args = {...}
  local timer = Timer:new()
  timer:start(period, period, function (status)
    callback(unpack(args))
  end)
  return timer
end

function Timer:clear_timer(timer)
  timer:stop()
  timer:close()
end

return Timer
