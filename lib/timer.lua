local UV = require('uv')

local function set_timeout(duration, callback, ...)
  local args = {...}
  local timer = UV.new_timer()
  timer:start(duration, 0, function (status)
    timer:close()
    callback(unpack(args))
  end)
  return timer
end

local function set_interval(period, callback, ...)
  local args = {...}
  local timer = UV.new_timer()
  timer:start(period, period, function (status)
    callback(unpack(args))
  end)
  return timer
end

local function clear_timer(timer)
  timer:stop()
  timer:close()
end

return {
  set_timeout = set_timeout,
  set_interval = set_interval,
  clear_timer = clear_timer,
}
