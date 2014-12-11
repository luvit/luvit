local readLine = require('readline').readLine

-- Wrapper around readline to provide a nice
local function prompt(message)
  local thread = coroutine.running()
  readLine(message, function (err, line)
    if err then
      return assert(coroutine.resume(thread, nil, err))
    end
    return assert(coroutine.resume(thread, line))
  end)
  return coroutine.yield()
end

coroutine.wrap(function ()
  local name = prompt("Who are you? ")
  -- prompt returns false on Control+C
  if name == false then os.exit(-1) end
  local age = prompt("How old are you? ")
  if age == false then os.exit(-1) end
  age = tonumber(age)
  p{name=name,age=age}
end)()
