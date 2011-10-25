VERSION = "Prelease"
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
_G.print = nil

-- Load libraries used in this file
local Debug = require('debug')

local UV = require('uv')
local Env = require('env')

local Table = require('table')
local Utils = require('utils')
local FS = require('fs')
local TTY = require('tty')
local Emitter = require('emitter')
local Constants = require('constants')
local Path = require('path')

process = Emitter.new()

function process.exit(exit_code)
  process:emit('exit', exit_code)
  exit_process(exit_code or 0)
end

function process:add_handler_type(name)
  local code = Constants[name]
  if code then
    UV.activate_signal_handler(code)
    UV.unref()
  end
end

function process:missing_handler_type(name, ...)
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
hide("exit_process")

-- Ignore sigpipe and exit cleanly on SIGINT and SIGTERM
-- These shouldn't hold open the event loop
UV.activate_signal_handler(Constants.SIGPIPE)
UV.unref()
UV.activate_signal_handler(Constants.SIGINT)
UV.unref()
UV.activate_signal_handler(Constants.SIGTERM)
UV.unref()

-- Load the tty as a pair of pipes
-- But don't hold the event loop open for them
process.stdin = TTY.new(0)
UV.unref()
process.stdout = TTY.new(1)
UV.unref()
local stdout = process.stdout

-- Replace print
function print(...)
  local n = select('#', ...)
  local arguments = { ... }

  for i = 1, n do
    arguments[i] = tostring(arguments[i])
  end

  stdout:write(Table.concat(arguments, "\t") .. "\n")
end

-- A nice global data dumper
function p(...)
  local n = select('#', ...)
  local arguments = { ... }

  for i = 1, n do
    arguments[i] = Utils.dump(arguments[i])
  end

  stdout:write(Table.concat(arguments, "\t") .. "\n")
end

hide("print_stderr")
-- Like p, but prints to stderr using blocking I/O for better debugging
function debug(...)
  local n = select('#', ...)
  local arguments = { ... }

  for i = 1, n do
    arguments[i] = Utils.dump(arguments[i])
  end

  print_stderr(Table.concat(arguments, "\t") .. "\n")
end


-- Add global access to the environment variables using a dynamic table
process.env = setmetatable({}, {
  __pairs = function (table)
    local keys = Env.keys()
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
    return Env.get(name)
  end,
  __newindex = function (table, name, value)
    if value then
      Env.set(name, value, 1)
    else
      Env.unset(name)
    end
  end
})

-- This is called by all the event sources from C
-- The user can override it to hook into event sources
function event_source(name, fn, ...)
  local args = {...}
  return assert(xpcall(function ()
    return fn(unpack(args))
  end, Debug.traceback))
end

error_meta = {__tostring=function(table) return table.message end}

local global_meta = {__index=_G}

function myloadfile(path)
  local success, code = pcall(function ()
    return FS.read_file_sync(path)
  end)
  if not success then return nil, code end
  local fn = assert(loadstring(code, '@' .. path))
  local dirname = Path.dirname(path)
  local real_require = require
  setfenv(fn, setmetatable({
    __filename = filename,
    __dirname = dirname,
    require = function (path)
      return real_require(path, dirname)
    end,
  }, global_meta))
  return fn
end



-- tries to load a module at a specified absolute path
local function load_module(path, verbose)

  local cname = "luaopen_" .. Path.basename(path)

  -- Try the exact match first
  local fn = myloadfile(path)
  if fn then return fn end

  -- Then try with lua appended
  fn = myloadfile(path .. ".lua")
  if fn then return fn end

  local error_message
  -- Then try C addon with luvit appended
  fn, error_message = package.loadlib(path .. ".luvit", cname)
  if fn then return fn end
  -- TODO: find a less fragile way to tell a not found error from other errors
  if not (error_message == path .. ".luvit: cannot open shared object file: No such file or directory") then
    error(error_message)
  end

  -- Then Try a folder with init.lua in it
  fn = myloadfile(path .. "/init.lua")
  if fn then return fn end

  -- Finally try the same for a C addon
  fn, error_message = package.loadlib(path .. "/init.luvit", cname)
  if fn then return fn end
  -- TODO: find a less fragile way to tell a not found error from other errors
  if not (error_message == path .. "/init.luvit: cannot open shared object file: No such file or directory") then
    error(error_message)
  end

  return "\n\tCannot find module " .. path
end

-- Remove the cwd based loaders, we don't want them
local builtin_loader = package.loaders[1]
package.loaders = nil
package.path = nil
package.cpath = nil
package.searchpath = nil
package.seeall = nil
package.config = nil
_G.module = nil

function require(path, dirname)
  if not dirname then dirname = base_path end

  -- Absolute and relative required modules
  local first = path:sub(1, 1)
  local absolute_path
  if first == "/" then
    absolute_path = Path.normalize(path)
  elseif first == "." then
    absolute_path = Path.join(dirname, path)
  end
  if absolute_path then
    module = package.loaded[absolute_path]
    if module then return module end
    loader = load_module(absolute_path)
    if type(loader) == "function" then
      module = loader()
      package.loaded[absolute_path] = module
      return module
    else
      error("Failed to find module '" .. path .."'" .. loader)
    end
  end

  local errors = {}

  -- Builtin modules
  local module = package.loaded[path]
  if module then return module end
  if path:find("^[a-z_]+$") then
    local loader = builtin_loader(path)
    if type(loader) == "function" then
      module = loader()
      package.loaded[path] = module
      return module
    else
      errors[#errors + 1] = loader
    end
  end

  -- Bundled path modules
  local dir = dirname .. "/"
  repeat
    dir = dir:sub(1, dir:find("/[^/]*$") - 1)
    local full_path = dir .. "/modules/" .. path
    if package.loaded[full_path] then return package.loaded[full_path] end
    local loader = load_module(dir .. "/modules/" .. path)
    if type(loader) == "function" then
      local module = loader()
      package.loaded[full_path] = module
      return module
    else
      errors[#errors + 1] = loader
    end
  until #dir == 0

  error("Failed to find module '" .. path .."'" .. Table.concat(errors, ""))

end

local Repl = require('repl')

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

  local interactive
  local repl = true
  local file
  local state = "BEGIN"
  local to_eval = {}
  local args = {[0]=process.argv[0]}
  for i, value in ipairs(process.argv) do
    if state == "BEGIN" then
      if value == "-h" or value == "--help" then
        usage()
        repl = false
      elseif value == "-v" or value == "--version" then
        print(Repl.colored_name .. " version " .. VERSION)
        repl = false
      elseif value == "-e" or value == "--eval" then
        state = "-e"
        repl = false
      elseif value == "-i" or value == "--interactive" then
        interactive = true
      elseif value:sub(1, 1) == "-" then
        usage()
        process.exit(1)
      else
        file = value
        repl = false
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
    Repl.evaluate_line(value)
  end

  if file then
    assert(myloadfile(Path.resolve(base_path, file)))()
  end
  if interactive or repl then
    Repl.start()
  end

end, Debug.traceback))


-- Start the event loop
UV.run()
-- trigger exit handlers and exit cleanly
process.exit(0)

