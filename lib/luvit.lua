-- Dump args to the screen for debugging
function p(...)
  local n = select('#', ...)
  local arguments = { ... }
  local dump = require('utils').dump

  for i = 1, n do
    arguments[i] = dump(arguments[i])
  end

  print(table.concat(arguments, "\t"))
end


if process.argv[1] then
  dofile(process.argv[1])
else

  local dump = require('utils').dump

  local function gather_results(success, ...)
    local n = select('#', ...)
    return success, { n = n, ... }
  end

  local function print_results(results)
    for i = 1, results.n do
      results[i] = dump(results[i])
    end
    print(table.concat(results, '\t'))
  end


  do
    local buffer = ''

    function evaluate_line(line)
      local chunk  = buffer .. line
      local f, err = loadstring('return ' .. chunk, 'REPL') -- first we prefix return

      if not f then
        f, err = loadstring(chunk, 'REPL') -- try again without return
      end

      if f then
        buffer = ''
        local success, results = gather_results(xpcall(f, debug.traceback))

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
  end

  local UV = require('uv');

  local stdout = UV.new_tty(1);
  local function noop() end


  function display_prompt(prompt)
    stdout:write(prompt .. ' ', noop)
  end

  stdout:write("Welcome to the luvit repl\n", noop)

  display_prompt '>'


  local stdin = UV.new_tty(0)
  UV.set_handler(stdin, 'read', function (line)
    local prompt = evaluate_line(line)
    display_prompt(prompt)
  end)

  UV.set_handler(stdin, 'end', function ()
    print("Bye!")
    UV.close(stdin)
    UV.close(stdout)
  end)

  UV.read_start(stdin)
end

require('uv').run()

