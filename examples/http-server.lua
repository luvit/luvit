local http = require("http")

http.createServer(function (req, res)
  res:writeHead(200, {
    ["Content-Type"] = "text/plain",
  })
  res:done('hello world\n')
end):listen(8080)

print("Server listening at http://localhost:8080/")
