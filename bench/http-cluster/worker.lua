local uv = require('uv')
local codec = require('http-codec').server
local chain = require('chain')
local app = require('./app')

local server = uv.new_tcp()

local function onconnection(err)
  assert(not err, err)
  local client = uv.new_tcp()
  local paused = true
  local queue = {}
  local waiting
  assert(uv.accept(server, client))

  local onRead

  local function read()
    if #queue > 0 then
      return unpack(table.remove(queue, 1))
    end
    if paused then
      paused = false
      uv.read_start(client, onRead)
    end
    waiting = coroutine.running()
    return coroutine.yield()
  end

  function onRead(err, chunk)
    local data = err and {nil, err} or {chunk}
    if waiting then
      local thread = waiting
      waiting = nil
      return coroutine.resume(thread, unpack(data))
    end
    queue[#queue + 1] = data
    if not paused then
      paused = true
      uv.read_stop(client)
    end
  end

  local function write(chunk)
    if chunk then
      -- TODO: add backpressure by pausing and resuming coroutine
      -- when write buffer is full.
      uv.write(client, chunk)
    else
      uv.close(client)
    end
  end

  chain(codec.decoder, app, codec.encoder)(read, write)

end

-- Get listening socket from master process
local pipe = uv.new_pipe(true)
uv.pipe_open(pipe, 3)
uv.read_start(pipe, function (err)
  assert(not err, err)
  if uv.pipe_pending_count(pipe) > 0 then
    local pending_type = uv.pipe_pending_type(pipe)
    assert(pending_type == "TCP")
    assert(uv.accept(pipe, server))
    assert(uv.listen(server, 256, onconnection))
    uv.close(pipe)
    print("Worker received server handle")
  end
end)
