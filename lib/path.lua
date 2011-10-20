local Table = require('table')
local Path = {}

-- Split a filename into [root, dir, basename], unix version
-- 'root' is just a slash, or nothing.
local function split_path(filename)
  local root, dit, basename
  local i, j = filename:find("[^/]*$")
  if filename:sub(1, 1) == "/" then
    root = "/"
    dir = filename:sub(2, i - 1)
  else
    root = ""
    dir = filename:sub(1, i - 1)
  end
  local basename = filename:sub(i, j)
  return root, dir, basename, ext
end

-- Modifies an array of path parts in place by interpreting "." and ".." segments
local function normalize_array(parts)
  local skip = 0
  for i = #parts, 1, -1 do
    local part = parts[i]
    if part == "." then
      Table.remove(parts, i)
    elseif part == ".." then
      Table.remove(parts, i)
      skip = skip + 1
    elseif skip > 0 then
      Table.remove(parts, i)
      skip = skip - 1
    end
  end
end

function Path.normalize(path)
  local is_absolute = path:sub(1, 1) == "/"
  local trailing_slash = path:sub(#path) == "/"

  local parts = {}
  for part in path:gmatch("[^/]+") do
    parts[#parts + 1] = part
  end
  normalize_array(parts)
  path = Table.concat(parts, "/")

  if #path == 0 then
    if is_absolute then
      return "/"
    end
    return "."
  end
  if trailing_slash then
    path = path .. "/"
  end
  if is_absolute then
    path = "/" .. path
  end
  return path
end

function Path.join(...)
  return Path.normalize(Table.concat({...}, "/"))
end

function Path.dirname(path)
  local root, dir = split_path(path)

  if #dir > 0 then
    dir = dir:sub(1, #dir - 1)
    return root .. dir
  end
  if #root > 0 then
    return root
  end
  return "."

end

function Path.basename(path, expected_ext)
  return path:match("[^/]+$") or ""
end

function Path.extname(path)
  return path:match(".[^.]+$") or ""
end

return Path
