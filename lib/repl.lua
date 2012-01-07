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

local Debug = require('debug')
local UV = require('uv')
local Utils = require('utils')
local Table = require('table')
local Repl = {}
local c = Utils.color

local function gather_results(success, ...)
  local n = select('#', ...)
  return success, { n = n, ... }
end

local function print_results(results)
  for i = 1, results.n do
    results[i] = Utils.dump(results[i])
  end
  print(Table.concat(results, '\t'))
end

local buffer = ''

function Repl.evaluate_line(line)
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
    local success, results = gather_results(xpcall(f, Debug.traceback))

    if success then
      -- successful call
      if results.n > 0 then
        print_results(results)
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
    end
  end

  return '>'
end

Repl.colored_name = c("Bred") .. "L" .. c("Bgreen") .. "uv" .. c("Bblue") .. "it" .. c()

function Repl.start()
  local function display_prompt(prompt)
    process.stdout:write(prompt .. ' ', noop)
  end


  print(c("Bwhite") .. "Welcome to the " .. Repl.colored_name .. c("Bwhite") .. " repl" .. c())

  display_prompt '>'


  process.stdin:on('data', function (line)
    local prompt = Repl.evaluate_line(line)
    display_prompt(prompt)
  end)

  process.stdin:on('end', function ()
    process.exit()
  end)

  process.stdin:read_start()
end

return Repl
