local MIME = require('mime')
local HTTP = require('http')
local Url = require('url')
local FS = require('fs')
local Response = require('response')

-- Monkey patch in a helper
function Response.prototype:notFound(reason)
  self:writeHead(404, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #reason
  })
  self:write(reason)
  self:close()
end

-- Monkey patch in another
function Response.prototype:error(reason)
  self:writeHead(500, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #reason
  })
  self:write(reason)
  self:close()
end

local root = "."
HTTP.createServer("0.0.0.0", 8080, function(req, res)
  req.uri = Url.parse(req.url)
  local path = root .. req.uri.pathname
  FS.stat(path, function (err, stat)
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
      ["Content-Type"] = MIME.getType(path),
      ["Content-Length"] = stat.size
    })

    FS.createReadStream(path):pipe(res)

  end)

end)

print("Http static file server listening at http://localhost:8080/")
