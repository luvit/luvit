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
local Pipe = require('pipe')
local Handle = require('handle')

local Process = Handle:extend()

function Process.prototype:initialize(command, args, options)
  self.stdin = Pipe:new(0)
  self.stdout = Pipe:new(0)
  self.stderr = Pipe:new(0)
  args = args or {}
  options = options or {}

  self.userdata = UV.spawn(self.stdin, self.stdout, self.stderr, command, args, options)

  self.stdout:read_start()
  self.stderr:read_start()
  self.stdout:on('end', function ()
    self.stdout:close()
  end)
  self.stderr:on('end', function ()
    self.stderr:close()
  end)
  self:on('exit', function ()
    self.stdin:close()
    self:close()
  end)

end

function Process.prototype:kill(signal)
  return UV.process_kill(self.userdata, signal)
end

Process.spawn = Process.new

return Process

