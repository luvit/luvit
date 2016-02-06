--[[

Copyright 2014-2015 The Luvit Authors. All Rights Reserved.

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

--[[lit-meta
  name = "luvit/los"
  version = "2.0.0"
  license = "Apache 2"
  homepage = "https://github.com/luvit/luvit/blob/master/deps/los.lua"
  description = "Tiny helper to get os name in luvit."
  tags = {"os"}
]]

local jit = require('jit')

local map = {
  ['Windows'] = 'win32',
  ['Linux'] = 'linux',
  ['OSX'] = 'darwin',
  ['BSD'] = 'bsd',
  ['POSIX'] = 'posix',
  ['Other'] = 'other'
}

local function type()
  return map[jit.os]
end

return { type = type }
