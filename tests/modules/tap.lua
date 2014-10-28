local uv = require('uv')
local utils = require('utils')
local stdin = utils.stdin
local stdout = utils.stdout
local stderr = utils.stderr
local colorize = utils.colorize

-- Capture output from global print and prefix with two spaces
local print = _G.print
_G.print = function (...)
  local n = select('#', ...)
  local arguments = {...}
  for i = 1, n do
    arguments[i] = tostring(arguments[i])
  end

  local text = table.concat(arguments, "\t")
  text = "  " .. string.gsub(text, "\n", "\n  ")
  print(text)
end

local tests = {};

local function run()
  local passed = 0

  if #tests < 1 then
    error("No tests specified!")
  end

  print("1.." .. #tests)
  for i = 1, #tests do
    local test = tests[i]
    local cwd = uv.cwd()
    print("\n# Starting Test: " .. colorize("highlight", test.name))
    local pass, err = xpcall(function ()
      local expected = 0
      local function expect(fn, count)
        expected = expected + (count or 1)
        return function (...)
          expected = expected - 1
          local ret = fn(...)
          collectgarbage()
          return ret
        end
      end
      test.fn(expect)
      collectgarbage()
      uv.run()
      collectgarbage()
      if expected > 0 then
        error("Missing " .. expected .. " expected call" .. (expected == 1 and "" or "s"))
      elseif expected < 0 then
        error("Found " .. -expected .. " unexpected call" .. (expected == -1 and "" or "s"))
      end
      collectgarbage()
      local unclosed = 0
      uv.walk(function (handle)
        if handle == stdout or handle == stderr or handle == stdin then return end
        unclosed = unclosed + 1
        print("UNCLOSED", handle)
      end)
      if unclosed > 0 then
        error(unclosed .. " unclosed handle" .. (unclosed == 1 and "" or "s"))
      end
      if uv.cwd() ~= cwd then
        error("Test moved cwd from " .. cwd .. " to " .. uv.cwd())
      end
      collectgarbage()
    end, debug.traceback)

    -- Flush out any more opened handles
    uv.run()
    uv.walk(function (handle)
      if handle == stdout or handle == stderr or handle == stdin then return end
      uv.close(handle)
    end)
    uv.run()
    uv.chdir(cwd)

    if pass then
      print("ok " .. i .. " " .. colorize("success", test.name))
      passed = passed + 1
    else
      _G.print(colorize("err", err))
      print("not ok " .. i .. " " .. colorize("failure", test.name))
    end
  end

  local failed = #tests - passed
  if failed == 0 then
    print("# All tests passed")
  else
    print("#" .. failed .. " failed test" .. (failed == 1 and "" or "s"))
  end

  -- Close all then handles, including stdout
  uv.walk(uv.close)
  uv.run()

  os.exit(-failed)
end

local single = true
local prefix

local function tap(suite)

  if type(suite) == "function" then
    -- Pass in suite directly for single mode
    suite(function (name, fn)
      if prefix then
        name = prefix .. ' - ' .. name
      end
      tests[#tests + 1] = {
        name = name,
        fn = fn
      }
    end)
    prefix = nil
  elseif type(suite) == "string" then
    prefix = suite
    single = false
  else
    -- Or pass in false to collect several runs of tests
    -- And then pass in true in a later call to flush tests queue.
    single = suite
  end

  if single then run() end

end

return tap
