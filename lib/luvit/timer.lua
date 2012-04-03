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
local os = require('os')
local table = require('table')

local TIMEOUT_MAX = 2147483647

local lists = {}

local expiration
expiration = function(msecs)
  return function()
    local now = Timer.now()
    -- pull out the element from back to front, so we can remove elements safely
    for i=#lists[msecs].items, 1, -1 do
      local elem = lists[msecs].items[i]
      local diff = now - elem._idleStart;
      p('diff = ' .. diff)
      p('msecs = ' .. msecs)
      if ((diff + 1) < msecs) == true then
        p('in timer.start')
        lists[msecs].timer:start(msecs - diff, 0, expiration)
        return
      else
        table.remove(lists[msecs].items, i)
        if elem._onTimeout then
          elem._onTimeout()
        end
      end
    end

    p(msecs .. ' list empty')
    lists[msecs].timer:close()
    lists[msecs] = nil
  end
end


function _insert(item, msecs)
  item._idleStart = Timer.now()
  item._idleTimeout = msecs

  if msecs < 0 then return end

  if not lists[msecs] then
    local list = {}
    list.items = { item }
    list.timer = Timer:new()
    lists[msecs] = list
    list.timer:start(msecs, 0, expiration(msecs))
  else
    table.insert(lists[msecs].items, item)
  end
end

function unenroll(item)
  local list = lists[item._idleTimeout]
  if list and #list.items == 0 then
    -- empty list
    lists[item._idleTimeout] = nil
  end
  item._idleTimeout = -1
end

-- does not start the timer, just initializes the item
function enroll(item, msecs)
  if item._idleNext then
    unenroll(item)
  end
  item._idleTimeout = msecs
end

-- call this whenever the item is active (not idle)
function active(item)
  local msecs = item._idleTimeout
  if msecs >= 0 then
    if not lists[msecs] then
      p('_insert')
      _insert(item, msecs)
    else
      p('_append')
      item._idleStart = Timer.now()
      table.insert(lists[msecs].items, item)
      p(lists[msecs].items)
    end
  end
end

function setTimeout(duration, callback, ...)
  local args = {...}

  if duration < 1 or duration > TIMEOUT_MAX then
    duration = 1
  end

  local timer = {}
  timer._idleTimeout = duration
  timer._idleNext = timer
  timer._idlePrev = timer
  timer._onTimeout = function()
    p('_onTimeout')
    callback(unpack(args))
  end
  active(timer)
  return timer
end

function setInterval(period, callback, ...)
  local args = {...}
  local timer = Timer:new()
  timer:start(period, period, function (status)
    callback(unpack(args))
  end)
  return timer
end

function clearTimer(timer)
  timer._onTimeout = nil
  timer:close()
end

local exports = {}
exports.setTimeout = setTimeout
exports.setInterval = setInterval
exports.clearTimer = clearTimer
exports.unenroll = unenroll
exports.enroll = enroll
exports.active = active
return exports
