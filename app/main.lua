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

-- Start the Luvit REPL
local utils = require('utils')
local repl = require('repl')
local c = utils.color
local greeting = "Welcome to the " .. c("Bred") .. "L" .. c("Bgreen") .. "uv" .. c("Bblue") .. "it" .. c() .. " repl!"
repl(utils.stdin, utils.stdout, greeting)

-- Start the event loop
uv.run()

-- When the loop exits, close all uv handles.
uv.walk(uv.close)
uv.run()
