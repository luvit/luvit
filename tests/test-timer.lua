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

require("helper")

local timer = require('timer')

expect("timeout")
timer.setTimeout(200, function (arg1)
  fulfill("timeout")
  assert(arg1 == 'test1')
end, "test1")

expect("interval")
local count = 0
local interval
interval = timer.setInterval(200, function(arg1)
  count = count + 1
  assert(arg1 == 'test2')
  if count == 2 then
    fulfill("interval")
    timer.clearTimer(interval)
  end
end, 'test2')

-- nextTick
local zeroTimeoutTriggered = false
timer.setTimeout(500, function()
  zeroTimeoutTriggered = true
end)

-- nextTick
local zeroTimeoutTriggered2 = false
timer.setTimeout(500, function()
  zeroTimeoutTriggered2 = true
end)

process:on('exit', function()
  assert(zeroTimeoutTriggered == true)
  assert(zeroTimeoutTriggered2 == true)
end)
