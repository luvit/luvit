local ffi = require('ffi')

require('tap')(function (test)
  test('test crash', function()
    ffi.string(nil, 1)
  end)
end)
