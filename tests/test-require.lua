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

require("helper")
local path = require("path")

_G.num_loaded = 0
local m1 = require("module1")
local m1_m2 = require("module1/module2")
local m1_m2 = require("module1/module2")
local m1_m2 = require("module1/module2")
local m2_m2 = require("module2/module2")
local rm1 = require("./modules/module1")
local rm1_m2 = require("./modules/module1/module2")
local rm2_m2 = require("./modules/module2/module2")
local rm1sm1_m2 = require("./modules/module1/../module1/module2")
local rm2sm2_m2 = require("./modules/module2/../module2/module2")

printStderr("require: " .. tostring(require))

p(m1, m1_m2, m2_m2)
p(rm1, rm1_m2, rm2_m2, rm1sm1_m2, rm2sm2_m2)
p({num_loaded=num_loaded})
assert(num_loaded == 3, "There should be exactly three modules loaded, there was " .. num_loaded)
assert(m1 == rm1 and m1_m2 == rm1_m2 and m2_m2 == rm2_m2, "Modules are not caching correctly")

-- Test native addons
--[[
local vectors = {
  require("vector"),
  require("vector-renamed"),
}
assert(vectors[1] == vectors[2], "Symlinks should realpath and load real module and reuse cache")
]]

-- Test to make sure dashes are allowed and the same file is cached no matter how it's found
local libluvits = {
  require('lib-luvit'),
  require('./modules/lib-luvit'),
}
assert(libluvits[1] == libluvits[2], "Module search and relative should share same cache")

