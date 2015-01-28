local spawn = require('childprocess').spawn
local los = require('los')

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

  test('invalid command', function(expect)
    local child, onError

    function onError(err)
      assert(err)
    end

    child = spawn('skfjsldkfjskdfjdsklfj')
    child:on('error', expect(onError))
  end)

  test('process.env pairs', function()
    local key = "LUVIT_TEST_VARIABLE_1"
    local value = "TEST1"
    local iterate, found

    function iterate()
      for k, v in pairs(process.env) do
        p(k, v)
        if k == key and v == value then found = true end
      end
    end

    process.env[key] = value
    found = false
    iterate()
    assert(found)

    process.env[key] = nil
    found = false
    iterate()
    assert(process.env[key] == nil)
    assert(found == false)
  end)
end)

