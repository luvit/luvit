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
local uv = require('uv')
local Emitter = require('emitter')


local Handle = Emitter:extend()

function Handle.prototype:close()
  --_oldprint("Handle.prototype:close")
  if not self.userdata then error("Can't call :close() on non-userdata objects") end
  return uv.close(self.userdata)
end

function Handle.prototype:addHandlerType(name)
  --_oldprint("Handle.prototype:addHandlerType")
  if not self.userdata then return end
  self:setHandler(name, function (...)
    self:emit(name, ...)
  end)
end


function Handle.prototype:setHandler(name, callback)
  --_oldprint("Handle.prototype:setHandler")
  if not self.userdata then error("Can't call :setHandler() on non-userdata objects") end
  return uv.setHandler(self.userdata, name, callback)
end

return Handle
