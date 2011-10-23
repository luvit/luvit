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
assert(num_loaded == 3, "There should be three modules loaded")
assert(m1 == rm1 and m1_m2 == rm1_m2 and m2_m2 == rm2_m2, "Modules are not caching correctly")
