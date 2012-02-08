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

local Yajl = require('yajl')
local table = require('table')
local JSON = {
  null = Yajl.null
}

function JSON.streamingParser(callback, options)
  local current
  local key
  local stack = {}
  local null
  if options and options.use_null then
    null = Yajl.null
    options.use_null = nil
  end
  local function emit(value, open, close)
    if current then
      current[key or #current + 1] = value
    else
      callback(value)
    end
  end
  function open(value)
    if current then
      current[key or #current + 1] = value
    end
  end
  function close(value)
    if not current then
      callback(value)
    end
  end
  local parser = Yajl.newParser({
    onNull = function ()
      emit(null)
    end,
    onBoolean = function (value)
      emit(value)
    end,
    onNumber = function (value)
      emit(value)
    end,
    onString = function (value)
      emit(value)
    end,
    onStartMap = function ()
      local new = {}
      open(new)
      table.insert(stack, current)
      key = nil
      current = new
    end,
    onMapKey = function (value)
      key = value
    end,
    onEndMap = function ()
      key = nil
      local map = current
      current = table.remove(stack)
      close(map)
    end,
    onStartArray = function ()
      local new = {}
      open(new)
      table.insert(stack, current)
      key = nil
      current = new
    end,
    onEndArray = function ()
      local array = current
      current = table.remove(stack)
      close(array)
    end
  })
  if options then
    for k,v in pairs(options) do
      parser:config(k, v)
    end
  end
  return parser
end


function JSON.parse(string, options)
  local values = {}
  local parser = JSON.streamingParser(function (value)
    table.insert(values, value)
  end, options)
  parser:parse(string)
  parser:complete()
  return unpack(values)
end

function JSON.stringify(value, options)
  local generator = Yajl.newGenerator();
  if options then
    for k,v in pairs(options) do
      generator:config(k, v)
    end
  end

  function add(o)
    local t = type(o)
    if t == 'nil' or o == JSON.null then
      generator:null()
    elseif t == "boolean" then
      generator:boolean(o)
    elseif t == "number" then
      generator:number(o)
    elseif t == "string" then
      generator:string(o)
    elseif t == "table" then
      -- Check to see if this is an array
      local is_array = true
      local i = 1
      for k,v in pairs(o) do
        if not (k == i) then
          is_array = false
        end
        i = i + 1
      end
      if is_array then
        generator:arrayOpen()
        for i,v in ipairs(o) do
          add(v)
        end
        generator:arrayClose()
      else
        generator:mapOpen()
        for k,v in pairs(o) do
          if not (type(k) == "string" or type(k) == "number") then
            error("Keys must be strings to stringify as JSON")
          end
          generator:string(k)
          add(v)
        end
        generator:mapClose()
      end
    else
      error("Cannot stringify " .. t .. " value")
    end
  end
  add(value)
  return generator:getBuf()
end

return JSON
