local mime = require('mime')
local http = require('http')
local url = require('url')
local fs = require('fs')
local Response = require('http').Response

-- Monkey patch in a helper
function Response:notFound(reason)
  self:writeHead(404, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #reason
  })
  self:write(reason)
  self:close()
end

-- Monkey patch in another
function Response:error(reason)
  self:writeHead(500, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #reason
  })
  self:write(reason)
  self:close()
end

local root = "."
http.createServer(function(req, res)
  req.uri = url.parse(req.url)
  local path = root .. req.uri.pathname
  fs.stat(path, function (err, stat)
    if err then
      if err.code == "ENOENT" then
        return res:notFound(err.message .. "\n")
      end
      return res:error(err.message .. "\n")
    end
    if not stat.is_file then
      return res:notFound("Requested url is not a file\n")
    end

    res:writeHead(200, {
      ["Content-Type"] = mime.getType(path),
      ["Content-Length"] = stat.size
    })

    fs.createReadStream(path):pipe(res)

  end)

end):listen(8080)

print("Http static file server listening at http://localhost:8080/")
