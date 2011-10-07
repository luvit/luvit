local UV = require('uv')

local function set_timeout(duration, callback)
  local timer = UV.new_timer()
  UV.timer_start(timer, duration, 0, function (status)
    UV.close(timer)
    callback()
  end)
  return timer
end

local function noop() end

local function set_interval(period, callback)
  local timer = UV.new_timer()
  UV.timer_start(timer, period, period, function (status)
    callback()
  end)
  return timer
end

local function clear_timer(timer)
  UV.timer_stop(timer)
  UV.close(timer, noop)
end

return {
  set_timeout = set_timeout,
  set_interval = set_interval,
  clear_timer = clear_timer,
}
