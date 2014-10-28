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

local os = require('os')

local timer = require('timer')
local math = require('math')

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
--
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

-- test cancelled timer
local cancelledTimerTriggered = false
local cancelledTimer = timer.setTimeout(10000, function()
  cancelledTimerTriggered = true
end)
timer.clearTimer(cancelledTimer)

-- test recursive timer
function calcJitter(n, jitter)
  return math.floor(n + (jitter * math.random()))
end

local counter = 0
local timeoutId1
local timeoutId2
local timeoutId3

-- Test two timers closing at the same time caused expiration() to call close on
-- the wrong timer

local function schedule()
    timeoutId2 = timer.setTimeout(200, function()
    end)

    timeoutId1 = timer.setTimeout(200, function()
        timer.clearTimer(timeoutId2)
        counter = counter + 1

        if counter < 4 then
            schedule()
        end
    end)
end

schedule()

local recursiveTimerCount = 0
local recursiveTime = 0
local st = 0
function start()
  local timeout = 2000
  st = os.time()
  return timer.setTimeout(timeout, function()
    recursiveTimerCount = recursiveTimerCount + 1
    recursiveTime = recursiveTime + os.time() - st
    if recursiveTimerCount < 3 then
      start()
    end
  end)
end
start()

process:on('exit', function()
  assert(zeroTimeoutTriggered == true)
  assert(zeroTimeoutTriggered2 == true)
  assert(cancelledTimerTriggered == false)
  assert(recursiveTimerCount == 3)
  assert(recursiveTime >= 6)
end)
