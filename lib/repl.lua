local Debug = require('debug')
local UV = require('uv')
local Utils = require('utils')
local Table = require('table')

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

local function evaluate_line(line)
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


local function display_prompt(prompt)
  process.stdout:write(prompt .. ' ', noop)
end

local c = Utils.color

print(c("Bwhite") .. "Welcome to the " .. c("Bred") .. "L" .. c("Bgreen") .. "uv" .. c("Bblue") .. "it" .. c("Bwhite") .. " repl" .. c())

display_prompt '>'


process.stdin:on('data', function (line)
  local prompt = evaluate_line(line)
  display_prompt(prompt)
end)

process.stdin:on('end', function ()
  print(Utils.colorize("Bblue", "\nBye!"))
  process.exit()
end)

process.stdin:read_start()

