local Coroutine = require('coroutine')
local Fiber = {}

function Fiber.new(fn)
  local co = Coroutine.create(fn)
  assert(Coroutine.resume(co, co))
end

-- Convert a callback based function to work with coroutines
function Fiber.wrap(fn, nargs)
  return function (coro, ...)
    local function resume(...)
      assert(Coroutine.resume(coro, ...))
    end
    local args = {...}
    if nargs == 1 then
      fn(args[1], resume)
    elseif nargs == 2 then
      fn(args[1], args[2], resume)
    elseif nargs == 3 then
      fn(args[1], args[2], args[3], resume)
    elseif nargs == 4 then
      fn(args[1], args[2], args[3], args[4], resume)
    else
      error("Too many nargs")
    end
    return Coroutine.yield()
  end
end

return Fiber

