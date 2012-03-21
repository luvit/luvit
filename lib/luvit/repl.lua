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

local debug = require('debug')
local utils = require('utils')
local table = require('table')
local repl = {}
local c = utils.color

local function gatherResults(success, ...)
  local n = select('#', ...)
  return success, { n = n, ... }
end

local function printResults(results)
  for i = 1, results.n do
    results[i] = utils.dump(results[i])
  end
  print(table.concat(results, '\t'))
end

function repl.useColors(colors)
  if colors then
    c = utils.color
  else
    c = function (x) return "" end
  end
end

local buffer = ''

function repl.evaluateLine(line)
  if line == "<3\n" then
    print("I " .. c("Bred") .. "♥" .. c() .. " you too!")
    return '>'
  end
  local chunk  = buffer .. line
  local f, err = loadstring('return ' .. chunk, 'REPL') -- first we prefix return

  if not f then
    f, err = loadstring(chunk, 'REPL') -- try again without return
  end

  if f then
    buffer = ''
    local success, results = gatherResults(xpcall(f, debug.traceback))

    if success then
      -- successful call
      if results.n > 0 then
        printResults(results)
      end
    else
      -- error
      print(results[1])
    end
  else

    if err:match "'<eof>'$" then
      -- Lua expects some more input; stow it away for next time
      buffer = chunk .. '\n'
      return '>>'
    else
      print(err)
      buffer = ''
    end
  end

  return '>'
end

repl.colored_name = function()
  return c("Bred") .. "L" .. c("Bgreen") .. "uv" .. c("Bblue") .. "it" .. c()
end

function repl.start()
  --_oldprint("repl.start")
  local function displayPrompt(prompt)
    --_oldprint("display_prompt " .. prompt)
    process.stdout:write(prompt .. ' ', noop)
  end

  print(c("B") .. "Welcome to the " .. repl.colored_name() .. c("B") .. " repl" .. c())

  displayPrompt '>'


  process.stdin:on('data', function (line)
    local prompt = repl.evaluateLine(line)
    displayPrompt(prompt)
  end)

  process.stdin:on('end', function ()
    process.exit()
  end)

  process.stdin:readStart()
end

return repl
