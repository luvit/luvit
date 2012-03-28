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

local lists = {}

function insert(item, msecs, ...)
  local args = {...}

  item._idleStart = Timer.now()
  item._idleTimeout = msecs

  if msecs < 0 then return end

  local list
  if lists[msecs] then
    list = lists[msecs]
  else
    list = {}
    list.items = {}
    list.timer = Timer:new()
    lists[msecs] = list
    function expiration()
      local now = Timer.now()
      -- pull out the element from back to front, so we can remove elements safely
      for i=#list.items, 1, -1 do
        local elem = list.items[i]
        local diff = now - elem._idleStart;
        if ((diff + 1) < msecs) == true then
          list.timer:start(msecs - diff, 0, expiration)
          return
        else
          table.remove(list.items, i)
          if elem._onTimeout then
            elem._onTimeout()
          end
        end
      end

      if list.timer then
        list.timer:stop()
        list.timer:close()
        list.timer = nil
      end
      lists[msecs] = nil
    end
    list.timer:start(msecs, 0, expiration)
  end

  table.insert(list.items, item)
end

function unenroll(item)
  local list = lists[item._idleTimeout]
  if list and #list.items == 0 then
    -- empty list
    lists[item._idleTimeout] = nil
  end
  item._idleTimeout = -1
end

function enroll(item, msecs)
  if item._idleNext then
    unenroll(item)
  end
  item._idleTimeout = msecs
end

function active(item)
  local msecs = item._idleTimeout
  if msecs and msecs >= 0 then
    local list = lists[msecs]
    if not list or #list.items == 0 then
      insert(item, msecs)
    else
      item._idleStart = Timer.now()
    end
  end
end

function setTimeout(duration, callback, ...)
  local args = {...}
  local timer = {}
  timer._idleTimeout = duration
  timer._onTimeout = function()
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
