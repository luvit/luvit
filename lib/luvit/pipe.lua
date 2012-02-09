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

local pipe = {}

local Pipe = Stream:extend()
pipe.Pipe = Pipe

function Pipe:initialize(ipc)
  self.userdata = uv.newPipe(ipc and 1 or 0)
end

function Pipe:open(fd)
  return uv.pipeOpen(self.userdata, fd)
end

function Pipe:bind(name)
  return uv.pipeBind(self.userdata, name)
end

function Pipe:connect(name)
  return uv.pipeConnect(self.userdata, name)
end

return pipe

