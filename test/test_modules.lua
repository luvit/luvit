local m1 = require("module1")
local m1_m2 = require("module1/module2")
local m2_m2 = require("module2/module2")
local rm1 = require("./modules/module1")
local rm1_m2 = require("./modules/module1/module2")
local rm2_m2 = require("./modules/module2/module2")

p(m1, m1_m2, m2_m2)
p(rm1, rm1_m2, rm2_m2)
