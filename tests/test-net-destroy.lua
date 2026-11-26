local net = require('net')
local uv = require('uv')

local function newSocket()
  return net.Socket:new({ handle = uv.new_tcp() })
end

local function checkClosed(socket, expect)
  local callbackError
  socket:once('error', expect(function(err) callbackError = err end))
  assert(socket:write('closed', expect(function(err)
    assert(err and err == callbackError)
  end)) == false)
  socket:pause()
  socket:resume()
  socket:shutdown()
  socket:shutdown(expect(function() end))
  assert(not socket._reading)
end

require('tap')(function(test)
  test('reject I/O on either side of the close callback', function(expect)
    local socket = newSocket()
    socket:on('close', expect(function() end))
    socket:destroy(nil, expect(function()
      checkClosed(socket, expect)
    end))
    socket:destroy(nil, expect(function() end))
    checkClosed(socket, expect)
  end)

  test('deferred read rechecks the socket on connect', function(expect)
    local socket = newSocket()
    socket._connecting = true
    socket:_read(0)
    socket:destroy(nil, expect(function() end))
    socket._connecting = false
    socket:emit('connect')
    assert(not socket._reading)
  end)

  test('recognize close started by another owner', function(expect)
    local socket = newSocket()
    uv.close(socket._handle)
    checkClosed(socket, expect)
  end)

  test('immediate submission errors settle the write once', function(expect)
    local socket = newSocket()
    -- The handle is open, but has never connected.
    socket:on('error', expect(function(err) assert(err) end))
    socket:write('data', expect(function(err)
      assert(err and socket.destroyed)
      assert(socket._writableState.pendingcb == 0)
      assert(not socket._writableState.writing)
    end))
  end)

  test('unsuccessful read_start leaves reading clear', function(expect)
    local socket = newSocket()
    socket:on('error', expect(function(err) assert(err) end))
    socket:resume()
    assert(socket.destroyed and not socket._reading)
  end)

  test('destroy settles corked writes', function(expect)
    local socket = newSocket()
    socket:cork()
    socket:write('one', expect(function(err) assert(err) end))
    socket:write('two', expect(function(err)
      assert(err and socket._writableState.pendingcb == 0)
    end))
    socket:destroy()
    assert(socket._writableState.length == 0)
    checkClosed(socket, expect)
  end)

  local function pendingWrite(expect, completionError)
    local socket = newSocket()
    local complete
    function socket:_write(_, callback)
      assert(not complete, 'unexpected second write')
      complete = callback
    end
    if completionError then
      socket:on('error', expect(function(err) assert(err == completionError) end))
    end
    socket:write('active', expect(function(err) assert(err == completionError) end))
    socket:write('queued', expect(function(err)
      assert(err and socket._writableState.pendingcb == 0)
    end))
    socket:destroy()
    assert(socket._writableState.length == #'active')
    complete(completionError)
    assert(socket._writableState.length == 0)
  end

  test('submitted write succeeds after destroy', function(expect)
    pendingWrite(expect)
  end)

  test('submitted write is canceled after destroy', function(expect)
    pendingWrite(expect, 'ECANCELED')
  end)
end)
