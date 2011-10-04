local uv = require('uv')

local client = uv.new_tcp()
uv.tcp_connect(client, "72.14.187.119", 8080)
uv.set_handler(client, "complete", function (...)
  p("oncomplete", {...})
end)
