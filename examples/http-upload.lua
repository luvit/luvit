local HTTP = require("http")
local Utils = require("utils")
local Table = require("table")

HTTP.create_server("0.0.0.0", 8080, function (req, res)
  p("on_request", req)
  local chunks = {}
  local length = 0
  req:on('data', function (chunk, len)
    p("on_data", {len=len})
    length = length + 1
    chunks[length] = chunk
  end)
  req:on('end', function ()
    local body = Table.concat(chunks, "")
    p("on_end", {total_len=#body})
    body = "length = " .. tostring(#body) .. "\n"
    res:write_head(200, {
      ["Content-Type"] = "text/plain",
      ["Content-Length"] = #body
    })
    res:finish(body)
  end)
    
end)

print("Server listening at http://localhost:8080/")

