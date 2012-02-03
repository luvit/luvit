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

local Object = require('object')
local Table = require('table')

local Emitter = Object:extend()

-- By default, and error events that are not listened for should thow errors
function Emitter.prototype:missingHandlerType(name, ...)
  --_oldprint("Emitter.prototype:missingHandlerType")
  if name == "error" then
    local args = {...}
    error(tostring(args[1]))
  end
end

-- Sugar for emitters you want to auto-remove themself after first event
function Emitter.prototype:once(name, callback)
  --_oldprint("Emitter.prototype:once")
  local function wrapped(...)
    self:removeListener(name, wrapped)
    callback(...)
  end
  self:on(name, wrapped)
end

-- Add a new typed event emitter
function Emitter.prototype:on(name, callback)
  --_oldprint("Emitter.prototype:on")
  local handlers = rawget(self, "handlers")
  if not handlers then
    handlers = {}
    rawset(self, "handlers", handlers)
  end
  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then
    if self.addHandlerType then
      self:addHandlerType(name)
    end
    handlers_for_type = {}
    rawset(handlers, name, handlers_for_type)
  end
  Table.insert(handlers_for_type, callback)
end

function Emitter.prototype:emit(name, ...)
  --_oldprint("Emitter.prototype:emit")
  local handlers = rawget(self, "handlers")
  if not handlers then
    self:missingHandlerType(name, ...)
    return
  end
  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then
    self:missingHandlerType(name, ...)
    return
  end
  for i, callback in ipairs(handlers_for_type) do
    callback(...)
  end
  for i = #handlers_for_type, 1, -1 do
    if not handlers_for_type[i] then
      Table.remove(handlers_for_type, i)
    end
  end

end

function Emitter.prototype:removeListener(name, callback)
  --_oldprint("Emitter.prototype:removeListener")
  local handlers = rawget(self, "handlers")
  if not handlers then return end
  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then return end
  for i = 1, #handlers_for_type do
    if handlers_for_type[i] == callback then
      handlers_for_type[i] = nil
    end
  end
end

-- Register a bound version of a method and route errors
function Emitter.prototype:wrap(name)
  local fn = self[name]
  self[name] = function (err, ...)
    if (err) then return self:emit("error", err) end
    return fn(self, ...)
  end
end

return Emitter

