require("helper")

_G.num_loaded = 0
local m1 = require("module1")
local m1_m2 = require("module1/module2")
local m2_m2 = require("module2/module2")
local rm1 = require("./modules/module1")
local rm1_m2 = require("./modules/module1/module2")
local rm2_m2 = require("./modules/module2/module2")

p(m1, m1_m2, m2_m2)
p(rm1, rm1_m2, rm2_m2)
p({num_loaded=num_loaded})
assert(num_loaded == 3, "There should be exactly three modules loaded, there was " .. num_loaded)
assert(m1 == rm1 and m1_m2 == rm1_m2 and m2_m2 == rm2_m2, "Modules are not caching correctly")

-- Test native addons
local vectors = {
  require("vector"),
  require("vector-renamed"),
}
assert(vectors[1] == vectors[2], "Symlinks should realpath and load real module and reuse cache")

-- Test to make sure dashes are allowed and the same file is cached no matter how it's found
local libluvits = {
  require('lib-luvit'),
  require('./modules/lib-luvit'),
}
assert(libluvits[1] == libluvits[2], "Module search and relative should share same cache")

