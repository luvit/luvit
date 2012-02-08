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
local Stream = require('core').Stream

local tty = {}

local Tty = Stream:extend()
tty.Tty = Tty

function Tty:initialize(fd, readable)
  --_oldprint("Tty:initialize")
  self.userdata = uv.newTty(fd, readable)
end

function Tty:setMode(mode)
  --_oldprint("Tty:setMode")
  return uv.ttySetMode(self.userdata, mode)
end

function Tty:getWinsize()
  --_oldprint("Tty:getWinsize")
  return uv.ttyGetWinsize(self.userdata)
end

function tty.resetMode()
  --_oldprint("Tty.resetMode")
  return uv.ttyResetMode()
end

return tty
