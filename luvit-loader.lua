--[[

Copyright 2014-2016 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]

local hasLuvi, luvi = pcall(require, 'luvi')
local uv, bundle

if hasLuvi then
  uv = require('uv')
  bundle = luvi.bundle
else
  uv = require('luv')
end

local getenv = require('os').getenv

local isWindows
if _G.jit then
  isWindows = _G.jit.os == "Windows"
else
  isWindows = not not package.path:match("\\")
end

local tmpBase = isWindows and (getenv("TMP") or uv.cwd()) or
                              (getenv("TMPDIR") or '/tmp')
local binExt = isWindows and ".dll" or ".so"

local getPrefix, splitPath, joinParts
if isWindows then
  -- Windows aware path utilities
  function getPrefix(path)
    return path:match("^%a:\\") or
           path:match("^/") or
           path:match("^\\+")
  end
  function splitPath(path)
    local parts = {}
    for part in string.gmatch(path, '([^/\\]+)') do
      table.insert(parts, part)
    end
    return parts
  end
  function joinParts(prefix, parts, i, j)
    if not prefix then
      return table.concat(parts, '/', i, j)
    elseif prefix ~= '/' then
      return prefix .. table.concat(parts, '\\', i, j)
    else
      return prefix .. table.concat(parts, '/', i, j)
    end
  end
else
  -- Simple optimized versions for UNIX systems
  function getPrefix(path)
    return path:match("^/")
  end
  function splitPath(path)
    local parts = {}
    for part in string.gmatch(path, '([^/]+)') do
      table.insert(parts, part)
    end
    return parts
  end
  function joinParts(prefix, parts, i, j)
    if prefix then
      return prefix .. table.concat(parts, '/', i, j)
    end
    return table.concat(parts, '/', i, j)
  end
end

local function pathJoin(...)
  local inputs = {...}
  local l = #inputs

  -- Find the last segment that is an absolute path
  -- Or if all are relative, prefix will be nil
  local i = l
  local prefix
  while true do
    prefix = getPrefix(inputs[i])
    if prefix or i <= 1 then break end
    i = i - 1
  end

  -- If there was one, remove its prefix from its segment
  if prefix then
    inputs[i] = inputs[i]:sub(#prefix)
  end

  -- Split all the paths segments into one large list
  local parts = {}
  while i <= l do
    local sub = splitPath(inputs[i])
    for j = 1, #sub do
      parts[#parts + 1] = sub[j]
    end
    i = i + 1
  end

  -- Evaluate special segments in reverse order.
  local skip = 0
  local reversed = {}
  for idx = #parts, 1, -1 do
    local part = parts[idx]
    if part ~= '.' then
      if part == '..' then
        skip = skip + 1
      elseif skip > 0 then
        skip = skip - 1
      else
        reversed[#reversed + 1] = part
      end
    end
  end

  -- Reverse the list again to get the correct order
  parts = reversed
  for idx = 1, #parts / 2 do
    local j = #parts - idx + 1
    parts[idx], parts[j] = parts[j], parts[idx]
  end

  local path = joinParts(prefix, parts)
  return path
end

local function loader(dir, path, bundleOnly)
  local errors = {}
  local fullPath
  local useBundle = bundleOnly
  local function try(tryPath)
    local prefix = useBundle and "bundle:" or ""
    local fileStat = useBundle and bundle.stat or uv.fs_stat

    local newPath = tryPath
    local stat = fileStat(newPath)
    if stat and stat.type == "file" then
      fullPath = newPath
      return true
    end
    errors[#errors + 1] = "\n\tno file '" .. prefix .. newPath .. "'"

    newPath = tryPath .. ".lua"
    stat = fileStat(newPath)
    if stat and stat.type == "file" then
      fullPath = newPath
      return true
    end
    errors[#errors + 1] = "\n\tno file '" .. prefix .. newPath .. "'"

    newPath = pathJoin(tryPath, "init.lua")
    stat = fileStat(newPath)
    if stat and stat.type == "file" then
      fullPath = newPath
      return true
    end
    errors[#errors + 1] = "\n\tno file '" .. prefix .. newPath .. "'"

  end
  if string.sub(path, 1, 1) == "." then
    -- Relative require
    if not try(pathJoin(dir, path)) then
      return table.concat(errors)
    end
  else
    while true do
      if try(pathJoin(dir, "deps", path)) or
         try(pathJoin(dir, "libs", path)) then
        break
      end
      if #dir < 2 then
        return table.concat(errors)
      end
      dir = pathJoin(dir, "..")
    end
    -- Module require
  end
  if useBundle then
    local key = "bundle:" .. fullPath
    return function ()
      if package.loaded[key] then
        return package.loaded[key]
      end
      local code = bundle.readfile(fullPath)
      local module = loadstring(code, key)()
      package.loaded[key] = module
      return module
    end, key
  end
  fullPath = uv.fs_realpath(fullPath)
  return function ()
    if package.loaded[fullPath] then
      return package.loaded[fullPath]
    end
    local module = loadfile(fullPath)()
    package.loaded[fullPath] = module
    return module
  end
end

-- Register as a normal lua package loader.
local cwd = uv.cwd()
table.insert(package.loaders, 1, function (path)

  -- Ignore built-in libraries with this loader.
  if path:match("^[a-z]+$") and package.preload[path] then
    return
  end

  local caller = debug.getinfo(3, "S").source
  if string.sub(caller, 1, 1) == "@" then
    return loader(pathJoin(cwd, caller:sub(2), ".."), path)
  elseif string.sub(caller, 1, 7) == "bundle:" then
    return loader(pathJoin(caller:sub(8), ".."), path, true)
  end
end)
