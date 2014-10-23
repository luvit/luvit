local uv = require('uv')
local p = require('utils').prettyPrint
local bundle = require('luvi').bundle
local pathJoin = require('luvi').path.join

-- -- Requires are relative
-- return function (options)
--   -- The name of the function to inject
--   local requireName = options.requireName or "require"
--   -- The name of the folder to look for bundled dependencies
--   local modulesName = options.modulesName or "modules"
--   -- Map of format string to handler function
--   local formats = {}
--   -- The raw format gives you the raw data as a string
--   function formats.raw (data) return data end
--   if options.formats then
--     for key, value in pairs(options.formats) do
--       formats[key] = value
--     end
--   end

-- end

local finder

local formatters = {}
function formatters.raw (data, module)
  module.exports = data
end

function formatters.lua (data, module)
  local fn, err = loadstring(data, module.path)
  if not fn then
    return nil, err
  end
  p{
    fn = fn,
    type = type(fn),
  }
  setfenv(fn, setmetatable(_G, {
    index = {
      require = function (name)
        return finder(module.path, name) or require(name)
      end,
      module = module,
      exports = module.exports,
    }
  }))
  fn()
end

local readers = {}
readers.bundle = bundle.readfile

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

local cachedModules = {}


local function loader(prefix, path, format)
  local key = prefix .. ":" .. path .. "#" .. format
  local module = cachedModules[key]
  if module then return module end

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
    exports = {}
  }
  cachedModules[key] = module

  local _
  _, err = formatter(data, module)
  if err then return _, err end

  return module

end

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
    format = 'lua'
  end

  -- Extract prefix from callerPath
  match = string.match(callerPath, "^[^:]+:")
  if match then
    base = string.sub(callerPath, #match + 1)
    prefix = string.sub(match, 1, -2)
  else
    base = callerPath
  end

  -- Extract prefix from path
  match = string.match(path, "^[^:]+:")
  if match then
    path = string.sub(path, #match + 1)
    if string.sub(path, 1, 1) == "." then
      return nil, "Don't use prefix with relative requires"
    end
    prefix = string.sub(match, 1, -2)
  elseif string.sub(path, 1, 1) == '/' then
    prefix = 'fs'
  end

  if not prefix then
    prefix = 'fs'
  end

  p{
    path=path,
    prefix=prefix,
    format=format,
    base=base,
  }

  -- Resolve relative directly
  if string.sub(path, 1, 1) == "." then
    newPath = pathJoin(base, "..", path)
    module, err = loader(prefix, newPath, format)

  -- Resolve absolute directly
  elseif string.sub(path, 1, 1) == "/" then
    newPath = path
    module, err = loader(prefix, newPath, format)

  -- Search for others
  else
    repeat
      base = pathJoin(base, "..")
      newPath = pathJoin(base, "modules", path)
      module, err = loader(prefix, newPath, format)
    until module or base == ""
  end

  p {
    module = module,
    exports = module and module.exports,
    err = err
  }
  if module then
    return module.exports, module.path
  else
    return nil, err
  end
end

finder("bundle:modules/require.lua", "../test.txt#raw")
finder("bundle:modules/require.lua", "utils.lua")
finder("bundle:modules/require.lua", "test.lua")
finder("bundle:modules/require.lua", "nope.lua")
finder("bundle:modules/require.lua", "/home/tim/Code/luvit/app/modules/utils.lua")
