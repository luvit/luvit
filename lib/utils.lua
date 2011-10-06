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

function color(string, color_name, reset_name)
  local color = colors[color_name] or "0"
  if (reset_name) then
    local reset_color = colors[reset_name]
    return "\27[" .. color .. "m" .. string .. "\27[" .. reset_color .. "m"
  else
    return "\27[" .. color .. "m" .. string .. "\27[0m"
  end
end

function dump(o, depth)
  if type(depth) == 'nil' then
    depth = 0
  end
  local indent = ("  "):rep(depth)
  if type(o) == 'nil' then
    return color("nil", "Bblack")
  end
  if type(o) == 'boolean' then
    return color(tostring(o), "yellow")
  end
  if type(o) == 'number' then
    return color(tostring(o), "blue")
  end
  if type(o) == 'string' then
    return color('"', "Bgreen", "green") .. o:gsub("\\", color("\\\\", "Bgreen", green)):gsub("%z", color("\\0", "Bgreen", "green")):gsub("\n",color("\\n", "Bgreen", "green")):gsub("\r",color("\\r", "Bgreen", "green")):gsub("\t",color("\\t", "Bgreen", "green")) .. color('"', "Bgreen")
  end
  if type(o) == 'table' then
    if (depth > 1) then
      return color(tostring(o), "yellow")
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
          s = s .. color('[', "white") .. dump(k, 100) ..color(']', "white") .. ' = '
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
    return color(tostring(o), "magenta")
  end
  if type(o) == 'thread' then
    return color(tostring(o), "Bred")
  end
  if type(o) == 'function' then
    return color(tostring(o), "cyan")
  end
  -- This doesn't happen right?
  return tostring(o)
end


return {
  dump = dump,
  color = color
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
--  [print] = {{"deep"},{{"nesting"}},3,4,5},
--  [{1,2,3}] = {4,5,6}
--}))
