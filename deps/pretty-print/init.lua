--[[

Copyright 2014-2015 The Luvit Authors. All Rights Reserved.

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
exports.name = "luvit/pretty-print"
exports.version = "0.1.0"

local uv = require('uv')
local env = require('env')

local prettyPrint, dump, strip, color, colorize, loadColors
local theme = {}
local useColors = false
local defaultTheme

local stdout, stdin, stderr, width

local quote, quote2, dquote, dquote2, obracket, cbracket, obrace, cbrace, comma, equals, controls

local themes = {
  [16] = require('./16.lua'),
  [256] = require('./256.lua'),
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

function strip(str)
  return string.gsub(str, '\027%[[^m]*m', '')
end


function loadColors(index)
  if index == nil then index = defaultTheme end

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
  dquote    = colorize('quotes', '"', 'string')
  dquote2   = colorize('quotes', '"')
  obrace   = colorize('braces', '{ ')
  cbrace   = colorize('braces', '}')
  obracket = colorize('property', '[')
  cbracket = colorize('property', ']')
  comma    = colorize('sep', ', ')
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
  controls[92] = colorize('escape', '\\\\', 'string')
  controls[34] = colorize('escape', '\\"', 'string')
  controls[39] = colorize('escape', "\\'", 'string')
  for i = 128, 255 do
    local c
    if i < 100 then
      c = "0" .. tostring(i)
    else
      c = tostring(i)
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

local function stringEscape(c)
  return controls[string.byte(c, 1)]
end

function dump(value)
  local seen = {}
  local output = {}
  local offset = 0
  local stack = {}

  local function recalcOffset(index)
    for i = index + 1, #output do
      local m = string.match(output[i], "\n([^\n]*)$")
      if m then
        offset = #(strip(m))
      else
        offset = offset + #(strip(output[i]))
      end
    end
  end

  local function write(text, length)
    if not length then length = #(strip(text)) end
    -- Create room for data by opening parent blocks
    -- Start at the root and go down.
    local i = 1
    while offset + length > width and stack[i] do
      local entry = stack[i]
      if not entry.opened then
        entry.opened = true
        table.insert(output, entry.index + 1, "\n" .. string.rep("  ", i))
        -- Recalculate the offset
        recalcOffset(entry.index)
        -- Bump the index of all deeper entries
        for j = i + 1, #stack do
          stack[j].index = stack[j].index + 1
        end
      end
      i = i + 1
    end
    output[#output + 1] = text
    offset = offset + length
    if offset > width then
      dump(stack)
    end
  end

  local function indent()
    stack[#stack + 1] = {
      index = #output,
      opened = false,
    }
  end

  local function unindent()
    stack[#stack] = nil
  end

  local function process(value)
    local typ = type(value)
    if typ == 'string' then
      if string.match(value, "'") and not string.match(value, '"') then
        write(dquote .. string.gsub(value, '[%c\\\128-\255]', stringEscape) .. dquote2)
      else
        write(quote .. string.gsub(value, "[%c\\'\128-\255]", stringEscape) .. quote2)
      end
    elseif typ == 'table' and not seen[value] then

      seen[value] = true
      write(obrace)
      local i = 1
      -- Count the number of keys so we know when to stop adding commas
      local total = 0
      for _ in pairs(value) do total = total + 1 end

      for k, v in pairs(value) do
        indent()
        if k == i then
          -- if the key matches the index, don't show it.
          -- This is how lists print without keys
          process(v)
        else
          if type(k) == "string" and string.find(k,"^[%a_][%a%d_]*$") then
            write(colorize("property", k) .. equals)
          else
            write(obracket)
            process(k)
            write(cbracket .. equals)
          end
          if type(v) == "table" then
            process(v)
          else
            indent()
            process(v)
            unindent()
          end
        end
        if i < total then
          write(comma)
        else
          write(" ")
        end
        i = i + 1
        unindent()
      end
      write(cbrace)
    else
      write(colorize(typ, tostring(value)))
    end
  end

  process(value)

  return table.concat(output, "")
end

-- Print replacement that goes through libuv.  This is useful on windows
-- to use libuv's code to translate ansi escape codes to windows API calls.
function _G.print(...)
  local n = select('#', ...)
  local arguments = {...}
  for i = 1, n do
    arguments[i] = tostring(arguments[i])
  end
  uv.write(stdout, table.concat(arguments, "\t") .. "\n")
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

if uv.guess_handle(0) == 'tty' then
  stdin = assert(uv.new_tty(0, true))
else
  stdin = uv.new_pipe(false)
  uv.pipe_open(stdin, 0)
end

if uv.guess_handle(1) == 'tty' then
  stdout = assert(uv.new_tty(1, false))
  width = uv.tty_get_winsize(stdout)
  -- auto-detect when 16 color mode should be used
  local term = env.get("TERM")
  if term == 'xterm' or term == 'xterm-256color' then
    defaultTheme = 256
  else
    defaultTheme = 16
  end
else
  stdout = uv.new_pipe(false)
  uv.pipe_open(stdout, 1)
  width = 80
end
loadColors()

if uv.guess_handle(2) == 'tty' then
  stderr = assert(uv.new_tty(2, false))
else
  stderr = uv.new_pipe(false)
  uv.pipe_open(stderr, 2)
end

exports.loadColors = loadColors
exports.theme = theme
exports.print = print
exports.prettyPrint = prettyPrint
exports.dump = dump
exports.color = color
exports.colorize = colorize
exports.stdin = stdin
exports.stdout = stdout
exports.stderr = stderr
exports.strip = strip
