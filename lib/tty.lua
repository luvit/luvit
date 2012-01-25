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
local Stream = require('stream')

local TTY = Stream:extend()

function TTY.prototype:initialize(fd, readable)
  _oldprint("TTY.prototype:initialize")
  self.userdata = UV.new_tty(fd, readable)
end

function TTY.prototype:set_mode(mode)
  _oldprint("TTY.prototype:set_mode")
  return UV.tty_set_mode(self.userdata, mode)
end

function TTY:reset_mode()
  _oldprint("TTY.reset_mode")
  return UV.tty_reset_mode()
end

function TTY.prototype:get_winsize()
  _oldprint("TTY.prototype:get_winsize")
  return UV.tty_get_winsize(self.userdata)
end

return TTY
