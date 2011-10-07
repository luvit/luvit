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
print = nil


-- Load libraries used in this file
local Table = require('table')
local UV = require('uv')
local Utils = require('utils')
local Env = require('env')

-- Load the I/O as streams
-- But don't hold the event loop open for them
stdin = UV.new_tty(0)
UV.unref()

-- Make a handy noop function for when needed
-- TODO: fix APIs so this isn't needed
function noop() end

-- A nice global data dumper
function p(...)
  local n = select('#', ...)
  local arguments = { ... }

  for i = 1, n do
    arguments[i] = Utils.dump(arguments[i])
  end

  stdin:write(Table.concat(arguments, "\t") .. "\n", noop)
end


-- Replace print
function print(...)
  stdin:write(Table.concat({...}, "\t") .. "\n", noop)
end

-- Add global access to the environment variables using a dynamic table
env = {}
setmetatable(env, {
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

-- Load the file given or start the interactive repl
if argv[1] then
  dofile(argv[1])
else
  require('repl')
end

-- Start the event loop
UV.run()

