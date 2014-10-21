--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

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

local uv = require('uv')
local utils = require('utils')

return function (stdin, stdout, greeting)

  if greeting then print(greeting) end

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

  local buffer = ''

  local function evaluateLine(line)
    if line == "<3\n" or line == "♥\n" then
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

  local function displayPrompt(prompt)
    uv.write(stdout, prompt .. ' ')
  end

  displayPrompt '>'

  uv.read_start(stdin, function (_, err, line)
    assert(not err, err)
    if line then
      local prompt = evaluateLine(line)
      displayPrompt(prompt)
    else
      uv.write(stdout, "\n")
    end
  end)

end
