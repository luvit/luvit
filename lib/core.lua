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
local table = require('table')

--[[
This module is for various classes and utilities that don't need their own
module.
]]
local core = {}

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
  obj.meta = {__index = obj}
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
]]
local Emitter = Object:extend()
core.Emitter = Emitter

-- By default, and error events that are not listened for should thow errors
function Emitter:missingHandlerType(name, ...)
  if name == "error" then
    local args = {...}
    error(tostring(args[1]))
  end
end

-- Same as `Emitter:on` except it de-registers itself after the first event.
function Emitter:once(name, callback)
  local function wrapped(...)
    self:removeListener(name, wrapped)
    callback(...)
  end
  self:on(name, wrapped)
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
end

-- Emit a named event to all listeners with optional data argument(s).
function Emitter:emit(name, ...)
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
      table.remove(handlers_for_type, i)
    end
  end

end

-- Remove a listener so that it no longer catches events.
function Emitter:removeListener(name, callback)
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

--------------------------------------------------------------------------------

--[[
This class is never used directly, but is the inheritance chain of all libuv
objects.
]]
local Handle = Emitter:extend()
core.Handle = Handle

-- Wrapper around `uv_close`. Closes the underlying file descriptor of a handle.
function Handle:close()
  if not self.userdata then error("Can't call :close() on non-userdata objects") end
  return UV.close(self.userdata)
end

--[[
This is used by Emitters to register with native events when the first listener
is added.
]]
function Handle:addHandlerType(name)
  if not self.userdata then return end
  self:setHandler(name, function (...)
    self:emit(name, ...)
  end)
end

--[[
Set or replace the handler for a native event.  Usually `Emitter:on()` is what
you want, not this.
]]
function Handle:setHandler(name, callback)
  if not self.userdata then error("Can't call :setHandler() on non-userdata objects") end
  return UV.setHandler(self.userdata, name, callback)
end

--------------------------------------------------------------------------------

--[[
This is never used directly.  If you want to create a pure Lua stream, subclass
or instantiate `core.iStream`.
]]
local Stream = Handle:extend()
core.Stream = Stream

function Stream:shutdown(callback)
  return UV.shutdown(self.userdata, callback)
end

function Stream:listen(callback)
  return UV.listen(self.userdata, callback)
end


function Stream:accept(other_stream)
  return UV.accept(self.userdata, other_stream)
end

function Stream:readStart()
  return UV.readStart(self.userdata)
end

function Stream:readStop()
  return UV.readStop(self.userdata)
end

function Stream:write(chunk, callback)
  return UV.write(self.userdata, chunk, callback)
end

function Stream:pipe(target)
  self:on('data', function (chunk, len)
    target:write(chunk)
  end)
  self:on('end', function ()
    target:close()
  end)
end

--------------------------------------------------------------------------------

--[[
This is an abstract interface that works like `core.Stream` but doesn't actually
contain a uv struct (it's pure lua)
]]
local iStream = Emitter:extend()
core.iStream = iStream

--TODO: Implement this

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
end

--------------------------------------------------------------------------------

return core

