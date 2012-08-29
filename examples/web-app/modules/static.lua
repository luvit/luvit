
local fs = require 'fs'
local pathJoin = require('path').join
local urlParse = require('url').parse
local getType = require('mime').getType
local osDate = require('os').date
local iStream = require('core').iStream

local floor = require('math').floor
local table = require 'table'

-- For encoding numbers using bases up to 64
local digits = {
  "0", "1", "2", "3", "4", "5", "6", "7",
  "8", "9", "A", "B", "C", "D", "E", "F",
  "G", "H", "I", "J", "K", "L", "M", "N",
  "O", "P", "Q", "R", "S", "T", "U", "V",
  "W", "X", "Y", "Z", "a", "b", "c", "d",
  "e", "f", "g", "h", "i", "j", "k", "l",
  "m", "n", "o", "p", "q", "r", "s", "t",
  "u", "v", "w", "x", "y", "z", "_", "$"
}
local function numToBase(num, base)
  local parts = {}
  repeat
    table.insert(parts, digits[(num % base) + 1])
    num = floor(num / base)
  until num == 0
  return table.concat(parts)
end

local function calcEtag(stat)
  return (not stat.is_file and 'W/' or '') ..
         '"' .. numToBase(stat.ino or 0, 64) ..
         '-' .. numToBase(stat.size, 64) ..
         '-' .. numToBase(stat.mtime, 64) .. '"'
end

local function createDirStream(path, options)
  local stream = iStream:new()
  fs.readdir(path, function (err, files)
    if err then
      stream:emit("error", err)
    end
    local html = {
      '<!doctype html>',
      '<html>',
      '<head>',
        '<title>' .. path .. '</title>',
      '</head>',
      '<body>',
        '<h1>' .. path .. '</h1>',
        '<ul><li><a href="../">..</a></li>'
    }
    for i, file in ipairs(files) do
      html[#html + 1] =
          '<li><a href="' .. file .. '">' .. file .. '</a></li>'
    end
    html[#html + 1] = '</ul></body></html>\n'
    html = table.concat(html)
    stream:emit("data", html)
    stream:emit("end")
  end)
  return stream
end


return function (app, options)
  if not options.root then error("options.root is required") end
  local root = options.root

  return function (req, res)
    -- Ignore non-GET/HEAD requests
    if not (req.method == "HEAD" or req.method == "GET") then
      return app(req, res)
    end

    local function serve(path, fallback)
      fs.open(path, "r", function (err, fd)
        if err then
          if err.code == 'ENOENT' or err.code == 'ENOTDIR' then
            if fallback then return serve(fallback) end
            if err.code == 'ENOTDIR' and path:sub(#path) == '/' then
              return res(302, {
                ["Location"] = req.url.path:sub(1, #req.url.path - 1)
              })
            end
            return app(req, res)
          end
          return res(500, {}, tostring(err) .. "\n" .. require('debug').traceback() .. "\n")
        end

        fs.fstat(fd, function (err, stat)
          if err then
            -- This shouldn't happen often, forward it just in case.
            fs.close(fd)
            return res(500, {}, tostring(err) .. "\n" .. require('debug').traceback() .. "\n")
          end

          local etag = calcEtag(stat)
          local code = 200
          local headers = {
            ['Last-Modified'] = osDate("!%a, %d %b %Y %H:%M:%S GMT", stat.mtime),
            ['ETag'] = etag
          }
          local stream

          if etag == req.headers['if-none-match'] then
            code = 304
          end

          if path:sub(#path) == '/' then
            -- We're done with the fd, createDirStream opens it again by path.
            fs.close(fd)

            if not options.autoIndex then
              -- Ignore directory requests if we don't have autoIndex on
              return app(req, res)
            end

            if not stat.is_directory then
              -- Can't autoIndex non-directories
              return res(302, {
                ["Location"] = req.url.path:sub(1, #req.url.path - 1)
              })
            end

            headers["Content-Type"] = "text/html"
            -- Create the index stream
            if not (req.method == "HEAD" or code == 304) then
              stream = createDirStream(path, options.autoIndex)
            end
          else
            if stat.is_directory then
              -- Can't serve directories as files
              fs.close(fd)
              return res(302, {
                ["Location"] = req.url.path .. "/"
              })
            end

            headers["Content-Type"] = getType(path)
            headers["Content-Length"] = stat.size

            if req.method ~= "HEAD" then
              stream = fs.createReadStream(nil, {fd=fd})
            else
              fs.close(fd)
            end
          end
          res(code, headers, stream)
        end)
      end)
    end

    local path = pathJoin(options.root, req.url.path)

    if options.index and path:sub(#path) == '/' then
      serve(pathJoin(path, options.index), path)
    else
      serve(path)
    end

  end
end

