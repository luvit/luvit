local uv = require('uv')

local prettyPrint, dump, strip, color, colorize, initialize
local theme = {}
local useColors = false

local stdout = assert(uv.new_tty(1, false))
local width = uv.tty_get_winsize(stdout)

local quote, quote2, obracket, cbracket, obrace, cbrace, comma, equals, controls

local themes = {
  [16] = require('./theme-16.lua'),
  [256] = require('./theme-256.lua'),
}

local special = {
  [7] = 'a',
  [8] = 'b',
  [9] = 't',
  [10] = 'n',
  [11] = 'v',
  [12] = 'f',
  [13] = 'r'
}

function initialize(index)

  -- Remove the old theme
  for key in pairs(theme) do
    theme[key] = nil
  end

  if index then
    local new = themes[index]
    if not new then error("Invalid theme index: " .. tostring(index)) end
    -- Add the new theme
    for key in pairs(new) do
      theme[key] = new[key]
    end
    useColors = true
  else
    useColors = false
  end

  quote    = colorize('quotes', "'", 'string')
  quote2   = colorize('quotes', "'")
  obrace   = colorize('braces', '{')
  cbrace   = colorize('braces', '}')
  obracket = colorize('property', '[')
  cbracket = colorize('property', ']')
  comma    = colorize('sep', ',')
  equals   = colorize('sep', ' = ')

  controls = {}
  for i = 0, 31 do
    local c = special[i]
    if not c then
      if i < 10 then
        c = "00" .. tostring(i)
      else
        c = "0" .. tostring(i)
      end
    end
    controls[i] = colorize('escape', '\\' .. c, 'string')
  end


end

function color(colorName)
  return '\27[' .. (theme[colorName] or '0') .. 'm'
end

function colorize(colorName, string, resetName)
  return useColors and
    (color(colorName) .. tostring(string) .. color(resetName)) or
    tostring(string)
end

function dump(value)
  local seen = {}

  local function count(str)
    return str, #(strip(str))
  end

  local function dumper(o, depth)
    local t = type(o)
    if t == 'string' then
      return count(quote .. string.gsub(o, '%c', function (c)
        return controls[string.byte(c, 1)]
      end) .. quote2)
    end
    if t ~= 'table' or seen[o] then
      return count(colorize(t, tostring(o)))
    end

    seen[o] = true

    local parts = {}
    local sizes = {}
    local size = 0
    local i = 1
    for k, v in pairs(o) do
      local innerSize = 0
      local key = ""
      local extra
      if k ~= i then
        if type(k) == "string" and k:find("^[%a_][%a%d_]*$") then
          key = colorize("property", k) .. equals
          innerSize = innerSize + #(strip(key))
        else
          key, extra = dumper(k, depth + 1)
          key = obracket .. key .. cbracket .. equals
          -- +5 for 2 x brackets and equals with 2 x spaces
          innerSize = innerSize + extra + 5
        end
      end
      local part
      part, extra = dumper(v, depth + 1)
      innerSize = innerSize + extra
      parts[i] = key .. part
      sizes[i] = innerSize
      size = size + innerSize
      i = i + 1
    end
    -- (i-2)*2 for commas and spaces between values,
    --      +4 for braces
    ---------- reduces to
    --   i * 2
    size = size + i * 2
    local max = width - depth * 2
    if size <= max then
      return obrace .. ' ' .. table.concat(parts, comma .. ' ') .. ' ' .. cbrace, size
    end

    local lines = {}
    local line = {}
    max = max - 3 -- two for indent and 1 for trailing commas
    local left = max
    for j = 1, #parts do
      if left < sizes[j] then
        if #line > 0 then
          lines[#lines + 1] = line
        end
        left = max
        line = {}
      end
      line[#line + 1] = parts[j]
      left = left - sizes[j] - 2
    end
    for j = 1, #lines do
      lines[j] = table.concat(lines[j], comma .. " ")
    end

    return obrace .. '\n  ' .. table.concat(lines, comma .. '\n  ') .. '\n' .. cbrace, size
  end
  local output = dumper(value, 0)
  return output
end

-- Print replacement that goes through libuv.  This is useful on windows
-- to use libuv's code to translate ansi escape codes to windows API calls.
function print(...)
  uv.write(stdout, table.concat({...}, "\t") .. "\n")
end

function prettyPrint(...)
  local n = select('#', ...)
  local arguments = { ... }

  for i = 1, n do
    arguments[i] = dump(arguments[i])
  end

  print(table.concat(arguments, "\t"))
end

function strip(str)
  return string.gsub(str, '\027%[[^m]*m', '')
end

return {
  initialize = initialize,
  theme = theme,
  print = print,
  prettyPrint = prettyPrint,
  dump = dump,
  color = color,
  colorize = colorize,
  stdout = stdout,
}
