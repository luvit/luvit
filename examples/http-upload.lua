local HTTP = require("http")
local Utils = require("utils")
local Table = require("table")

HTTP.create_server("0.0.0.0", 8080, function (req, res)
  p("on_request", req)
  local chunks = {}
  local length = 0
  req:on('data', function (chunk, len)
    p("on_data", {chunk=chunk, len=len})
    length = length + 1
    chunks[length] = chunk
  end)
  req:on('end', function ()
    local body = Table.concat(chunks, "")
    p("on_end", {body=body})

    res:write_head(200, {
      ["Content-Type"] = "text/plain",
      ["Content-Length"] = #body
    })
    res:write(body)
    res:close()
  end)
    
end)

print("Server listening at http://localhost:8080/")

