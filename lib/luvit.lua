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

-- clear some globals
-- This will break lua code written for other lua runtimes
_G.io = nil
_G.os = nil
_G.math = nil
_G.string = nil
_G.coroutine = nil
_G.jit = nil
_G.bit = nil
_G.debug = nil
_G.table = nil
_G.loadfile = nil
_G.dofile = nil
--_oldprint = print
_G.print = nil

-- Load libraries used in this file
local debugm = require('debug')
local uv = require('uv')
local env = require('env')
local table = require('table')
local utils = require('utils')
local fs = require('fs')
local Tty = require('tty')
local Emitter = require('emitter')
local constants = require('constants')
local path = require('path')

-- Copy date and binding over from lua os module into luvit os module
local OLD_OS = require('os')
local OS_BINDING = require('os_binding')
package.loaded.os = OS_BINDING
package.preload.os_binding = nil
package.loaded.os_binding = nil
OS_BINDING.date = OLD_OS.date
OS_BINDING.time = OLD_OS.time

process = Emitter:new()

process.version = VERSION
process.versions = {
  luvit = VERSION,
  uv = uv.VERSION_MAJOR .. "." .. uv.VERSION_MINOR .. "-" .. UV_VERSION,
  luajit = LUAJIT_VERSION,
  yajl = YAJL_VERSION,
  http_parser = HTTP_VERSION,
}
_G.VERSION = nil
_G.YAJL_VERSION = nil
_G.LUAJIT_VERSION = nil
_G.UV_VERSION = nil
_G.HTTP_VERSION = nil

function process.exit(exit_code)
  process:emit('exit', exit_code)
  exitProcess(exit_code or 0)
end

function process:addHandlerType(name)
  local code = constants[name]
  if code then
    uv.activateSignalHandler(code)
    uv.unref()
  end
end

function process:missingHandlerType(name, ...)
  if name == "error" then
    error(...)
  elseif name == "SIGINT" or name == "SIGTERM" then
    process.exit()
  end
end

process.cwd = getcwd
_G.getcwd = nil
process.argv = argv
_G.argv = nil

local base_path = process.cwd()

-- Hide some stuff behind a metatable
local hidden = {}
setmetatable(_G, {__index=hidden})
local function hide(name)
  hidden[name] = _G[name]
  _G[name] = nil
end
hide("_G")
hide("exitProcess")

-- Ignore sigpipe and exit cleanly on SIGINT and SIGTERM
-- These shouldn't hold open the event loop
if luvit_os ~= "win" then
  uv.activateSignalHandler(constants.SIGPIPE)
  uv.unref()
  uv.activateSignalHandler(constants.SIGINT)
  uv.unref()
  uv.activateSignalHandler(constants.SIGTERM)
  uv.unref()
end

-- Load the tty as a pair of pipes
-- But don't hold the event loop open for them
process.stdin = Tty:new(0)
process.stdout = Tty:new(1)
local stdout = process.stdout
uv.unref()
uv.unref()


-- Replace print
function print(...)
  local n = select('#', ...)
  local arguments = { ... }

  for i = 1, n do
    arguments[i] = tostring(arguments[i])
  end

  stdout:write(table.concat(arguments, "\t") .. "\n")
end

-- A nice global data dumper
function p(...)
  local n = select('#', ...)
  local arguments = { ... }

  for i = 1, n do
    arguments[i] = utils.dump(arguments[i])
  end

  stdout:write(table.concat(arguments, "\t") .. "\n")
end

hide("printStderr")
-- Like p, but prints to stderr using blocking I/O for better debugging
function debug(...)
  local n = select('#', ...)
  local arguments = { ... }

  for i = 1, n do
    arguments[i] = utils.dump(arguments[i])
  end

  printStderr(table.concat(arguments, "\t") .. "\n")
end


-- Add global access to the environment variables using a dynamic table
process.env = setmetatable({}, {
  __pairs = function (table)
    local keys = env.keys()
    local index = 0
    return function (...)
      index = index + 1
      local name = keys[index]
      if name then
        return name, table[name]
      end
    end
  end,
  __index = function (table, name)
    return env.get(name)
  end,
  __newindex = function (table, name, value)
    if value then
      env.set(name, value, 1)
    else
      env.unset(name)
    end
  end
})

-- This is called by all the event sources from C
-- The user can override it to hook into event sources
function eventSource(name, fn, ...)
  local args = {...}
  return assert(xpcall(function ()
    return fn(unpack(args))
  end, debugm.traceback))
end

