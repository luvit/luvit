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

exports.name = "luvit/utils"
exports.version = "0.1.0"

local pp = require('pretty-print')
for name, value in pairs(pp) do
  exports[name] = value
end

local function bind(fn, self, ...)
  local bindArgsLength = select("#", ...)

  -- Simple binding, just inserts self (or one arg or any kind)
  if bindArgsLength == 0 then
    return function (...)
      return fn(self, ...)
    end
  end

  -- More complex binding inserts arbitrary number of args into call.
  local bindArgs = {...}
  return function (...)
    local argsLength = select("#", ...)
    local args = {...}
    local arguments = {}
    for i = 1, bindArgsLength do
      arguments[i] = bindArgs[i]
    end
    for i = 1, argsLength do
      arguments[i + bindArgsLength] = args[i]
    end
    return fn(self, unpack(arguments, 1, bindArgsLength + argsLength))
  end
end

local function noop(err)
  if err then print("Unhandled callback error", err) end
end

local function adapt(c, fn, ...)
  local nargs = select('#', ...)
  local args = {...}
  -- No continuation defaults to noop callback
  if not c then c = noop end
  local t = type(c)
  if t == 'function' then
    args[nargs + 1] = c
    return fn(unpack(args))
  elseif t ~= 'thread' then
    error("Illegal continuation type " .. t)
  end
  local err, data, waiting
  args[nargs + 1] = function (e, ...)
    if waiting then
      if e then
        assert(coroutine.resume(c, nil, e))
      else
        assert(coroutine.resume(c, ...))
      end
    else
      err, data = e, {...}
      c = nil
    end
  end
  fn(unpack(args))
  if c then
    waiting = true
    return coroutine.yield(c)
  elseif err then
    return nil, err
  else
    return unpack(data)
  end
end

exports.bind = bind
exports.noop = noop
exports.adapt = adapt
