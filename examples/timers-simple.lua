local Timer = require('timer')

print("Starting 200ms interval")
local interval = Timer.set_interval(200, function ()
  p("on_interval")
end)
print("Starting 1000ms timer")
Timer.set_timeout(1000, function ()
  p("on_timeout!")
  Timer.clear_timer(interval)
end)


