local parse = require('querystring').parse
local deepEqual = require('deep-equal')

require('tap')(function(test)
  test('querystring', function(expect)
    -- Basic code coverage
    local tests = {
      [{'%25 %20+=foo%25%00%41bar&a=%26%3db'}] = {['%   '] = 'foo%\000Abar', a = '&=b'},
      [{'%25 %20+=foo%25%00%41bar&a=%26%3db', '+'}] = {['%  '] = '', ['']='foo%\000Abar&a=&=b'},
      [{'f'}] = {f=''},
      [{'f>u+u>f', '+', '>'}] = {f='u', u='f'},
    }

    for input, output in pairs(tests) do
      local tokens = parse(input[1], input[2], input[3])
      if not deepEqual(output, tokens) then
        p("Expected", output)
        p("But got", tokens)
        error("Test failed " .. input[1])
      end
    end
  end)
end)
