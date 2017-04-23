local spawn = require('childprocess').spawn
local los = require('los')
local net = require('net')
local uv = require('uv')

require('tap')(function(test)

  test('process getpid', function()
    p('process pid', process.pid)
    assert(process.pid)
  end)

  test('process argv', function()
    p('process argv', process.argv)
    assert(process.argv)
  end)

  test('signal usr1,usr2,hup', function(expect)
    local onHUP, onUSR1, onUSR2
    if los.type() == 'win32' then return end
    function onHUP() process:removeListener('sighup', onHUP) end
    function onUSR1() process:removeListener('sigusr1', onUSR1) end
    function onUSR2() process:removeListener('sigusr2', onUSR2) end
    process:on('sighup', expect(onHUP))
    process:on('sigusr1', expect(onUSR1))
    process:on('sigusr2', expect(onUSR2))
    process.kill(process.pid, 'sighup')
    process.kill(process.pid, 'sigusr1')
    process.kill(process.pid, 'sigusr2')
  end)

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
      p('stdout', chunk)
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
      child.stdin:destroy()
    end

    child.stdout:once('end', expect(onEnd))
    child.stdout:on('data', onStdout)
    child:on('exit', expect(onExit))
    child:on('close', expect(onExit))
  end)

  test('invalid command', function(expect)
    local child, onError

    -- disable on windows, bug in libuv
    if los.type() == 'win32' then return end

    function onError(err)
      assert(err)
    end

    child = spawn('skfjsldkfjskdfjdsklfj')
    child:on('error', expect(onError))
    child.stdout:on('error', expect(onError))
    child.stderr:on('error', expect(onError))
  end)

  test('invalid command verify exit callback', function(expect)
    local child, onExit, onClose

    -- disable on windows, bug in libuv
    if los.type() == 'win32' then return end

    function onExit() p('exit') end
    function onClose() p('close') end

    child = spawn('skfjsldkfjskdfjdsklfj')
    child:on('exit', expect(onExit))
    child:on('close', expect(onClose))
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

  test('child process no stdin', function(expect)
    local child, onData, options

    options = {
      stdio = {
        nil,
        net.Socket:new({ handle = uv.new_pipe(false) }),
        net.Socket:new({ handle = uv.new_pipe(false) })
      }
    }

    function onData(data) end

    if los.type() == 'win32' then
      child = spawn('cmd.exe', {'/C', 'set'}, options)
    else
      child = spawn('env', {}, options)
    end
    child:on('data', onData)
    child:on('exit', expect(function() end))
    child:on('close', expect(function() end))
  end)

  test('child process (no stdin, no stderr, stdout) with close', function(expect)
    local child, onData, options

    options = {
      stdio = {
        nil,
        net.Socket:new({ handle = uv.new_pipe(false) }),
        nil
      }
    }

    function onData(data) p(data) end

    if los.type() == 'win32' then
      child = spawn('cmd.exe', {'/C', 'set'}, options)
    else
      child = spawn('env', {}, options)
    end
    child:on('data', onData)
    child:on('close', expect(function(exitCode) assert(exitCode == 0) end))
  end)
end)

