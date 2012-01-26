-- Load our native module
local Vector = require('./vector')

p(Vector)

local v = Vector:new(20, 10)

p({x=v.x,y=v.y,angle=v.angle})

