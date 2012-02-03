local http = require("http")
local utils = require("utils")

http.createServer("0.0.0.0", 8080, function (req, res)
  local body = utils.dump({req=req,headers=req.headers}) .. "\n"
  res:writeHead(200, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #body
  })
  res:finish(body)
end)

print("Server listening at http://localhost:8080/")

