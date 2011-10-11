local HTTP = require("http")
local Utils = require("utils")

HTTP.create_server("0.0.0.0", 8080, function (req, res)
  local body = Utils.dump({req=req,headers=req.headers}) .. "\n"
  res:write_head(200, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #body
  })
  res:write(body)
  res:close()
end)

print("Server listening at http://localhost:8080/")

