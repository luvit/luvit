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

-- The base Class that provides the mini Luvit OOP system for Lua
local Object = {methods = {}}
Object.meta = {__index = Object.prototype}

-- Create a new instance of the class. Call the initializer if there is one.
function Object:new(...)
  if not self then error("Make sure to call :new(...) not .new(...)") end
  local object = setmetatable({}, self.meta)
  if object.initialize then
    object:initialize(...)
  end
  return object
end

-- Create a new subclass that inherits both Class methods and instance methods
function Object:extend()
  if not self then error("Make sure to call :extend() not .extend()") end
  child = setmetatable({}, {__index = self})
  child.prototype = setmetatable({}, {__index = self.prototype})
  child.meta = {__index = child.prototype}
  return child
end

return Object

-- Sample Usage.
--[[
p("Object", Object)

Rectangle = Object:extend()
function Rectangle.prototype:initialize(w, h)
  self.w = w
  self.h = h
end

function Rectangle.prototype:area()
  return self.w * self.h
end

p("Rectangle", Rectangle)
rect = Rectangle:new(2, 3)
p("rect", rect)
Square = Rectangle:extend()
function Square.prototype:initialize(w)
  self.w = w
  self.h = w
end
p("Square", Square)
square = Square:new(5)
p("square", square)
p("square:area()", square:area())

]]
