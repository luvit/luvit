require("helper")

local Path = require('path')

-- test `Path.dirname`
assert(Path.dirname('/usr/bin/vim') == '/usr/bin')
assert(Path.dirname('/usr/bin/') == '/usr')
assert(Path.dirname('/usr/bin') == '/usr')

