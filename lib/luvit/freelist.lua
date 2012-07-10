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

local Object = require('core').Object
local table = require('table')

local Freelist = Object:extend()

function Freelist:initialize(name, max, factory)
  self.name = name
  self.factory = factory
  self.max = max
  self.list = {}
  self.length = 0
end

function Freelist:alloc(...)
  if 0 < self.length then
    self.length = self.length - 1
    return table.remove(self.list, 1)
  end

  return self.factory(...)
end

function Freelist:free(instance)
  if self.length < self.max then
    self.length = self.length + 1
    self.list[self.length] = instance
  end
end

return Freelist
