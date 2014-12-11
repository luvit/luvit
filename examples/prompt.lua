local readLine = require('readline').readLine

-- Wrapper around readline to provide a nice
local function prompt(message)
  local thread = coroutine.running()
  readLine(message, function (err, line, reason)
    if err then
      return assert(coroutine.resume(thread, nil, err))
    end
    return assert(coroutine.resume(thread, line, reason))
  end)
  return coroutine.yield()
end

coroutine.wrap(function ()
  -- prompt returns false on Control+C
  -- and nil on Control+D, assert will catch those and exit the process.
  local name = assert(prompt("Who are you? "))
  local age = tonumber(assert(prompt("How old are you? ")))
  p{name=name,age=age}
end)()
