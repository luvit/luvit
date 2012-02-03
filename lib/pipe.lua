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
local Stream = require('stream')

local pipe = Stream:extend()

function pipe.prototype:initialize(ipc)
  --_oldprint("pipe.prototype:initialize")
  self.userdata = uv.newPipe(ipc and 1 or 0)
end

function pipe.prototype:open(fd)
  --_oldprint("pipe.prototype:open")
  return uv.pipeOpen(self.userdata, fd)
end

function pipe.prototype:bind(name)
  --_oldprint("pipe.prototype:bind")
  return uv.pipeBind(self.userdata, name)
end

function pipe.prototype:connect(name)
  --_oldprint("pipe.prototype:connect")
  return uv.pipeConnect(self.userdata, name)
end

return pipe

