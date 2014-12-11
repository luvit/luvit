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
local pathJoin = require('luvi').path.join
local Editor = require('readline').Editor
local History = require('readline').History

return function (stdin, stdout, greeting)

  local global = setmetatable({
    require = require('luvit-require')()(pathJoin(uv.cwd(), "repl"))
  }, {
    __index = _G
  })
  global._G = global

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
      setfenv(f, global)
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
        return '>> '
      else
        print(err)
        buffer = ''
      end
    end

    return '> '
  end

  local function completionCallback(line)
    local base, sep, rest = string.match(line, "^(.*)([.:])(.*)")
    if not base then
      rest = line
    end
    local prefix = string.match(rest, "^[%a_][%a%d_]*")
    if prefix and prefix ~= rest then return end
    local scope
    if base then
      local f = loadstring("return " .. base)
      setfenv(f, global)
      scope = f()
    else
      base = ''
      sep = ''
      scope = global
    end
    local matches = {}
    local prop = sep ~= ':'
    while type(scope) == "table" do
      for key, value in pairs(scope) do
        if (prop or (type(value) == "function")) and
           ((not prefix) or (string.match(key, "^" .. prefix))) then
          matches[key] = true
        end
      end
      scope = getmetatable(scope)
      scope = scope and scope.__index
    end
    local items = {}
    for key in pairs(matches) do
      items[#items + 1] = key
    end
    table.sort(items)
    if #items == 1 then
      return base .. sep .. items[1]
    elseif #items > 1 then
      return items
    end
  end

  local function start(historyLines, onSaveHistoryLines)
    local prompt = "> "
    local history = History.new()
    if history then
      history:load(historyLines)
    end
    local editor = Editor.new({
      stdin = stdin,
      stdout = stdout,
      completionCallback = completionCallback,
      history = history
    })

    local function onLine(err, line)
      assert(not err, err)
      if line then
        prompt = evaluateLine(line)
        editor:readLine(prompt, onLine)
        -- TODO: break out of >> with control+C
      elseif onSaveHistoryLines then
        onSaveHistoryLines(history:dump())
      end
    end

    editor:readLine(prompt, onLine)
  end

  return {
    start = start,
    evaluateLine = evaluateLine,
  }
end
