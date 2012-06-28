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
local stringify = require('querystring').stringify

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

local sTests = {
  [{['foo'] = '918854443121279438895193'}] = 'foo=918854443121279438895193',
  [{['foo'] = 'bar'}] = 'foo=bar',
  [{['foo'] = {'bar', 'quux'}}] = 'foo=bar&foo=quux',
  [{['foo'] = '1', ['bar'] = '2'}] = 'foo=1&bar=2',
  [{['my weird field'] = 'q1!2"\'w$5&7/z8)?' }] = 'my%20weird%20field=q1%212%22%27w%245%267%2Fz8%29%3F',
  [{['foo=baz'] = 'bar'}] = 'foo%3Dbaz=bar',
  [{['foo'] = 'baz=bar'}] = 'foo=baz%3Dbar',
  [{['str'] = 'foo',
    ['arr'] = {'1', '2', '3'},
    ['somenull'] = '',
    ['undef'] = ''}] = 'somenull=&arr=1&arr=2&arr=3&undef=&str=foo',
  [{[' foo '] = ' bar '}] = '%20foo%20=%20bar%20',
  [{['foo'] = '%zx'}] = 'foo=%25zx'
}

for input, output in pairs(sTests) do
  local str = stringify(input)

  if output ~= str then
    p("Expected", output)
    p("But got", str)
    error("Test failed " .. input)
  end
end

-- Test ordering
local soTest = {
  str = 'foo',
  arr = {1, 2, 3},
  somenull = '',
  undef = ''
}
local soOrder = {
  [{ 'str', 'arr', 'somenull', 'undef' }] = 'str=foo&arr=1&arr=2&arr=3&somenull=&undef='
}

for input, output in pairs(soOrder) do
  local str = stringify(soTest, input, nil, nil)

  if output ~= str then
    p("Expected", output)
    p("But got", str)
    error("Test failed " .. input)
  end
end
