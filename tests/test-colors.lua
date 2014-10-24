local ffi = require("ffi")
local colors = require('colors')
colors.initialize("256")
local p = colors.prettyPrint
p("colors", colors)
p("This is \n\r\t cool \0 right?")
p(1, 2, true, false, nil, "Hello")

local str = ""
for i = 0, 127 do
  str = str .. string.char(i)
end

p(str)

p(colors.stdout)

ffi.cdef[[
typedef struct { uint8_t red, green, blue, alpha; } rgba_pixel;
]]
local img = ffi.new("rgba_pixel[?]", 9)
p(img, p)

p({1,2,3,4})

p({1,2,3,g=5,6,z=2, [10]=10})

local tim = {name="Tim", age=32}
local jack = {name="Jack", age=8}
p{
  [tim] = "programmer",
  [jack] = "player",
}
p{
  programmer = tim,
  player = jack,
}

p(ffi)

p(require('uv'))
