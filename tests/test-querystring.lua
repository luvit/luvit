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

require('helper')

local parse = require('querystring').parse

-- Basic code coverage
local tests = {
  [{'%25 %20+=foo%25%00%41bar&a=%26%3db'}] = {['%   '] = 'foo%\000Abar', a = '&=b'},
  [{'%25 %20+=foo%25%00%41bar&a=%26%3db', '+'}] = {['%  '] = '', ['']='foo%\000Abar&a=&=b'},
  [{'f'}] = {f=''},
  [{'f>u+u>f', '+', '>'}] = {f='u', u='f'},
}

for input, output in pairs(tests) do
  local tokens = parse(input[1], input[2], input[3])
  if not deep_equal(output, tokens) then
    p("Expected", output)
    p("But got", tokens)
    error("Test failed " .. input[1])
  end
end
