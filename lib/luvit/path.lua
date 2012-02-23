--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

local os = require('os_binding')
local table = require('table')
local path = {}

if os.type() == "win32" then
  path.sep = "\\"
  path.root = "c:"
else
  path.sep = "/"
  path.root = "/"
end

-- Split a filename into [root, dir, basename], unix version
-- 'root' is just a slash, or nothing.
local function splitPath(filename)
  local root, dir, basename
  local i, j = filename:find("[^" .. path.sep .. "]*$")
  if filename:sub(1, 1) == path.sep then
    root = path.root
    dir = filename:sub(2, i - 1)
  else
    root = ""
    dir = filename:sub(1, i - 1)
  end
  local basename = filename:sub(i, j)
  return root, dir, basename, ext
end

-- Modifies an array of path parts in place by interpreting "." and ".." segments
local function normalizeArray(parts)
  local skip = 0
  for i = #parts, 1, -1 do
    local part = parts[i]
    if part == "." then
      table.remove(parts, i)
    elseif part == ".." then
      table.remove(parts, i)
      skip = skip + 1
    elseif skip > 0 then
      table.remove(parts, i)
      skip = skip - 1
    end
  end
end

function path.normalize(filepath)
  local is_absolute = filepath:sub(1, 1) == path.sep
  local trailing_slash = filepath:sub(#filepath) == path.sep

  local parts = {}
  for part in filepath:gmatch("[^" .. path.sep .. "]+") do
    parts[#parts + 1] = part
  end
  normalizeArray(parts)
  filepath = table.concat(parts, path.sep)

  if #filepath == 0 then
    if is_absolute then
      return path.sep
    end
    return "."
  end
  if trailing_slash then
    filepath = filepath .. path.sep
  end
  if is_absolute then
    filepath = path.sep .. filepath
  end
  return filepath
end

function path.join(...)
  return path.normalize(table.concat({...}, path.sep))
end

function path.resolve(root, filepath)
  if filepath:sub(1, path.root:len()) == path.root then
    return path.normalize(filepath)
  end
  return path.join(root, filepath)
end

function path.dirname(filepath)
  if filepath:sub(filepath:len()) == path.sep then
    filepath = filepath:sub(1, -2)
  end

  local root, dir = splitPath(filepath)

  if #dir > 0 then
    dir = dir:sub(1, #dir - 1)
    return root .. dir
  end
  if #root > 0 then
    return root
  end
  return "."

end

function path.basename(filepath, expected_ext)
  return filepath:match("[^" .. path.sep .. "]+$") or ""
end

function path.extname(filepath)
  return filepath:match(".[^.]+$") or ""
end

return path
