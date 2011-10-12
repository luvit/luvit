local Coroutine = require('coroutine')
local Fiber = {}

function Fiber.new(fn)
  local resume = Coroutine.wrap(fn)
  resume(resume, Coroutine.yield)
end


return Fiber

