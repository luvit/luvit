local server = require('web').createServer("127.0.0.1", 8080, require('cleanup')(function (req, res)
  return res(200, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = 12
  }, "Hello World\n")
end))
local address = server:getsockname()
p("http server listening on http://" .. address.address .. ':' .. address.port .. '/')
