--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

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

function Path:initialize(root, sep)
  self.root = root
  self.sep = sep
end

function Path:_get(key)
  return self[key]
end

function Path:getRoot(filepath)
  return self.root
end

function Path:getSep()
  return self.sep
end

-- Split a filename into [root, dir, basename], unix version
-- 'root' is just a slash, or nothing.
function Path:_splitPath(filename)
  local root, dir, basename
  local i, j = filename:find("[^" .. self.sep .. "]*$")
  if self:isAbsolute(filename) then
    root = self:getRoot(filename)
    dir = filename:sub(root:len()+1, i - 1)
  else
    root = ""
    dir = filename:sub(1, i - 1)
  end
  local basename = filename:sub(i, j)
  return root, dir, basename
end

-- Modifies an array of path parts in place by interpreting "." and ".." segments
function Path:_normalizeArray(parts, isrelative)
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
  if isrelative then
    while skip > 0 do
      table.insert(parts, 1, "..")
      skip = skip - 1
    end
  end
end

function Path:normalize(filepath)
  local is_absolute = self:isAbsolute(filepath)
  local root = is_absolute and self:getRoot(filepath) or nil
  local trailing_slash = filepath:sub(#filepath) == self.sep

  if root then
    filepath = filepath:sub(root:len()+1)
  end

  local parts = {}
  for part in filepath:gmatch("[^" .. self.sep .. "]+") do
    parts[#parts + 1] = part
  end
  self:_normalizeArray(parts, not is_absolute)
  filepath = table.concat(parts, self.sep)

  if #filepath == 0 then
    if is_absolute then
      return root
    end
    return "."
  end
  if trailing_slash then
    filepath = filepath .. self.sep
  end
  if is_absolute then
    filepath = root .. filepath
  end
  return filepath
end

function Path:_filterparts(parts)
  local filteredparts = {}
  -- filter out empty parts
  for i, part in ipairs(parts) do
    if part and part ~= "" then
      table.insert(filteredparts, part)
    end
  end
  for i, part in ipairs(filteredparts) do
    -- Strip leading slashes on all but first item
    if i > 1 then
      while part:sub(1, 1) == self.sep do
        part = part:sub(2)
      end
    end
    -- Strip trailing slashes on all but last item
    if i < #filteredparts then
      while part:sub(#part) == self.sep do
        part = part:sub(1, #part - 1)
      end
    end
    filteredparts[i] = part
  end
  return filteredparts
end

function Path:_rawjoin(parts)
  return table.concat(parts, self.sep)
end

function Path:join(...)
  local parts = {...}
  local filteredparts = self:_filterparts(parts)
  local joined = self:_rawjoin(filteredparts)
  return self:normalize(joined)
end

function Path:resolve(...)
  local paths = {...}
  local resolvedpath = ""
  local isabsolute = false
  for i=#paths, 1, -1 do
    local path = paths[i]
    if path and path ~= "" then
      resolvedpath = self:join(self:normalize(path), resolvedpath)
      if self:isAbsolute(resolvedpath) then
        isabsolute = true
        break
      end
    end
  end
  if not isabsolute then
    resolvedpath = self:join(process.cwd(), resolvedpath)
  end
  return resolvedpath
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
  local base, ext_pos = filepath:match("[^" .. self.sep .. "]+$") or ""
  if expected_ext then
     local ext_pos = base:find(expected_ext:gsub('%.', '%.') .. '$')
     if ext_pos then base = base:sub(1, ext_pos - 1) end
  end
  return base
end

function Path:extname(filepath)
  return filepath:match(".[^.]+$") or ""
end

local PosixPath = Path:extend()

function PosixPath:initialize()
  Path.initialize(self, '/', '/') 
end

function PosixPath:isAbsolute(filepath)
  return filepath:sub(1, self.root:len()) == self.root
end

function PosixPath:_makeLong(filepath)
  return filepath
end


local WindowsPath = Path:extend()

function WindowsPath:initialize()
  Path.initialize(self, 'c:\\', '\\') 
end

function WindowsPath:isAbsolute(filepath)
  return filepath and self:getRoot(filepath) ~= nil
end

function WindowsPath:isUNC(filepath)
  return filepath and filepath:match("^\\\\[^?\\.]") ~= nil
end

-- if filepath is not specified, returns the default root (c:\)
-- if filepath is specified, returns one of the following:
--   the UNC server and sharename in the format "\\server\" or "\\server\share\"
--   the drive letter in the format "d:\"
--   nil if the neither could be found (meaning the filepath is relative)
function WindowsPath:getRoot(filepath)
  if filepath then
    if self:isUNC(filepath) then
      local server = filepath:match("^\\\\([^?\\.][^\\]*)")
      -- share name is optional
      local share = filepath:sub(server:len()+3):match("^\\([^\\.][^\\]*)")
      local root = self.sep .. self.sep .. server .. (share and (self.sep .. share) or "")
      -- always append trailing slash
      return root .. self.sep
    else
      local drive = filepath:match("^[%a]:")
      -- always append trailing slash
      return drive and (drive .. self.sep)
    end
  else
    return self.meta.super.getRoot(self, filepath)
  end
end

function WindowsPath:join(...)
  local parts = {...}
  local filteredparts = self:_filterparts(parts)
  local joined = self:_rawjoin(filteredparts)

  -- the joined path may be interpretted as a UNC path, so we need to
  -- make sure that a UNC path was intended. if the first filtered part
  -- looks like a UNC path, then it is probably a safe assumption.
  -- if not, then consolidate any initial slashes to avoid ambiguity
  if not self:isUNC(filteredparts[1]) then
    joined = joined:gsub("^["..self.sep.."]+", self.sep)
  end

  return self:normalize(joined)
end

function WindowsPath:_makeLong(filepath)
  if self:isUNC(filepath) then
    return "\\\\?\\UNC\\" .. self:resolve(filepath)
  elseif self:isAbsolute(filepath) then
    return "\\\\?\\" .. self:resolve(filepath)
  else
    return filepath
  end
end

path.nt = WindowsPath:new()
path.posix = PosixPath:new()
return path
