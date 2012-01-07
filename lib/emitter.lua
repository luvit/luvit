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

local Constants = require('constants')

local emitter_prototype = {}

-- By default, and error events that are not listened for should thow errors
function emitter_prototype:missing_handler_type(name, ...)
  if name == "error" then
    error(...)
  end
end

-- Sugar for emitters you want to auto-remove themself after first event
function emitter_prototype:once(name, callback)
  local function wrapped(...)
    self:remove_listener(name, wrapped)
    callback(...)
  end
  self:on(name, wrapped)
end

-- Add a new typed event emitter
function emitter_prototype:on(name, callback)
  local handlers = rawget(self, "handlers")
  if not handlers then
    handlers = {}
    rawset(self, "handlers", handlers)
  end
  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then
    if self.add_handler_type then
      self:add_handler_type(name)
    end
    handlers_for_type = {}
    rawset(handlers, name, handlers_for_type)
  end
  handlers_for_type[callback] = true
end

function emitter_prototype:emit(name, ...)
  local handlers = rawget(self, "handlers")
  if not handlers then
    self:missing_handler_type(name, ...)
    return
  end
  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then
    self:missing_handler_type(name, ...)
    return
  end
  for k, v in pairs(handlers_for_type) do
    k(...)
  end
end

function emitter_prototype:remove_listener(name, callback)
  local handlers = rawget(self, "handlers")
  if not handlers then return end
  local handlers_for_type = rawget(handlers, name)
  if not handlers_for_type then return end
  handlers_for_type[callback] = nil
end

local emitter_meta = {__index=emitter_prototype}

local function new()
  return setmetatable({}, emitter_meta)
end

return {
  new = new,
  prototype = emitter_prototype,
  meta = emitter_meta
}
