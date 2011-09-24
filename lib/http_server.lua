local http = require("lib/http")

http.create_server(function (req, res)
--  p("req", req)
--  p("res", res)
  res:write_head(200, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = "11"
  })
  res:write("Hello World")
  res:finish()
end):listen(8080)

print("Server listening at http://localhost:8080/")


