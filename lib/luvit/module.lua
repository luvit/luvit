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

local fs = require('fs')
local path = require('path')
local table = require('table')
local zipreader = require('zipreader')
local uv = require('uv_native')

local zip = zipreader(uv.fsOpen(uv.execpath(), "r", tonumber("644", 8)), {
  fstat = uv.fsFstat,
  read = function (fd, size, offset)
    return uv.fsRead(fd, offset, size)
  end
})
_G.zip = zip

local function fileExists(path)
  if zip and path:sub(1, 4) == "zip:" then
    local zipPath = path:sub(5)
    return zip.stat(zipPath)
  end
  return fs.existsSync(path)
end

local function readFile(path)
  if zip and path:sub(1, 4) == "zip:" then
    local zipPath = path:sub(5)
    return zip.readfile(zipPath)
  end
  return fs.readFileSync(path)
end

local module = {}

-- This is the built-in require from lua.
module.oldRequire = require

local global_meta = {__index=_G}

local function partialRealpath(filepath)
  -- Do some minimal realpathing
  local link
  link = fs.lstatSync(filepath).is_symbolic_link and fs.readlinkSync(filepath)
  while link do
    filepath = path.resolve(path.dirname(filepath), link)
    link = fs.lstatSync(filepath).is_symbolic_link and fs.readlinkSync(filepath)
  end
  return path.normalize(filepath)
end

package.loading = {}

local function myloadfile(filepath)
  if not fileExists(filepath) then return end

  if not zip or filepath:sub(1, 4) ~= "zip:" then
    filepath = partialRealpath(filepath)
  end

  if package.loaded[filepath] then
    return function ()
      return package.loaded[filepath]
    end
  end

  local code = readFile(filepath)

  -- TODO: find out why inlining assert here breaks the require test
  local fn, err = loadstring(code, '@' .. filepath)
  assert(fn, err)
  local dirname = path.dirname(filepath)
  local realRequire = require
  local exports = {}
  exports.__filename = filepath
  exports.__dirname = dirname
  exports.exports = package.loading[filepath] or {}
  exports.require = function(filepath)
    local function exists(fn)
      if pcall(function () fs.statSync(fn) end) then
        return fn
      end
    end

    local stem = path.normalize(path.join(dirname, filepath))
    local realName = exists(stem) or exists(stem .. '.lua') or exists(stem .. '.luvit') or exists(stem .. 'init.lua') or exists(stem .. 'init.luvit')

    if not realName then
      return realRequire(filepath)
    end

    if package.loading[realName] then
      return package.loading[realName]
    end

    local m = realRequire(filepath, dirname) or package.loading[realName]
    package.loading[realName] = nil
    return m
  end
  local fn = setfenv(fn, setmetatable(exports, global_meta))
  package.loading[filepath] = exports.exports
  local module = fn() or package.loading[filepath]
  package.loaded[filepath] = module
  package.loading[filepath] = nil
  return function() return package.loaded[filepath] end
end
module.myloadfile = myloadfile

local function myloadlib(filepath)
  if not fileExists(filepath) then return end

  filepath = partialRealpath(filepath)

  if package.loaded[filepath] then
    return function ()
      return package.loaded[filepath]
    end
  end

  local name = path.basename(filepath)
  if name == "init.luvit" then
    name = path.basename(path.dirname(filepath))
  end
  local base_name = name:sub(1, #name - 6)
  package.loaded[filepath] = base_name -- Hook to allow C modules to find their path
  local fn, error_message = package.loadlib(filepath, "luaopen_" .. base_name)
  if fn then
    local module = fn()
    package.loaded[filepath] = module
    return function() return module end
  end
  error(error_message)
end

-- tries to load a module at a specified absolute path
local function loadModule(filepath, verbose)

  -- First, look for exact file match if the extension is given
  local extension = path.extname(filepath)
  if extension == ".lua" then
    return myloadfile(filepath)
  end
  if extension == ".luvit" then
    return myloadlib(filepath)
  end

  -- Then, look for module/package.lua config file
  if fileExists(path.join(filepath, "package.lua")) then
    local metadata = loadModule(path.join(filepath, "package.lua"))()
    if metadata.main then
      return loadModule(path.join(filepath, metadata.main))
    end
  end

  -- Try to load as either lua script or binary extension
  local fn = myloadfile(filepath .. ".lua") or myloadfile(path.join(filepath, "init.lua"))
          or myloadlib(filepath .. ".luvit") or myloadlib(path.join(filepath, "init.luvit"))
  if fn then return fn end

  return "\n\tCannot find module " .. filepath
end

local builtinLoader = package.loaders[1]
local base_path = process.cwd()
local libpath = process.execPath:match('^(.*)' .. path.sep .. '[^' ..path.sep.. ']+' ..path.sep.. '[^' ..path.sep.. ']+$') ..path.sep.. 'lib' ..path.sep.. 'luvit' ..path.sep
local bundled_paths = {"modules", "node_modules"}
function module.require(filepath, dirname)
  if not dirname then dirname = base_path end

  -- Let module paths always use / even on windows
  filepath = filepath:gsub("/", path.sep)

  -- Absolute and relative required modules
  local absolute_path
  if filepath:sub(1, path.root:len()) == path.root then
    absolute_path = path.normalize(filepath)
  elseif filepath:sub(1, 1) == "." then
    absolute_path = path.join(dirname, filepath)
  end
  if absolute_path then
    local loader = loadModule(absolute_path)
    if type(loader) == "function" then
      return loader()
    else
      error("Failed to find module '" .. filepath .."'")
    end
  end

  local errors = {}

  -- Builtin modules
  local module = package.loaded[filepath]
  if module then return module end
  if filepath:find("^[a-z_]+$") then
    local loader = builtinLoader(filepath)
    if type(loader) == "function" then
      module = loader()
      package.loaded[filepath] = module
      return module
    else
      errors[#errors + 1] = loader
    end
  end

  -- Library modules

  local loader = loadModule(libpath .. filepath)
  if type(loader) == "function" then
    return loader()
  else
    errors[#errors + 1] = loader
  end

  -- zip bundled modules
  if zip then
    loader = loadModule("zip:" .. filepath)
    if type(loader) == "function" then
      return loader()
    end
    errors[#errors + 1] = loader
  end

  -- Bundled path modules
  local dir = dirname .. path.sep
  repeat
    local loader
    for _, bundled_path in ipairs(bundled_paths) do
      local full_path = path.join(dir, bundled_path, filepath)
      loader = loadModule(full_path)
      if type(loader) == "function" then
        return loader()
      end
      errors[#errors + 1] = loader
    end
    dir = path.dirname(dir)
  until dir == "."

  error("Failed to find module '" .. filepath .."'" .. table.concat(errors, ""))

end

-- Remove the cwd based loaders, we don't want them
package.loaders = nil
package.path = nil
package.cpath = nil
package.searchpath = nil
package.seeall = nil
package.config = nil
_G.module = nil

return module
