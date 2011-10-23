require("helper")

local Timer = require('timer')

expect("timeout")
Timer.set_timeout(200, function ()
  fulfill("timeout")
end)
