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

-- Helps us to avoid creating too many of the same object
local Object = require('object')

local FreeList = Object:extend()

function Freelist.prototype:initialize(name, max, factory)
  self.name = name
  self.max = max
  self.factory = factory
  self.list = {}
end

function Freelist.prototype:alloc(...)
  if 0 == #self.list then return self.factory:new(...) end
  return table.remove(self.list, 1)
end

function Freelist.prototype:free(object)
  if #self.list < self.max then table.insert(object) end
end
