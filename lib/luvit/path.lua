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

local Object = require('core').Object
local os = require('os_binding')
local table = require('table')

local path = {}

local Path = Object:extend()
path.Path = Path

function Path:initialize(root, sep)
  self.root = root
  self.sep = sep
end

-- Split a filename into [root, dir, basename], unix version
-- 'root' is just a slash, or nothing.
function Path:_splitPath(filename)
  local root, dir, basename
  local i, j = filename:find("[^" .. self.sep .. "]*$")
  if filename:sub(1, 1) == self.sep then
    root = self.root
    dir = filename:sub(2, i - 1)
  else
    root = ""
    dir = filename:sub(1, i - 1)
  end
  local basename = filename:sub(i, j)
  return root, dir, basename, ext
end

-- Modifies an array of path parts in place by interpreting "." and ".." segments
function Path:_normalizeArray(parts)
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

function Path:normalize(filepath)
  local is_absolute = filepath:sub(1, 1) == self.sep
  local trailing_slash = filepath:sub(#filepath) == self.sep

  local parts = {}
  for part in filepath:gmatch("[^" .. self.sep .. "]+") do
    parts[#parts + 1] = part
  end
  self:_normalizeArray(parts)
  filepath = table.concat(parts, self.sep)

  if #filepath == 0 then
    if is_absolute then
      return self.sep
    end
    return "."
  end
  if trailing_slash then
    filepath = filepath .. self.sep
  end
  if is_absolute then
    filepath = self.sep .. filepath
  end
  return filepath
end

function Path:join(...)
  local parts = {...}
  for i, part in ipairs(parts) do
    -- Strip leading slashes on all but first item
    if i > 1 then
      while part:sub(1, 1) == self.sep do
        part = part:sub(2)
      end
    end
    -- Strip trailing slashes on all but last item
    if i < #parts then
      while part:sub(#part) == self.sep do
        part = part:sub(1, #part - 1)
      end
    end
    parts[i] = part
  end
  return table.concat(parts, self.sep)
end

function Path:resolve(root, filepath)
  if filepath:sub(1, self.root:len()) == self.root then
    return self:normalize(filepath)
  end
  return self:join(root, filepath)
end

function Path:dirname(filepath)
  if filepath:sub(filepath:len()) == self.sep then
    filepath = filepath:sub(1, -2)
  end

  local root, dir = self:_splitPath(filepath)

  if #dir > 0 then
    dir = dir:sub(1, #dir - 1)
    return root .. dir
  end
  if #root > 0 then
    return root
  end
  return "."

end

function Path:basename(filepath, expected_ext)
  return filepath:match("[^" .. self.sep .. "]+$") or ""
end

function Path:extname(filepath)
  return filepath:match(".[^.]+$") or ""
end

-- use this when fully qualified long windows paths cannot have relative parts
local function derelative(filepath)
  -- loop . and .. cases until cleared
  while filepath:match("\\%.\\") do
    filepath = filepath:gsub("\\%.\\","\\",1)
  end
  while filepath:match("\\[^\\]+\\%.%.\\") do
    -- some X:\..\..\ pairs get eaten by this but no matter
    filepath = filepath:gsub("\\[^\\]+\\%.%.\\","\\",1)
  end
  -- handle .. to the root
  if filepath:match("^[%a]:\\%.%.\\") then
    filepath = filepath:gsub("^([%a]:\\)%.%.\\","%1",1)
  end
  -- trailing cases last
  filepath = filepath:gsub("\\%.$","")
  filepath = filepath:gsub("\\[^\\]+\\%.%.$","")
  filepath = filepath:gsub("^([%a]:\\)%.%.$","%1",1)
  return filepath
end

function Path:_makeLong(filepath)
  if os.type() == "win32" then
    -- Standard windows fully qualified path
    if filepath:match("^[%a]:") then
      -- long paths cannot have relative parts
      return "\\\\?\\" .. derelative(filepath)
    else
      -- Windows Network Path
      if filepath:match("^\\\\[^?]") then
        -- long paths cannot have relative parts
        return "\\\\?\\UNC\\" .. derelative(filepath)
      else
        return filepath
      end
    end
  else
    return filepath
  end
end

path.nt = Path:new("c:", "\\")
path.posix = Path:new("/", "/")

local function setup_meta(ospath)
  setmetatable(path, {__index = function(table, key)
      if type(ospath[key]) == 'function' then
        return function(...) return ospath[key](ospath, ...) end
      else
        return ospath[key]
      end
    end
  })
end


if os.type() == "win32" then
  setup_meta(path.nt)
else
  setup_meta(path.posix)
end

return path
