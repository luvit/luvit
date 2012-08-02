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

local coroutine = require('coroutine')
local debug = require 'debug'
local fiber = {}

function fiber.new(block, callback)
  local paused
  local co = coroutine.create(block)

  local function formatError(err)
    local stack = debug.traceback(co, tostring(err))
    if type(err) == "table" then
      err.message = stack
      return err
    end
    return stack
  end

  local function check(success, ...)
    if not success then
      if callback then
        return callback(formatError(...))
      else
        error(formatError(...))
      end
    end
    if not paused then
      return callback and callback(nil, ...)
    end
    paused = false
  end

  local function wait(fn, ...)
    if type(fn) ~= "function" then
      error("can only wait on functions")
    end
    local args = {...}
    args[#args + 1] = function (...)
      check(coroutine.resume(co, ...))
    end
    fn(unpack(args))
    paused = true
    return coroutine.yield()
  end

  local function wrap(fn, handleErrors)

    if type(fn) == "table" then
      return setmetatable({}, {
        __index = function (table, key)
          return fn[key] and wrap(fn[key], handleErrors)
        end
      })
    end

    if type(fn) ~= "function" then
      error("Can only wrap functions or tables of functions")
    end
    -- Do a simple curry for the passthrough wait wrapper
    if not handleErrors then
      return function (...)
        return wait(fn, ...)
      end
    end

    -- Or magically pull out the error argument and throw it if it's there.
    -- Return all other values if no error.
    return function (...)
      local result = {wait(fn, ...)}
      local err = result[1]
      if err then error(err) end
      return unpack(result, 2)
    end

  end

  check(coroutine.resume(co, wrap, wait))

end

return fiber

