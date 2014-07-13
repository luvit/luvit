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

require("helper")
local path = require('path')
local fs = require('fs')
local core = require('core')
local string = require('string')

local text = [[Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum.]]

local tmp_file = path.join(__dirname, 'tmp', 'test_readstream')
fs.writeFileSync(tmp_file, text)

local options = {
  flags = 'r',
  mode = '0644',
  chunk_size = 65536,
  offset = 0,
  fd = nil,
  length = 16, -- should stop at 16
}
local fp = fs.createReadStream(tmp_file, options)

local sink = core.iStream:new()
sink.str = ""
sink.write = function(self, chunk)
  self.str = self.str .. chunk
  return true
end

fp:once('end', function()
  local expected = string.sub(text, 1, options.length)
  assert(expected == sink.str)
end)

fp:pipe(sink)
