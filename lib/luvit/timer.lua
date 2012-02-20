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

local Timer = require('uv').Timer

local timer = {}

function timer.setTimeout(duration, callback, ...)
  local args = {...}
  local timer = Timer:new()
  timer:start(duration, 0, function (status)
    timer:close()
    callback(unpack(args))
  end)
  return timer
end

function timer.setInterval(period, callback, ...)
  local args = {...}
  local timer = Timer:new()
  timer:start(period, period, function (status)
    callback(unpack(args))
  end)
  return timer
end

function timer.clearTimer(timer)
  timer:stop()
  timer:close()
end

return timer
