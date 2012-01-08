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

local function set_timeout(duration, callback, ...)
  local args = {...}
  local timer = UV.new_timer()
  timer:start(duration, 0, function (status)
    timer:close()
    callback(unpack(args))
  end)
  return timer
end

local function set_interval(period, callback, ...)
  local args = {...}
  local timer = UV.new_timer()
  timer:start(period, period, function (status)
    callback(unpack(args))
  end)
  return timer
end

local function clear_timer(timer)
  timer:stop()
  timer:close()
end

return {
  new = UV.new_timer,
  set_timeout = set_timeout,
  set_interval = set_interval,
  clear_timer = clear_timer,
}
