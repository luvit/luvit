local http = require("http")

http.createServer(function (req, res)
  local body = "Hello world\n"
  res:setHeader("Content-Type", "text/plain")
  res:finish(body)
end):listen(8080)

print("Server listening at http://localhost:8080/")
