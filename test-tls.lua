local openssl = require('openssl')
local uv = require('uv')
local bit = require('bit')
local pathjoin = require('luvi').path.join

-- Sync readfile using uv apis
local function readfile(path)
  local fd, stat, chunk, err
  fd = assert(uv.fs_open(path, "r", 420)) -- 420 = 0644)
  stat, err = uv.fs_fstat(fd)
  if stat then
    chunk, err = uv.fs_read(fd, stat.size, 0)
  end
  uv.fs_close(fd)
  if chunk then return chunk end
  error(err)
end

-- Resolve an address and connect
local function tcpConnect(host, port, callback)
  local onAddress, onConnect, address

  function onAddress(err, res)
    assert(not err, err)
    assert(#res > 0)
    address = res[1]
    local client = uv.new_tcp()
    uv.tcp_nodelay(client, true)
    uv.tcp_connect(client, address.addr, address.port, onConnect)
  end

  function onConnect(client, err)
    callback(err, client, address)
  end

  uv.getaddrinfo(host, port, {
    socktype= "STREAM",
    family = "INET"
  }, onAddress)
end

local function noop() end

local function prep(callback)
  if callback then return callback, noop end

  local thread, main = coroutine.running()
  if not thread or main then error("Callback required in main thread") end

  local waiting, data

  local function next(err, ...)
    assert(not err, err)
    if waiting then
      coroutine.resume(thread, ...)
    else
      data = {...}
    end
  end

  local function wait()
    if data then return unpack(data) end
    waiting = true
    return coroutine.suspend()
  end

  return next, wait
end

local function makeChannel(watermark)
  local length = 0
  local queue = {}
  local channel = {}
  local onDrain, onRead
  local err
  watermark = watermark or 2

  local function check()
    if err then
      if onRead then
        local fn = onRead
        onRead = nil
        fn(err)
      end
      if onDrain then
        local fn = onDrain
        onDrain = nil
        fn(err)
      end
    else
      print("onRead", onRead, "onDrain", onDrain, "length", length)
      if onRead and length > 0 then
        local fn = onRead
        onRead = nil
        local data = queue[length]
        queue[length] = nil
        length = length - 1
        fn(nil, data)
      end
      if onDrain and length < watermark then
        local fn = onDrain
        onDrain = nil
        fn()
      end
    end
  end

  function channel.put(item)
    if err then error(err) end
    queue[length + 1] = item
    length = length + 1
    check()
    return length < watermark
  end

  function channel.drain(callback)
    local next, wait = prep(callback)
    if onDrain then error("Only one drain at a time please") end
    if type(callback) ~= "function" then
      error("callback must be a function")
    end
    onDrain = next
    check()
    return wait()
  end

  function channel.take(callback)
    local next, wait = prep(callback)
    if onRead then error("Only one read at a time please") end
    if type(callback) ~= "function" then
      error("callback must be a function")
    end
    onRead = next
    check()
    return wait()
  end

  function channel.fail(e)
    err = e
    check()
  end

  return channel
end


--    <- input  <-                   <- input  <-
-- TCP            tcpChannel <-> BIOs            tlsChannel
--    -> output ->                   -> output ->

-- Wrap any uv_stream_t subclass (uv_tcp_t, uv_pipe_t, or uv_tty_t) and
-- expose it as a culvert channel with callback and coroutine support.
-- call channel.put/channel.drain to write to the tcp socket
-- call channel.take to read from the tcp socket
local function streamToChannel(stream)
  local input = makeChannel(2)
  local output = makeChannel(2)
  local paused = true
  local onRead, onDrain, onInput, onWrite

  function onRead(_, err, chunk)
    p("onTcpRead", {err=err,chunk=chunk})
    if err then return output.fail(err) end
    if output.put(chunk) or paused then return end
    paused = true
    uv.read_stop(stream)
    output.drain(onDrain)
  end

  function onDrain(err)
    if err then return output.fail(err) end
    if not paused then return end
    paused = false
    uv.read_start(stream, onRead)
  end

  function onInput(err, chunk)
    if err then return output.fail(err) end
    -- TODO: find better way to do backpressure than writing
    -- one at a time.
    uv.write(stream, chunk, onWrite)
  end

  function onWrite(_, err)
    if err then return output.fail(err) end
    input.take(onInput)
  end

  input.take(onInput)
  uv.read_start(stream, onRead)
  paused = false

  return {
    put = input.put,
    drain = input.drain,
    take = output.take,
    fail = input.fail,
  }
end


-- Given a duplex channel, do TLS handchake with it and return a new
-- channel for R/W of the clear text.
local function secureChannel(channel)
  local input = makeChannel(2)
  local output = makeChannel(2)
  local initialized = false

  local ctx = openssl.ssl.ctx_new("TLSv1_2")
  -- TODO: use root ca cert to verify server
  local xcert = openssl.x509.read(readfile(pathjoin(module.dir, "ca.cer")))
  p(xcert:parse())
  ctx:set_verify({"none"})
  -- TODO: Make options configurable in secureChannel call
  ctx:options(bit.bor(
    openssl.ssl.no_sslv2,
    openssl.ssl.no_sslv3,
    openssl.ssl.no_compression))
  local bin, bout = openssl.bio.mem(8192), openssl.bio.mem(8192)
  local ssl = ctx:ssl(bin, bout, false)

  local process, onPlainText, onCipherText

  function onPlainText(err, data)
    p("onPlainText", {err=err,data=data})
    if err then return output.fail(err) end
    bout:write(data)
    input.take(onPlainText)
    process()
  end

  function onCipherText(err, data)
    p("onCipherText", {err=err,data=data})
    if err then return output.fail(err) end
    bin:write(data)
    channel.take(onCipherText)
    process()
  end

  function process()
    if not initialized then
      local success, message = ssl:handshake()
      p {
        success = success,
        message = message,
      }
      if success then
        initialized = true
        input.take(onPlainText)
      end
    end
    if bin:pending() > 0 then
      local data = bin:read()
      p("writing plain", data)
      output.put(data)
    end
    if bout:pending() > 0 then
      local data = bout:read()
      p("writing cipher", data)
      channel.put(data)
    end
  end

  -- Kick off the process
  process()
  channel.take(onCipherText)

  return {
    put = input.put,
    drain = input.drain,
    take = output.take,
    fail = input.fail,
  }
end


print("Connecting to https://luvit.io/")
tcpConnect("luvit.io", "https", function (err, stream, address)
  assert(not err, err)
  print("TCP Connected.")
  p {stream=stream,address=address}

  print("Establishing secure socket")
  local channel = secureChannel(streamToChannel(stream))
  p {channel=channel}
  channel.put("GET / HTTP/1.0\r\n\r\n")
  channel.take(function (err, data)
    assert(not err, err)
    print("data!", data)
  end)
end)

-- Run the event loop with stack traces in case of errors
xpcall(uv.run, debug.traceback)
