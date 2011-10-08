local Coroutine = require('coroutine')

local function new(fn)
  local co = Coroutine.create(fn)
  assert(Coroutine.resume(co, co))
end

-- Make functions work with coros or callbacks
local function wrap(fn, nargs)
  return function (coro, ...)
    if type(coro) == 'thread' then
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
    else
      -- In this case coro is actually the first arg
      fn(coro, ...)
    end
  end
end

return {
  new = new,
  wrap = wrap,
}
