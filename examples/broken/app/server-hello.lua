local server = require("http").createServer(require('stack').stack(
  function (req, res)
    res:writeHead(200, {
      ["Content-Type"] = "text/plain",
      ["Content-Length"] = 12
    })
    res:finish("Hello World\n")
  end
)):listen(process.env.PORT or 8080, "127.0.0.1")

local address = server:address()
p("http server listening on http://" .. address.address .. ':' .. address.port .. '/')
