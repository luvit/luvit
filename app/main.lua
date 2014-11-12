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

local luvi = require('luvi')
local bundle = luvi.bundle

-- Manually register the require replacement system to bootstrap things
bundle.register("luvit-require", "modules/require.lua");
-- Upgrade require system in-place
_G.require = require('luvit-require')()("bundle:modules/main.lua")

local uv = require('uv')
local utils = require('utils')
-- Make print go through libuv for windows colors
_G.print = utils.print
-- Register global 'p' for easy pretty printing
_G.p = utils.prettyPrint

local startRepl = nil
local combo = nil
local script = nil
local extra = {}

local function usage()
  print("Usage: " .. args[0] .. " [options] script.lua [arguments]"..[[


Options:
  -h, --help          Print this help screen.
  -v, --version       Print the version.
  -e code_chunk       Evaluate code chunk and print result.
  -i, --interactive   Enter interactive repl after executing script.
  -n, --no-color      Disable colors.
  -c, --16-colors     Use simple ANSI colors
  -C, --256-colors    Use 256-mode ANSI colors
                      (Note, if no script is provided, a repl is run instead.)
]])
  startRepl = false
end

local function version()
  print("TODO: show luvit version")
  startRepl = false
end


local shorts = {
  h = "help",
  v = "version",
  e = "eval",
  i = "interactive",
  n = "no-color",
  c = "16-colors",
  C = "256-colors",
}

local flags = {
  help = usage,
  version = version,
  eval = function ()
    local repl = require('repl')(utils.stdin, utils.stdout)
    combo = repl.evaluateLine
    startRepl = false
  end,
  interactive = function ()
    startRepl = true
  end,
  ["no-color"] = function ()
    utils.loadColors()
  end,
  ["16-colors"] = function ()
    utils.loadColors(16)
  end,
  ["256-colors"] = function ()
    utils.loadColors(256)
  end,
}

for i = 1, #args do
  local arg = args[i]
  if script then
    extra[#extra + 1] = arg
  elseif combo then
    combo(arg)
    combo = nil
  elseif string.sub(arg, 1, 1) == "-" then
    local flag
    if (string.sub(arg, 2, 2) == "-") then
      flag = string.sub(arg, 3)
    else
      arg = string.sub(arg, 2)
      flag = shorts[arg] or arg
    end
    local fn = flags[flag] or usage
    fn()
  else
    script = arg
  end
end

if combo then error("Missing flag value") end

if startRepl == nil and not script then startRepl = true end

-- Seed Lua's RNG
do
  local math = require('math')
  local os = require('os')
  math.randomseed(os.clock())
end

if script then
  require(luvi.path.join(uv.cwd(), script))
end

if startRepl then
  local c = utils.color
  local greeting = "Welcome to the " .. c("err") .. "L" .. c("quotes") .. "uv" .. c("table") .. "it" .. c() .. " repl!"
  require('repl')(utils.stdin, utils.stdout, greeting, ...).start()
end

-- Start the event loop
uv.run()

require('hooks'):emit('process.exit')
uv.run()

-- When the loop exits, close all uv handles.
uv.walk(uv.close)
uv.run()
