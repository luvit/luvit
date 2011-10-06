local HTTP = require("http")
local Utils = require("utils")

HTTP.create_server(function (req, res)
  local body = Utils.dump({req=req,headers=headers}) .. "\n"
  res:write_head(200, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #body
  })
  res:write(body)
  res:finish()
end):listen(8080)

print("Server listening at http://localhost:8080/")

