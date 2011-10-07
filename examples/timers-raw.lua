local UV = require('uv')

local timer = UV.new_timer()
local timer2 = UV.new_timer()

UV.timer_start(timer, 2000, 0, function (...)
  p("on_timeout", ...)
  UV.timer_stop(timer2)
  UV.timer_stop(timer)
  UV.close(timer, p)
  UV.close(timer2, p)
end)

UV.timer_start(timer2, 333, 333, function (...)
  p("on_interval", ...)
  local period = UV.timer_get_repeat(timer2)
  p("period", period)
  UV.timer_set_repeat(timer2, period / 1.2 + 1);
end)

p(timer, timer2)