error_meta = {__tostring=function(table) return table.message end}

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

local function myloadfile(filepath)
  if not fs.existsSync(filepath) then return end

  filepath = partialRealpath(filepath)

  if package.loaded[filepath] then
    return function ()
      return package.loaded[filepath]
    end
  end

  local code = fs.readFileSync(filepath)

  -- TODO: find out why inlining assert here breaks the require test
  local fn = loadstring(code, '@' .. filepath)
  assert(fn)
  local dirname = path.dirname(filepath)
  local realRequire = require
  setfenv(fn, setmetatable({
    __filename = filepath,
    __dirname = dirname,
    require = function (filepath)
      return realRequire(filepath, dirname)
    end,
  }, global_meta))
  local module = fn()
  package.loaded[filepath] = module
  return function() return module end
end

local function myloadlib(filepath)
  if not fs.existsSync(filepath) then return end

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
  if fs.existsSync(filepath .. "/package.lua") then
    local metadata = loadModule(filepath .. "/package.lua")()
    if metadata.main then
      return loadModule(path.join(filepath, metadata.main))
    end
  end

  -- Try to load as either lua script or binary extension
  local fn = myloadfile(filepath .. ".lua") or myloadfile(filepath .. "/init.lua")
          or myloadlib(filepath .. ".luvit") or myloadlib(filepath .. "/init.luvit")
  if fn then return fn end

  return "\n\tCannot find module " .. filepath
end

-- Remove the cwd based loaders, we don't want them
local builtinLoader = package.loaders[1]
package.loaders = nil
package.path = nil
package.cpath = nil
package.searchpath = nil
package.seeall = nil
package.config = nil
_G.module = nil

function require(filepath, dirname)
  if not dirname then dirname = base_path end

  -- Absolute and relative required modules
  local first = filepath:sub(1, 1)
  local absolute_path
  if first == "/" then
    absolute_path = path.normalize(filepath)
  elseif first == "." then
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

  -- Bundled path modules
  local dir = dirname .. "/"
  repeat
    dir = dir:sub(1, dir:find("/[^/]*$") - 1)
    local full_path = dir .. "/modules/" .. filepath
    local loader = loadModule(dir .. "/modules/" .. filepath)
    if type(loader) == "function" then
      return loader()
    else
      errors[#errors + 1] = loader
    end
  until #dir == 0

  error("Failed to find module '" .. filepath .."'" .. table.concat(errors, ""))

end

local repl = require('repl')

local function usage()
  print("Usage: " .. process.argv[0] .. " [options] script.lua [arguments]")
  print("")
  print("Options:")
  print("  -h, --help          Print this help screen.")
  print("  -v, --version       Print the version.")
  print("  -e code_chunk       Evaluate code chunk and print result.")
  print("  -i, --interactive   Enter interactive repl after executing script.")
  print("                      (Note, if no script is provided, a repl is run instead.)")
  print("")
end

assert(xpcall(function ()

  local interactive = false
  local showrepl = true
  local file
  local state = "BEGIN"
  local to_eval = {}
  local args = {[0]=process.argv[0]}


  for i, value in ipairs(process.argv) do
    if state == "BEGIN" then
      if value == "-h" or value == "--help" then
        usage()
        showrepl = false
      elseif value == "-v" or value == "--version" then
        print(process.version)
        showrepl = false
      elseif value == "-e" or value == "--eval" then
        state = "-e"
        showrepl = false
      elseif value == "-i" or value == "--interactive" then
        interactive = true
      elseif value:sub(1, 1) == "-" then
        usage()
        process.exit(1)
      else
        file = value
        showrepl = false
        state = "USERSPACE"
      end
    elseif state == "-e" then
      to_eval[#to_eval + 1] = value
      state = "BEGIN"
    elseif state == "USERSPACE" then
      args[#args + 1] = value
    end
  end

  if not (state == "BEGIN" or state == "USERSPACE") then
    usage()
    process.exit(1)
  end

  process.argv = args

  for i, value in ipairs(to_eval) do
    repl.evaluateLine(value)
  end

  if file then
    assert(myloadfile(path.resolve(base_path, file)))()
  elseif not (uv.handleType(0) == "TTY") then
    process.stdin:on("data", function(line)
      repl.evaluateLine(line)
    end)
    process.stdin:readStart()
    uv.run()
    process.exit(0)
  end

  if interactive or showrepl then
    repl.start()
  end

end, debugm.traceback))

-- Start the event loop
uv.run()
-- trigger exit handlers and exit cleanly
process.exit(0)

