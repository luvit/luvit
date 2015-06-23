--[[

Copyright 2014-2015 The Luvit Authors. All Rights Reserved.

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

if exports then
  exports.name = "luvit/require"
  exports.version = "1.2.1"
  exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/require.lua"
  exports.description = "Luvit's custom require system with relative requires and sane search paths."
  exports.tags = {"luvit", "require"}
  exports.license = "Apache 2"
  exports.author = { name = "Tim Caswell" }
end

local luvi = require('luvi')
local bundle = luvi.bundle
local pathJoin = luvi.path.join
local env = require('env')
local os = require('ffi').os
local uv = require('uv')

local realRequire = _G.require

local tmpBase = os == "Windows" and (env.get("TMP") or uv.cwd()) or
                                    (env.get("TMPDIR") or '/tmp')
local binExt = os == "Windows" and ".dll" or ".so"

-- Package sources
-- $author/$name@$version -> resolves to hash, cached in memory
-- bundle:full/bundle/path
-- full/unix/path
-- C:\\full\windows\path

local fileCache = {}
local function readFile(path)
  assert(path)
  local data = fileCache[path]
  if data ~= nil then return data end
  local prefix = path:match("^bundle:/*")
  if prefix then
    data = bundle.readfile(path:sub(#prefix + 1))
  else
    local stat = uv.fs_stat(path)
    if stat and stat.type == "file" then
      local fd = uv.fs_open(path, "r", 511)
      if fd then
        data = uv.fs_read(fd, stat.size, -1)
        uv.fs_close(fd)
      end
    end
  end
  fileCache[path] = data and true or false
  return data
end

local function scanDir(path)
  local bundlePath = path:match("^bundle:/*(.*)")
  if bundlePath then
    local names, err = bundle.readdir(bundlePath)
    if not names then return nil, err end
    local i = 1
    return function ()
      local name = names[i]
      if not name then return end
      i = i + 1
      local stat = assert(bundle.stat(bundlePath .. "/" .. name))
      return {
        name = name,
        type = stat.type,
      }
    end
  else
    local req, err = uv.fs_scandir(path)
    if not req then return nil, err end
    return function ()
      return uv.fs_scandir_next(req)
    end
  end
end

local statCache = {}
local function statFile(path)
  local stat, err
  stat = statCache[path]
  if stat then return stat end
  local bundlePath = path:match("^bundle:/*(.*)")
  if bundlePath then
    stat, err = bundle.stat(bundlePath)
  else
    stat, err = uv.fs_stat(path)
  end
  if stat then
    statCache[path] = stat
    return stat
  end
  return nil, err or "Problem statting: " .. path
end


local dirCache = {}
local function isDir(path)
  assert(path)
  local is = dirCache[path]
  if is ~= nil then return is end
  local prefix = path:match("^bundle:/*")
  local stat
  if prefix then
    stat = bundle.stat(path:sub(#prefix + 1))
  else
    stat = uv.fs_stat(path)
  end
  is = stat and (stat.type == "directory") or false
  dirCache[path] = is
  return is
end


local types = { ".lua", binExt }

local function fixedRequire(path)
  assert(path)
  local fullPath = path
  local data = readFile(fullPath)
  if not data then
    for i = 1, #types do
      fullPath = path .. types[i]
      data = readFile(fullPath)
      if data then break end
      fullPath = pathJoin(path, "init" .. types[i])
      data = readFile(fullPath)
      if data then break end
    end
    if not data then return end
  end
   local prefix = fullPath:match("^bundle:")
   local normalizedPath = fullPath
   if prefix == "bundle:" and bundle.base then
     normalizedPath = fullPath:gsub(prefix, bundle.base)
   end

  return data, fullPath, normalizedPath
end


local skips = {}
local function moduleRequire(base, name)
  assert(base and name)
  while true do
    if not skips[base] then
      local mod, path, key
      if isDir(pathJoin(base, "libs")) then
        mod, path, key = fixedRequire(pathJoin(base, "libs", name))
        if mod then return mod, path, key end
      end
      if isDir(pathJoin(base, "deps")) then
        mod, path, key = fixedRequire(pathJoin(base, "deps", name))
        if mod then return mod, path, key end
      end
    end

    -- Stop at filesystem or prefix root (58 is ":")
    if base == "/" or base:byte(-1) == 58 then break end
    base = pathJoin(base, "..")
  end
  -- If we didn't find it outside the bundle, look inside the bundle.
  if not base:match("^bundle:/*") then
    return moduleRequire("bundle:", name)
  end
end


local moduleCache = {}


-- Prototype for module tables
-- module.path - is path to module
-- module.dir - is path to directory containing module
-- module.exports - actual exports, initially is an empty table
local Module = {}
local moduleMeta = { __index = Module }

local function makeModule(modulePath)
  -- Convert windows paths to unix paths (mostly)
  local path = modulePath:gsub("\\", "/")
  -- Normalize slashes around prefix to be exactly one after
  path = path:gsub("^/*([^/:]+:)/*", "%1/")
  return setmetatable({
    path = path,
    dir = pathJoin(path, ".."),
    exports = {}
  }, moduleMeta)
end

function Module:load(path)
  path = pathJoin(self.dir, './' .. path)
  local prefix = path:match("^bundle:/*")
  if prefix then
    return bundle.readfile(path:sub(#prefix + 1))
  end
  local fd, stat, data, err
  fd, err = uv.fs_open(path, "r", 511)
  if fd then
    stat, err = uv.fs_fstat(fd)
    if stat then
      data, err = uv.fs_read(fd, stat.size, -1)
    end
    uv.fs_close(fd)
  end
  if data then return data end
  return nil, err
end

function Module:scan(path)
  return scanDir(pathJoin(self.dir, './' .. path))
end

function Module:stat(path)
  return statFile(pathJoin(self.dir, './' .. path))
end

function Module:action(path, action)
  path = pathJoin(self.dir, './' .. path)
  local bundlePath = path:match("^bundle:/*(.*)")
  if bundlePath then
    return bundle.action(bundlePath, action)
  else
    return action(path)
  end
end

function Module:resolve(name)
  assert(name, "Missing name to resolve")
  local debundled_name = name:match("^bundle:(.*)") or name
  if debundled_name:byte(1) == 46 then -- Starts with "."
    return fixedRequire(pathJoin(self.dir, name))
  elseif debundled_name:byte(1) == 47 then -- Starts with "/"
    return fixedRequire(name)
  end
  return moduleRequire(self.dir, name)
end

function Module:require(name)
  assert(name, "Missing name to require")

  if package.preload[name] or package.loaded[name] then
    return realRequire(name)
  end

  -- Resolve the path
  local data, path, key = self:resolve(name)
  if not path then
    local success, value = pcall(realRequire, name)
    if success then return value end
    if not success then
      error("No such module '" .. name .. "' in '" .. self.path .. "'\r\n" ..  value)
    end
  end

  -- Check in the cache for this module
  local module = moduleCache[key]
  if module then return module.exports end
  -- Put a new module in the cache if not
  module = makeModule(path)
  moduleCache[key] = module

  local ext = path:match("%.[^/\\]+$")
  if ext == ".lua" then
    local fn = assert(loadstring(data, path))
    local global = {
      module = module,
      exports = module.exports,
      require = function (...)
        return module:require(...)
      end
    }
    setfenv(fn, setmetatable(global, { __index = _G }))
    local ret = fn()

    -- Allow returning the exports as well
    if ret then module.exports = ret end

  elseif ext == binExt then
    local fnName = "luaopen_" .. name:match("[^/]+$"):match("^[^%.]+")
    local fn, err
    local realPath = uv.fs_access(path, "r") and path or uv.fs_access(key, "r") and key
    if realPath then
      -- If it's a real file, load it directly
      fn, err = package.loadlib(realPath, fnName)
      if not fn then
        error(realPath .. "#" .. fnName .. ": " .. err)
      end
    else
      -- Otherwise, copy to a temporary folder and read from there
      local dir = assert(uv.fs_mkdtemp(pathJoin(tmpBase, "lib-XXXXXX")))
      path = pathJoin(dir, path:match("[^/\\]+$"))
      local fd = uv.fs_open(path, "w", 384) -- 0600
      uv.fs_write(fd, data, 0)
      uv.fs_close(fd)
      fn, err = package.loadlib(path, fnName)
      if not fn then
        error(path .. "#" .. fnName .. ": " .. err)
      end
      uv.fs_unlink(path)
      uv.fs_rmdir(dir)
    end
    module.exports = fn()
  else
    error("Unknown type at '" .. path .. "' for '" .. name .. "' in '" .. self.path .. "'")
  end
  return module.exports
end


local function generator(modulePath)
  assert(modulePath, "Missing path to require generator")

  local module = makeModule(modulePath)
  local function require(...)
    return module:require(...)
  end

  return require, module
end

return generator
