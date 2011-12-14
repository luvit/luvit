local Table = require('table')

local colors = {
  black   = "0;30",
  red     = "0;31",
  green   = "0;32",
  yellow  = "0;33",
  blue    = "0;34",
  magenta = "0;35",
  cyan    = "0;36",
  white   = "0;37",
  Bblack   = "1;30",
  Bred     = "1;31",
  Bgreen   = "1;32",
  Byellow  = "1;33",
  Bblue    = "1;34",
  Bmagenta = "1;35",
  Bcyan    = "1;36",
  Bwhite   = "1;37"
}

local function color(color_name)
  return "\27[" .. (colors[color_name] or "0") .. "m"
end

local function colorize(color_name, string, reset_name)
  return color(color_name) .. string .. color(reset_name)
end

local backslash = colorize("Bgreen", "\\\\", "green")
local null      = colorize("Bgreen", "\\0", "green")
local newline   = colorize("Bgreen", "\\n", "green")
local carraige  = colorize("Bgreen", "\\r", "green")
local tab       = colorize("Bgreen", "\\t", "green")
local quote     = colorize("Bgreen", '"', "green")
local quote2    = colorize("Bgreen", '"')
local obracket  = colorize("white", '[')
local cbracket  = colorize("white", ']')

local function dump(o, depth)
  local t = type(o)
  if t == 'string' then
    return quote .. o:gsub("\\", backslash):gsub("%z", null):gsub("\n", newline):gsub("\r", carraige):gsub("\t", tab) .. quote2
  end
  if t == 'nil' then
    return colorize("Bblack", "nil")
  end
  if t == 'boolean' then
    return colorize("yellow", tostring(o))
  end
  if t == 'number' then
    return colorize("blue", tostring(o))
  end
  if t == 'userdata' then
    return colorize("magenta", tostring(o))
  end
  if t == 'thread' then
    return colorize("Bred", tostring(o))
  end
  if t == 'function' then
    return colorize("cyan", tostring(o))
  end
  if t == 'cdata' then
    return colorize("Bmagenta", tostring(o))
  end
  if t == 'table' then
    if type(depth) == 'nil' then
      depth = 0
    end
    if depth > 1 then
      return colorize("yellow", tostring(o))
    end
    local indent = ("  "):rep(depth)

    -- Check to see if this is an array
    local is_array = true
    local i = 1
    for k,v in pairs(o) do
      if not (k == i) then
        is_array = false
      end
      i = i + 1
    end

    local first = true
    local lines = {}
    i = 1
    local estimated = 0
    for k,v in (is_array and ipairs or pairs)(o) do
      local s
      if is_array then
        s = ""
      else
        if type(k) == "string" and k:find("^[%a_][%a%d_]*$") then
          s = k .. ' = '
        else
          s = '[' .. dump(k, 100) .. '] = '
        end
      end
      s = s .. dump(v, depth + 1)
      lines[i] = s
      estimated = estimated + #s
      i = i + 1
    end
    if estimated > 200 then
      return "{\n  " .. indent .. Table.concat(lines, ",\n  " .. indent) .. "\n" .. indent .. "}"
    else
      return "{ " .. Table.concat(lines, ", ") .. " }"
    end
  end
  -- This doesn't happen right?
  return tostring(o)
end

local user_proto = {}

function user_proto.add_handler_type(emitter, name)
  emitter.userdata:set_handler(name, function (...)
    emitter:emit(name, ...)
  end)
end

-- Shared metatable for all userdata type wrappers
local user_meta = {
  __index = function (table, key)
    return table.prototype[key] or user_proto[key] or table.userdata[key]
  end,
  __newindex = rawset
}

return {
  dump = dump,
  color = color,
  colorize = colorize,
  user_meta = user_meta,
  user_proto = user_proto,
}

--print("nil", dump(nil))

--print("number", dump(42))

--print("boolean", dump(true), dump(false))

--print("string", dump("\"Hello\""), dump("world\nwith\r\nnewlines\r\t\n"))

--print("funct", dump(print))

--print("table", dump({
--  ["nil"] = nil,
--  ["8"] = 8,
--  ["number"] = 42,
--  ["boolean"] = true,
--  ["table"] = {age = 29, name="Tim"},
--  ["string"] = "Another String",
--  ["function"] = dump,
--  ["thread"] = coroutine.create(dump),
--  [print] = {{"deep"},{{"nesting"}},3,4,5},
--  [{1,2,3}] = {4,5,6}
--}))
