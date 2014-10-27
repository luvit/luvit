local ffi = require('ffi')
local utils = require('utils')
local dump = utils.dump
local p = utils.prettyPrint

utils.loadColors(256)
print("256 utils")
p(utils)

utils.loadColors(16)
print("16 utils")
p(utils)

utils.loadColors()
print("no-color")
p(utils)
p(dump(utils))

utils.loadColors(256)

p{"This is \n\r\t cool \0 right?"}
p{1, 2, true, false, nil, "Hello"}

local str = ""
for i = 0, 127 do
  str = str .. string.char(i)
end

p(str)

ffi.cdef[[
typedef struct { uint8_t red, green, blue, alpha; } rgba_pixel;
]]
local img = ffi.new("rgba_pixel[?]", 9)
p{utils.stdout, img, p}

local tim = {name="Tim", age=32}
local jack = {name="Jack", age=8}
p{
  {1,2,3,4},
  {1,2,3,g=5,6,z=2, [10]=10},
}
p{
  [tim] = "programmer",
  [jack] = "player",
}
p{
  programmer = tim,
  player = jack,
}

local cycle = {a="table"}
cycle.self = cycle
p(cycle)
