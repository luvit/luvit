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

local table = require('table')

local utils = {}

local colors = {
  black   = "0;30",
  red     = "0;31",
  green   = "0;32",
  yellow  = "0;33",
  blue    = "0;34",
  magenta = "0;35",
  cyan    = "0;36",
  white   = "0;37",
  B        = "1;",
  Bblack   = "1;30",
  Bred     = "1;31",
  Bgreen   = "1;32",
  Byellow  = "1;33",
  Bblue    = "1;34",
  Bmagenta = "1;35",
  Bcyan    = "1;36",
  Bwhite   = "1;37"
}

if utils._useColors == nil then
  utils._useColors = true
end

function utils.color(color_name)
  if utils._useColors then
    return "\27[" .. (colors[color_name] or "0") .. "m"
  else
    return ""
  end
end

function utils.colorize(color_name, string, reset_name)
  return utils.color(color_name) .. tostring(string) .. utils.color(reset_name)
end

local escapes = { backslash = "\\\\", null = "\\0", newline = "\\n", carriage = "\\r",
  tab = "\\t", quote = '"', quote2 = '"', obracket = '[', cbracket = ']'
}

local colorized_escapes = {}

function utils.loadColors (n)
  if n ~= nil then utils._useColors = n end

  colorized_escapes["backslash"] = utils.colorize("Bgreen", escapes.backslash, "green")
  colorized_escapes["null"]      = utils.colorize("Bgreen", escapes.null, "green")
  colorized_escapes["newline"]   = utils.colorize("Bgreen", escapes.newline, "green")
  colorized_escapes["carriage"]  = utils.colorize("Bgreen", escapes.carriage, "green")
  colorized_escapes["tab"]       = utils.colorize("Bgreen", escapes.tab, "green")
  colorized_escapes["quote"]     = utils.colorize("Bgreen", escapes.quote, "green")
  colorized_escapes["quote2"]    = utils.colorize("Bgreen", escapes.quote2)
  for k,v in pairs(escapes) do
    if not colorized_escapes[k] then
      colorized_escapes[k] = utils.colorize("B", v)
    end
  end
end

utils.loadColors()

local function colorize_nop(color, obj)
  return obj
end

function utils.dump(o, depth, no_colorize)
  local _colorize_func
  local _escapes

  if no_colorize then
    _escapes = escapes
    colorize_func = colorize_nop
  else
    _escapes = colorized_escapes
    colorize_func = utils.colorize
  end

  local t = type(o)
  if t == 'string' then
    return _escapes.quote .. o:gsub("\\", _escapes.backslash):gsub("%z", _escapes.null):gsub("\n", _escapes.newline):gsub("\r", _escapes.carriage):gsub("\t", _escapes.tab) .. _escapes.quote2
  end
  if t == 'nil' then
    return colorize_func("Bblack", "nil")
  end
  if t == 'boolean' then
    return colorize_func("yellow", tostring(o))
  end
  if t == 'number' then
    return colorize_func("blue", tostring(o))
  end
  if t == 'userdata' then
    return colorize_func("magenta", tostring(o))
  end
  if t == 'thread' then
    return colorize_func("Bred", tostring(o))
  end
  if t == 'function' then
    return colorize_func("cyan", tostring(o))
  end
  if t == 'cdata' then
    return colorize_func("Bmagenta", tostring(o))
  end
  if t == 'table' then
    if type(depth) == 'nil' then
      depth = 0
    end
    if depth > 1 then
      return colorize_func("yellow", tostring(o))
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
          s = '[' .. utils.dump(k, 100, no_colorize) .. '] = '
        end
      end
      s = s .. utils.dump(v, depth + 1, no_colorize)
      lines[i] = s
      estimated = estimated + #s
      i = i + 1
    end
    if estimated > 200 then
      return "{\n  " .. indent .. table.concat(lines, ",\n  " .. indent) .. "\n" .. indent .. "}"
    else
      return "{ " .. table.concat(lines, ", ") .. " }"
    end
  end
  -- This doesn't happen right?
  return tostring(o)
end

-- Replace print
function utils.print(...)
  local n = select('#', ...)
  local arguments = { ... }

  for i = 1, n do
    arguments[i] = tostring(arguments[i])
  end

  process.stdout:write(table.concat(arguments, "\t") .. "\n")
end

-- A nice global data dumper
function utils.prettyPrint(...)
  local n = select('#', ...)
  local arguments = { ... }

  for i = 1, n do
    arguments[i] = utils.dump(arguments[i])
  end

  process.stdout:write(table.concat(arguments, "\t") .. "\n")
end

-- Like p, but prints to stderr using blocking I/O for better debugging
function utils.debug(...)
  local n = select('#', ...)
  local arguments = { ... }

  for i = 1, n do
    arguments[i] = utils.dump(arguments[i])
  end

  process.stderr:write(table.concat(arguments, "\t") .. "\n")
end

function utils.bind(fn, self, ...)
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

return utils

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
