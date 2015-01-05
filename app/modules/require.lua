exports = {}
exports.name = "creationix/require"
exports.version = "1.0.2"

local uv = require('uv')
local luvi = require('luvi')
local bundle = luvi.bundle
local pathJoin = luvi.path.join
local env = require('env')
local os = require('ffi').os

local realRequire = require

local tmpBase = os == "Windows" and (env.get("TMP") or uv.cwd()) or
                                    (env.get("TMPDIR") or '/tmp')

-- Requires are relative
local function requireSystem(options)
  local loader, fixedLoader, finder, generator

  -- All options are optional
  options = options or {}

  -- The name of the function to inject
  local requireName = options.requireName or "require"

  -- The name of the folder to look for bundled dependencies
  local modulesName = options.modulesName or "modules"

  -- Map of format string to handler function
  -- Baked in is '#raw' to load a file as a raw string.
  -- Also is `#lua` (or no format) which loads the file as a module
  -- And allows it to require it's own dependencies.
  -- This supports circular dependencies usnig CJS style or
  -- return the exports at the end of the script.
  local formatters = {}

  -- Readers for different I/O prefixes
  -- Baked in is 'bundle:' for reading out of the luvi bundle
  -- and 'fs:' (or no prefix) for reading from the filesystem.
  local readers = { bundle = bundle.readfile }

  -- Internal table for caching resolved module paths (including prefix and format) to modules.
  local cachedModules = {}

  -- Given a callerPath and modulePath return a new modulePath and the raw body
  function finder(callerPath, modulePath)
    local prefix, format, base, path
    local match, newPath, module, err

    -- Extract format from modulePath
    format = string.match(modulePath, "#[^#]+$", -10)
    if format then
      path = string.sub(modulePath, 1, -#format - 1)
      format = string.sub(format, 2)
    else
      path = modulePath
      format = string.match(modulePath, "%.([^/\\%.]+)$", -10) or "lua"
    end

    -- Extract prefix from callerPath
    match = string.match(callerPath, "^[^:]+:")
    if match then
      if string.match(match, "^[A-Z]:$") then
        prefix = "fs"
        base = callerPath
      else
        base = string.sub(callerPath, #match + 1)
        prefix = string.sub(match, 1, -2)
      end
    else
      base = callerPath
    end

    -- Extract prefix from path
    match = string.match(path, "^[^:]+:")
    if match then
      if string.match(match, "^[A-Z]:$") then
        prefix = "fs"
      else
        path = string.sub(path, #match + 1)
        if string.sub(path, 1, 1) == "." then
          return nil, "Don't use prefix with relative requires"
        end
        prefix = string.sub(match, 1, -2)
      end
    elseif string.sub(path, 1, 1) == '/' then
      prefix = 'fs'
    end

    if not prefix then
      prefix = 'fs'
    end

    -- Resolve relative directly
    if string.sub(path, 1, 1) == "." then
      newPath = pathJoin(base, "..", path)
      module, err = loader(prefix, newPath, format)

    -- Resolve absolute directly
    elseif string.sub(path, 1, 1) == "/" or string.sub(path, 1, 1) == "\\" then
      newPath = path
      module, err = loader(prefix, newPath, format)

    -- Search for others
    else
      repeat
        base = pathJoin(base, "..")
        newPath = pathJoin(base, modulesName, path)
        module, err = loader(prefix, newPath, format)
      until module or base == "" or base == "/" or string.match(base, "^[A-Z]:\\$")
      if not module and prefix ~= "bundle" then
        -- If it's not found outside the bundle, look there too.
        module, err = loader("bundle", pathJoin(modulesName, path), format)
      end
    end

    if module then
      return module.exports, module.path
    else
      return nil, err
    end
  end

  -- Common code for loading a module once it's path has been resolved
  function loader(prefix, path, format)
    local module, err
    if string.find(path, "%."..format.."$") then
      return fixedLoader(prefix, path, format)
    else
      module, err = fixedLoader(prefix, path .. '.' .. format, format)
      if module then return module, err end
      return fixedLoader(prefix, pathJoin(path, 'init.' .. format), format)
    end
  end

  function fixedLoader(prefix, path, format)
    local key = prefix .. ":" .. path .. "#" .. format
    local module = cachedModules[key]
    if module then
      return module
    end

    local readfile = readers[prefix]
    if not readfile then
      error("Unknown prefix: " .. prefix)
    end

    local formatter = formatters[format]
    if not formatter then
      error("Unknown format: " .. format)
    end

    local data, err = readfile(path)
    if not data then
      return nil, err
    end

    if prefix ~= "fs" then
      path = prefix .. ":" .. path
    end

    module = {
      format = format,
      path = path,
      dir = pathJoin(path, ".."),
      exports = {}
    }
    cachedModules[key] = module

    local _
    _, err = formatter(data, module)
    if err then return _, err end

    return module
  end

  function formatters.raw(data, module)
    module.exports = data
  end

  function formatters.lua(data, module)
    local fn = assert(loadstring(data, module.path))
    setfenv(fn, setmetatable({
      [requireName] = generator(module.path),
      module = module,
      exports = module.exports,
    }, { __index = _G }))
    local ret = fn()

    -- Allow returning the exports as well
    if ret then module.exports = ret end
  end

  formatters[os == "Windows" and "dll" or "so"] = function (data, module)
    local filename = string.match(module.path, "[^/\\]+$")
    local name = "luaopen_" .. string.match(filename, "^[^.]+");
    local fn
    if uv.fs_access(module.path, "r") then
      -- If it's a real file, load it directly
      fn = assert(package.loadlib(module.path, name))
    else
      -- Otherwise, copy to a temporary folder and read from there
      local dir = assert(uv.fs_mkdtemp(pathJoin(tmpBase, "lib-XXXXXX")))
      local path = pathJoin(dir, filename)
      local fd = uv.fs_open(path, "w", tonumber("600", 8))
      uv.fs_write(fd, data, 0)
      uv.fs_close(fd)
      fn = assert(package.loadlib(path, name))
      uv.fs_unlink(path)
      uv.fs_rmdir(dir)
    end
    module.exports = fn()
  end

  function readers.fs(path)
    local fd, stat, chunk, err
    fd, err = uv.fs_open(path, "r", tonumber("644", 8))
    if not fd then
      return nil, err
    end
    stat, err = uv.fs_fstat(fd)
    if not stat then
      uv.fs_close(fd)
      return nil, err
    end
    chunk, err = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)
    if not chunk then
      return nil, err
    end
    return chunk
  end

  -- Mixin extra readers
  if options.readers then
    for key, value in pairs(options.readers) do
      readers[key] = value
    end
  end

  -- Mixin extra formatters
  if options.formatters then
    for key, value in pairs(options.formatters) do
      formatters[key] = value
    end
  end

  function generator(path)
    return function (name)
      return finder(path, name) or realRequire(name)
    end
  end

  return generator

end

exports.requireSystem = requireSystem
setmetatable(exports, {
  __call = function (_, ...)
    return requireSystem(...)
  end
})

return exports