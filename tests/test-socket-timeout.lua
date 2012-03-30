require("helper")
local net = require('net')

local client = net.create(4343, 'google.com')
client:setTimeout(250)
client:on('timeout', function()
  client:close()
end)

-- windows emits an error because of a interrupted system call
process:on('error', function() end)
