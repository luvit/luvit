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

local JSON = require('json')

--
-- smoke
--

assert(JSON)
assert(JSON.parse)
assert(JSON.stringify)
assert(JSON.null)
assert(JSON.stringify({a = 'a'}) == '{"a":"a"}')
assert(deep_equal(JSON.parse('{"a":"a"}'), {a = 'a'}))

--
-- sanity
--

  -- parse

for _, x in ipairs({
  '', ' ', '{', '[', '{"f":', '{"f":1', '{"f":1',
}) do
  local status, result = pcall(JSON.parse, x)
  assert(not status)
  assert(result:find('parse error: premature EOF'))
end

for _, x in ipairs({
  '{]', '[}',
}) do
  local status, result = pcall(JSON.parse, x)
  assert(not status)
  assert(result:find('parse error: '))
end

for _, x in ipairs({
  '[]', '{}',
}) do
  local status, result = pcall(JSON.parse, x)
  assert(status)
  assert(type(result) == 'table')
end

  -- stringify

assert(JSON.stringify() == 'null')
for _, x in ipairs({
  {}, {1, 2, 3}, {a = 'a'}, 'string', 0, 0.1, 3.1415926, true, false,
}) do
  local status, result = pcall(JSON.stringify, x)
  assert(status)
  assert(type(result) == 'string')
end

--
-- types
--

-- empty table stringify as empty array
assert(JSON.stringify({}) == '[]')
-- FIXME:
--  functions should be silently ignored for hash
--  and be null for array part of table
--[[
assert(JSON.stringify({function () end}), '[null]')
assert(JSON.stringify({x = function () end}), '{}')
assert(JSON.stringify({function () end, x = function () end}), '[null]')
]]--

-- strings are escaped
assert(JSON.stringify('a"b\tc\nd') == '"a\\"b\\tc\\nd"')
assert(JSON.parse('"a\\"b\\tc\\nd"') == 'a"b\tc\nd')
-- TODO: complete set of dangerous chars

-- booleans are ok
assert(JSON.stringify(true) == 'true')
assert(JSON.stringify(false) == 'false')
assert(JSON.parse('true') == true)
assert(JSON.parse('false') == false)

--
-- strict
--

for _, x in ipairs({
  '{f:1}', "{'f':1}",
}) do
  local status, result = pcall(JSON.parse, x)
  assert(not status)
  assert(result:find('lexical error:'))
end

--
-- TODO: options
--

--
-- TODO: multivalue?
--
