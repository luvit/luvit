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
local Table = require('table')
local JSON = {
  null = Yajl.null
}

function JSON.parse(string, options)
  local root = {}
  local current = root
  local key
  local null = JSON.null
  local stack = {}
  local null = options and options.use_null and JSON.null
  local parser = Yajl.new_parser({
    on_null = function ()
      current[key or #current + 1] = null
    end,
    on_boolean = function (value)
      current[key or #current + 1] = value
    end,
    on_number = function (value)
      current[key or #current + 1] = value
    end,
    on_string = function (value)
      current[key or #current + 1] = value
    end,
    on_start_map = function ()
      local new = {}
      Table.insert(stack, current)
      current[key or #current + 1] = new
      key = nil
      current = new
    end,
    on_map_key = function (value)
      key = value
    end,
    on_end_map = function ()
      key = nil
      current = Table.remove(stack)
    end,
    on_start_array = function ()
      local new = {}
      Table.insert(stack, current)
      current[key or #current + 1] = new
      key = nil
      current = new
    end,
    on_end_array = function ()
      current = Table.remove(stack)
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
  local generator = Yajl.new_generator();
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
        generator:array_open()
        for i,v in ipairs(o) do
          add(v)
        end
        generator:array_close()
      else
        generator:map_open()
        for k,v in pairs(o) do
          if not (type(k) == "string") then
            error("Keys must be strings to stringify as JSON")
          end
          generator:string(k)
          add(v)
        end
        generator:map_close()
      end
    else
      error("Cannot stringify " .. type .. " value")
    end
  end
  add(value)
  return generator:get_buf()
end

return JSON
