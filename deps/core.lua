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

--[[
This module is for various classes and utilities that don't need their own
module.
]]
--[[lit-meta
  name = "luvit/core"
  version = "2.0.0"
  license = "Apache 2"
  homepage = "https://github.com/luvit/luvit/blob/master/deps/core.lua"
  description = "Core object model for luvit using simple prototypes and inheritance."
  tags = {"luvit", "objects", "inheritance"}
]]
local core = {}


--[[
Returns whether obj is instance of class or not.

    local object = Object:new()
    local emitter = Emitter:new()

    assert(instanceof(object, Object))
    assert(not instanceof(object, Emitter))

    assert(instanceof(emitter, Object))
    assert(instanceof(emitter, Emitter))

    assert(not instanceof(2, Object))
    assert(not instanceof('a', Object))
    assert(not instanceof({}, Object))
    assert(not instanceof(function() end, Object))

Caveats: This function returns true for classes.
    assert(instanceof(Object, Object))
    assert(instanceof(Emitter, Object))
]]
function core.instanceof(obj, class)
  if type(obj) ~= 'table' or obj.meta == nil or not class then
    return false
  end
  if obj.meta.__index == class then
    return true
  end
  local meta = obj.meta
  while meta do
    if meta.super == class then
      return true
    elseif meta.super == nil then
      return false
    end
    meta = meta.super.meta
  end
  return false
end

--------------------------------------------------------------------------------

--[[
This is the most basic object in Luvit. It provides simple prototypal
inheritance and inheritable constructors. All other objects inherit from this.
]]
local Object = {}
core.Object = Object
Object.meta = {__index = Object}

-- Create a new instance of this object
function Object:create()
  local meta = rawget(self, "meta")
  if not meta then error("Cannot inherit from instance object") end
  return setmetatable({}, meta)
end

--[[
Creates a new instance and calls `obj:initialize(...)` if it exists.

    local Rectangle = Object:extend()
    function Rectangle:initialize(w, h)
      self.w = w
      self.h = h
    end
    function Rectangle:getArea()
      return self.w * self.h
    end
    local rect = Rectangle:new(3, 4)
    p(rect:getArea())
]]
function Object:new(...)
  local obj = self:create()
  if type(obj.initialize) == "function" then
    obj:initialize(...)
  end
  return obj
end

--[[
Creates a new sub-class.

    local Square = Rectangle:extend()
    function Square:initialize(w)
      self.w = w
      self.h = h
    end
]]

function Object:extend()
  local obj = self:create()
  local meta = {}
  -- move the meta methods defined in our ancestors meta into our own
  --to preserve expected behavior in children (like __tostring, __add, etc)
  for k, v in pairs(self.meta) do
    meta[k] = v
  end
  meta.__index = obj
  meta.super=self
  obj.meta = meta
  return obj
end

--------------------------------------------------------------------------------

--[[
This class can be used directly whenever an event emitter is needed.

    local emitter = Emitter:new()
    emitter:on('foo', p)
    emitter:emit('foo', 1, 2, 3)

Also it can easily be sub-classed.

    local Custom = Emitter:extend()
    local c = Custom:new()
    c:on('bar', onBar)

Unlike EventEmitter in node.js, Emitter class doesn't auto binds `self`
reference. This means, if a callback handler is expecting a `self` reference,
utils.bind() should be used, and the callback handler should have a `self` at
the beginning its parameter list.

    function some_func(self, a, b, c)
    end
    emitter:on('end', utils.bind(some_func, emitter))
    emitter:emit('end', 'a', 'b', 'c')
]]
local Emitter = Object:extend()
core.Emitter = Emitter

-- By default, any error events that are not listened for should throw errors
function Emitter:missingHandlerType(name, ...)
  if name == "error" then
    --error(tostring(args[1]))
    -- we define catchall error handler
    if self ~= process then
      -- if process has an error handler
      local handlers = rawget(process, "handlers")
      if handlers and handlers["error"] then
        -- delegate to process error handler
        process:emit("error", ..., self)
      end
    end
  end
end

local onceMeta = {}
function onceMeta:__call(...)
  self.emitter:removeListener(self.name, self)
  return self.callback(...)
end

-- Same as `Emitter:on` except it de-registers itself after the first event.
function Emitter:once(name, callback)
  return self:on(name, setmetatable({
    emitter = self,
    name = name,
    callback = callback
  }, onceMeta))
end

-- Adds an event listener (`callback`) for the named event `name`.
function Emitter:on(name, callback)
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
  table.insert(handlers_for_type, callback)
  return self
end

function Emitter:listenerCount(name)
  local handlers = rawget(self, "handlers")
  if not handlers then
    return 0
  end

  handlers = rawget(handlers, name)
  return handlers and #handlers or 0
end

-- Emit a named event to all listeners with optional data argument(s).
function Emitter:emit(name, ...)
  local handlers = rawget(self, "handlers")
  if not handlers then
    self:missingHandlerType(name, ...)
    return
  end

  handlers = rawget(handlers, name)
  if handlers then
    local _ = {}
    for i=1, #handlers do
      _[i] = handlers[i]
    end
    for i=1, #_ do
      if _[i] then _[i](...) end
    end
  else
    self:missingHandlerType(name, ...)
    return
  end

  return self
end

-- Remove a listener so that it no longer catches events.
function Emitter:removeListener(name, callback)
  local handlers = rawget(self, "handlers")
  if not handlers then return end

  if not name then
    rawset(self, "handlers", {})
    return
  end

  if callback then
    handlers = rawget(handlers, name)
    if not handlers then return end

    for i = #handlers, 1, -1 do
      local h = handlers[i]
      if type(callback) == "table" then
        -- only remove once callback table
        h = type(h) == 'table' and h == callback or false
      elseif type(callback) == "function" then
        -- remove once callback table or other callback function
        h = type(h) == 'table' and h.callback == callback or h == callback
      end
      if h then
        table.remove(handlers,i)
      end
    end
  else
    handlers = rawget(handlers, name)
    if not handlers then return end
    for i=#handlers, 1, -1 do
      rawset(handlers, i, nil)
    end
  end
end

-- Remove all listeners
--  @param {String?} name optional event name
function Emitter:removeAllListeners(name)
  self:removeListener(name)
end

-- Get listeners
--  @param {String} name event name
function Emitter:listeners(name)
  local handlers = rawget(self, "handlers")
  return handlers and (rawget(handlers, name) or {}) or {}
end

--[[
Utility that binds the named method `self[name]` for use as a callback.  The
first argument (`err`) is re-routed to the "error" event instead.

    local Joystick = Emitter:extend()
    function Joystick:initialize(device)
      self:wrap("onOpen")
      FS.open(device, self.onOpen)
    end

    function Joystick:onOpen(fd)
      -- and so forth
    end
]]
function Emitter:wrap(name)
  local fn = self[name]
  self[name] = function (err, ...)
    if (err) then return self:emit("error", err) end
    return fn(self, ...)
  end
end

-- Propagate the event to another emitter.
function Emitter:propagate(eventName, target)
  if (target and target.emit) then
    self:on(eventName, function (...) target:emit(eventName, ...) end)
    return target
  end

  return self
end

--------------------------------------------------------------------------------

-- This is for code that wants structured error messages.
local Error = Object:extend()
core.Error = Error

-- Make errors tostringable
function Error.meta.__tostring(table)
  return table.message
end

function Error:initialize(message)
  self.message = message
  if message then
    self.code = tonumber(message:match('([^:]+): '))
  end
end

--------------------------------------------------------------------------------

return core
