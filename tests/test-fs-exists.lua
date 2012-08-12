--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License")
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

require("helper")

local FS = require('fs')
local Path = require('path')

local f = __filename
local exists
local doesNotExist

-- TODO: Is it OK that this callback signature is different from node.js,
--       which is function(exists)?
FS.exists(f, function(err, y)
  exists = y
--  p("exists=" .. tostring(exists))
end)

FS.exists(f .. '-NO', function(err, y)
  doesNotExist = y
--  p("doesNotExist=" .. tostring(doesNotExist))
end)

assert(FS.existsSync(f))
assert(not FS.existsSync(f .. '-NO'))

process:on('exit', function()
  assert(exists == true)
  assert(doesNotExist == false)
end)
