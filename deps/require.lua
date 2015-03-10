
if exports then
  exports.name = "luvit/require"
  exports.version = "1.0.0"
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

local function generator(modulePath)
  assert(modulePath, "Missing path to require generator")

  -- Convert windows paths to unix paths (mostly)
  local path = modulePath:gsub("\\", "/")
  -- Normalize slashes around prefix to be exactly one after
  path = path:gsub("^/*([^/:]+:)/*", "%1/")

  local base = pathJoin(path, "..")

  local function resolve(name)
    assert(name, "Missing name to resolve")
    if name:byte(1) == 46 then -- Starts with "."
      return fixedRequire(pathJoin(base, name))
    elseif name:byte(1) == 47 then -- Starts with "/"
      return fixedRequire(name)
    end
    return moduleRequire(base, name)
  end

  local function require(name)
    assert(name, "Missing name to require")

    if package.preload[name] or package.loaded[name] then
      return realRequire(name)
    end

    -- Resolve the path
    local data, path, key = resolve(name)
    if not path then
      local success, value = pcall(realRequire, name)
      if success then return value end
      if not success then
        error("No such module '" .. name .. "' in '" .. modulePath .. "'")
      end
    end

    -- Check in the cache for this module
    local module = moduleCache[key]
    if module then return module.exports end
    -- Put a new module in the cache if not
    module = { path = path, dir = pathJoin(path, ".."), exports = {} }
    moduleCache[key] = module

    local ext = path:match("%.[^/]+$")
    if ext == ".lua" then
      local fn = assert(loadstring(data, path))
      local global = {
        module = module,
        exports = module.exports
      }
      global.require, module.resolve = generator(path)
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
      error("Unknown type at '" .. path .. "' for '" .. name .. "' in '" .. modulePath .. "'")
    end
    return module.exports
  end

  return require, resolve, moduleCache
end

return generator
