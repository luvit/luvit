local Timer = require('timer')

print("Starting 200ms interval")
local interval = Timer:setInterval(200, function ()
  p("on_interval")
end)
print("Starting 1000ms timer")
Timer:setTimeout(1000, function ()
  p("on_timeout!")
  Timer:clearTimer(interval)
end)


