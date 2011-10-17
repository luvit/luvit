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
_G.print = nil
_G.loadfile = nil

-- Hide some stuff behind a metatable
local hidden = {}
setmetatable(_G, {__index=hidden})
local function hide(name)
  hidden[name] = _G[name]
  _G[name] = nil
end
hide("_G")
hide("exit_process")

-- Load libraries used in this file
local Debug = require('debug')

local UV = require('uv')
local Env = require('env')

local Table = require('table')
local Utils = require('utils')
local FS = require('fs')
local TTY = require('tty')
local Emitter = require('emitter')

process = Emitter.new()
process.argv = argv
_G.argv = nil

function process.exit(exit_code)
  process:emit('exit', exit_code)
  exit_process(exit_code or 0)
end

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

-- Load the file given or start the interactive repl
if process.argv[1] then
  dofile(process.argv[1])
else
  require('repl')
end

-- Start the event loop
UV.run()
-- trigger exit handlers and exit cleanly
process.exit(0)

