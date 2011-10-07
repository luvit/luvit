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
  if type(depth) == 'nil' then
    depth = 0
  end
  local indent = ("  "):rep(depth)
  if type(o) == 'nil' then
    return colorize("Bblack", "nil")
  end
  if type(o) == 'boolean' then
    return colorize("yellow", tostring(o))
  end
  if type(o) == 'number' then
    return colorize("blue", tostring(o))
  end
  if type(o) == 'string' then
    return quote .. o:gsub("\\", backslash):gsub("%z", null):gsub("\n", newline):gsub("\r", carraige):gsub("\t", tab) .. quote2
  end
  if type(o) == 'table' then
    if (depth > 1) then
      return colorize("yellow", tostring(o))
    end

    -- Check to see if this is an array
    local is_array = true
    local i = 1
    for k,v in pairs(o) do
      if not (k == i) then
        is_array = false
      end
      i = i + 1
    end

    local s = '{'
    local first = true
    for k,v in pairs(o) do
      if first then
        first = false
      else
        s = s .. ","
      end
      s = s .. "\255"
      if not is_array then
        if type(k) == "string" and k:find("^[%a_][%a%d_]*$") then
          s = s .. k .. ' = '
        else
          s = s .. '[' .. dump(k, 100) .. '] = '
        end
      end
      s = s .. dump(v, depth + 1)
    end
    if (#s > 200) then
      return s:gsub("\255", "\n" .. indent .. "  ") .. "\n" .. indent .. "}"
    else
      return s:gsub("\255", " ") .. " }"
    end
  end
  if type(o) == 'userdata' then
    return colorize("magenta", tostring(o))
  end
  if type(o) == 'thread' then
    return colorize("Bred", tostring(o))
  end
  if type(o) == 'function' then
    return colorize("cyan", tostring(o))
  end
  -- This doesn't happen right?
  return tostring(o)
end


return {
  dump = dump,
  color = color,
  colorize = colorize
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
