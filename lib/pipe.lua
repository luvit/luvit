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
local user_meta = require('utils').user_meta
local stream_meta = require('stream').meta
local PIPE = {}

local pipe_prototype = {}
setmetatable(pipe_prototype, stream_meta)
PIPE.prototype = pipe_prototype

function PIPE.new(ipc)
  local pipe = {
    userdata = UV.new_pipe(ipc and 1 or 0),
    prototype = pipe_prototype
  }
  setmetatable(pipe, user_meta)
  return pipe
end

return PIPE

