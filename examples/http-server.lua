local http = require('http')

http.createServer(function (req, res)
  p{
    method = req.method,
    httpVersion = req.httpVersion,
    url = req.url,
    headers = req.headers
  }

  req:on("data", function (chunk)
    p("chunk", chunk)
  end)
  req:on("end", function ()
    p("end")

    local body = "Hello world\n"

    res:writeHead(200, {
      ["Content-Type"] = "text/plain",
      ["Content-Length"] = #body
    })
    res:finish(body)
  end)
end):listen(1337)
print("server listening at port 1337")
