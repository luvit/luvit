local spawn = require('childprocess').spawn
local los = require('los')

local environmentTestResult = false

require('tap')(function(test)
  test('environment subprocess', function(expect)
    local child, options, onStdout, onExit, onEnd, data

    options = {
      env = { TEST1 = 1 }
    }

    data = ''

    if los.type() == 'win32' then
      child = spawn('cmd.exe', {'/C', 'set'}, options)
    else
      child = spawn('env', {}, options)
    end

    function onStdout(chunk)
      p('stdout')
      data = data .. chunk
    end

    function onExit(code, signal)
      p('exit')
      assert(code == 0)
      assert(signal == 0)
    end

    function onEnd()
      assert(data:find('TEST1=1'))
      p('found')
    end

    child.stdout:once('end', expect(onEnd))
    child.stdout:on('data', onStdout)
    child:on('exit', expect(onExit))
  end)
end)

