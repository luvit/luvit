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

local yajl = require('yajl')
local table = require('table')
local JSON = {
  null = yajl.null
}

function JSON.parse(string, options)
  local root = {}
  local current = root
  local key
  local null = JSON.null
  local stack = {}
  local null = options and options.use_null and JSON.null
  local parser = yajl.newParser({
    onNull = function ()
      current[key or #current + 1] = null
    end,
    onBoolean = function (value)
      current[key or #current + 1] = value
    end,
    onNumber = function (value)
      current[key or #current + 1] = value
    end,
    onString = function (value)
      current[key or #current + 1] = value
    end,
    onStartMap = function ()
      local new = {}
      table.insert(stack, current)
      current[key or #current + 1] = new
      key = nil
      current = new
    end,
    onMapKey = function (value)
      key = value
    end,
    onEndMap = function ()
      key = nil
      current = table.remove(stack)
    end,
    onStartArray = function ()
      local new = {}
      table.insert(stack, current)
      current[key or #current + 1] = new
      key = nil
      current = new
    end,
    onEndArray = function ()
      current = table.remove(stack)
    end
  })
  if options then
    options.use_null = nil
    if options then
      for k,v in pairs(options) do
        parser:config(k, v)
      end
    end
  end
  parser:parse(string)
  parser:complete()
  return unpack(root)
end

function JSON.stringify(value, options)
  local generator = yajl.newGenerator();
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
          if not (type(k) == "string") then
            error("Keys must be strings to stringify as JSON")
          end
          generator:string(k)
          add(v)
        end
        generator:mapClose()
      end
    else
      error("Cannot stringify " .. type .. " value")
    end
  end
  add(value)
  return generator:getBuf()
end

return JSON
