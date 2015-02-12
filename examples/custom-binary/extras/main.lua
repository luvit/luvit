local luvi = require('luvi')
local bundle = luvi.bundle
-- Manually register the require replacement system to bootstrap things
bundle.register("require", "modules/require.lua");
-- Upgrade require system in-place
_G.require = require('require')()("bundle:modules/main.lua")

local luvit = require('luvit')
luvit.init()

print("Custom main with custom builtins!")
print("1 + 2", require("add")(1, 2))
print("3 - 2", require("multi")(3, 2))
p(process.argv)

luvit.run()

