local MIME = require('mime')
local HTTP = require('http')
local Url = require('url')
local FS = require('fs')
local Response = require('response')

-- Monkey patch in a helper
function Response.prototype:not_found(reason)
  self:write_head(404, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #reason
  })
  self:write(reason)
  self:close()
end

-- Monkey patch in another
function Response.prototype:error(reason)
  self:write_head(500, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #reason
  })
  self:write(reason)
  self:close()
end

local root = "."
HTTP.create_server("0.0.0.0", 8080, function(req, res)
  req.uri = Url.parse(req.url)
  local path = root .. req.uri.pathname
  FS.stat(path, function (err, stat)
    if err then
      if err.code == "ENOENT" then
        return res:not_found(err.message .. "\n")
      end
      return res:error(err.message .. "\n")
    end
    if not stat.is_file then
      return res:not_found("Requested url is not a file\n")
    end
    
    res:write_head(200, {
      ["Content-Type"] = MIME.get_type(path),
      ["Content-Length"] = stat.size
    })

    FS.create_read_stream(path):pipe(res)

  end)

end)

print("Http static file server listening at http://localhost:8080/")
