local uv = require('uv')

local function bind(fn, ...)
  local args = {...}
  if #args == 0 then return fn end
  return function ()
    return fn(unpack(args))
  end
end

function exports.setTimeout(delay, callback, ...)
  local timer = uv.new_timer()
  local args = {...}
  uv.timer_start(timer, delay, 0, function ()
    uv.timer_stop(timer)
    uv.close(timer)
    callback(unpack(args))
  end)
  return timer
end

function exports.setInterval(interval, callback, ...)
  local timer = uv.new_timer()
  uv.timer_start(timer, interval, interval, bind(callback, ...))
  return timer
end

function exports.clearInterval(timer)
  uv.timer_stop(timer)
  uv.close(timer)
end

exports.clearTimeout = exports.clearInterval

local checker = uv.new_check()
local idler = uv.new_idle()
local immediateQueue = {}

local function onCheck()
  local queue = immediateQueue
  immediateQueue = {}
  for i = 1, #queue do
    queue[i]()
  end
  -- If the queue is still empty, we processed them all
  -- Turn the check hooks back off.
  if #immediateQueue == 0 then
    uv.check_stop(checker)
    uv.idle_stop(idler)
  end
end

function exports.setImmediate(callback, ...)

  -- If the queue was empty, the check hooks were disabled.
  -- Turn them back on.
  if #immediateQueue == 0 then
    uv.check_start(checker, onCheck)
    uv.idle_start(idler, onCheck)
  end

  immediateQueue[#immediateQueue + 1] = bind(callback, ...)

end
