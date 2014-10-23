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
local luvi = require('luvi')
local bundle = luvi.bundle

-- Register all modules in "modules" as global modules.
local files = bundle.readdir("modules")
for i = 1, #files do
  local file = files[i]
  local path = "modules/" .. file
  local name = string.sub(file, 1, #file - 4)
  bundle.register(name, path)
end

local utils = require('utils')

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
  n = "no-color"
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
    utils.loadColors(false)
  end
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
      flag = shorts[string.sub(arg, 2)]
    end
    flags[flag]()
  else
    script = arg
  end
end

if combo then error("Missing flag value") end

if startRepl == nil and not script then startRepl = true end

if script then
  loadfile(luvi.path.join(uv.cwd(), script))(unpack(extra))
end

if startRepl then
  local c = utils.color
  local greeting = "Welcome to the " .. c("Bred") .. "L" .. c("Bgreen") .. "uv" .. c("Bblue") .. "it" .. c() .. " repl!"
  require('repl')(utils.stdin, utils.stdout, greeting, ...).start()
end

-- Start the event loop
uv.run()

-- When the loop exits, close all uv handles.
uv.walk(uv.close)
uv.run()
