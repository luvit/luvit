local Yajl = require('yajl')
local Table = require('table')
local JSON = {}

function JSON.parse(string)
  local root = {}
  local current = root
  local key
  local null = JSON.null
  local stack = {}
  local parser = Yajl.new({
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
      current = new
    end,
    on_end_array = function ()
      current = Table.remove(stack)
    end
  })
  parser:parse(string)
  return root[1]
end

return JSON