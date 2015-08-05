local fs = require('fs')
local thread = require('thread')

require('tap')(function(test)

  test('main thread self', function()
    p('main:',thread.self())
  end)

  test('thread thread', function()
    local thr = thread.start(function(a,b,c)
      local thread = require'thread'
      local fs = require'fs'
      assert(a+b==c)
      print(string.format('%d+%d=%d',a,b,c))
      p('child',thread.self())

      local fd = assert(fs.openSync('thread.tmp', "w+"))
      fs.writeSync(fd,0,tostring(thread.self()))
      assert(fs.closeSync(fd))
    end,2,4,6)
    local id = tostring(thr)
    thr:join()

    local chunk = fs.readFileSync('thread.tmp')
    p(chunk,id)
    assert(chunk==id)
    fs.unlinkSync('thread.tmp')
  end)
end)
