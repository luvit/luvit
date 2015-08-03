local qs = require('querystring')
local deepEqual = require('deep-equal')

require('tap')(function(test)
  -- Basic code coverage
  -- format: { arbitraryQS, canonicalQS, parsedQS, sep, eq }
  local tests = {
    {'foo=1&bar=2', 'foo=1&bar=2', {['foo'] = '1', ['bar'] = '2'}},
    {'%25 %20+=foo%25%00%41bar&a=%26%3db', '%25%20%20%20=foo%25%00Abar&a=%26%3Db', {['%   '] = 'foo%\000Abar', a = '&=b'}},
    {'%25 %20+=foo%25%00%41bar&a=%26%3db', '=foo%25%00Abar%26a%3D%26%3Db+%25%20%20=', {['%  '] = '', ['']='foo%\000Abar&a=&=b'}, '+'},
    {'f', 'f=', {f=''}},
    {'f>u+u>f', 'f>u+u>f', {u='f', f='u'}, '+', '>'},
  }

  test('parse', function(expect)
    for num, test in ipairs(tests) do
      local input = test[1]
      local output = test[3]
      local tokens = qs.parse(input, test[4], test[5])
      if not deepEqual(output, tokens) then
        p("Expected", output)
        p("But got", tokens)
        error("Test failed: " .. input)
      end
    end
  end)

  test('stringify', function(expect)
    for num, test in ipairs(tests) do
      local input = test[3]
      local output = test[2]
      local str = qs.stringify(input, test[4], test[5])
      if not deepEqual(output, str) then
        p("Expected", output)
        p("But got", str)
        error("Test #" .. num .. " failed")
      end
    end
  end)
end)
