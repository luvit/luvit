local Timer = require('uv').Timer

local timer = Timer:new()
local timer2 = Timer:new()

timer:start(2000, 0, function (...)
  p("on_timeout", ...)
  timer2:stop()
  timer:stop()
  timer:close(p)
  timer2:close(p)
end)

timer2:start(333, 333, function (...)
  p("on_interval", ...)
  local period = timer2:getRepeat()
  p("period", period)
  timer2:setRepeat(period / 1.2 + 1);
end)

p(timer, timer2)
