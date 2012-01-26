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

local Pipe = Stream:extend()

function Pipe.prototype:initialize(ipc)
  --_oldprint("Pipe.prototype:initialize")
  self.userdata = UV.new_pipe(ipc and 1 or 0)
end

function Pipe.prototype:open(fd)
  --_oldprint("Pipe.prototype:open")
  return UV.pipe_open(self.userdata, fd)
end

function Pipe.prototype:bind(name)
  --_oldprint("Pipe.prototype:bind")
  return UV.pipe_bind(self.userdata, name)
end

function Pipe.prototype:connect(name)
  --_oldprint("Pipe.prototype:connect")
  return UV.pipe_connect(self.userdata, name)
end

return Pipe

