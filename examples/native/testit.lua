-- Load our native module
local TopCube = require('./topcube')

-- Show it's a normal lua table
p({TopCube=TopCube})

-- Call a function in the library
TopCube.create_window("http://github.com/creationix/luvit", 1024, 768)

