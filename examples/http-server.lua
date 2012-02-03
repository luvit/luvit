local HTTP = require("http")
local Utils = require("utils")

HTTP.createServer("0.0.0.0", 8080, function (req, res)
  local body = Utils.dump({req=req,headers=req.headers}) .. "\n"
  res:writeHead(200, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #body
  })
  res:finish(body)
end)

print("Server listening at http://localhost:8080/")

