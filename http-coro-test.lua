local codec = require('http-coro').server
local uv = require('uv')

local function app(read, write)
  for req in read do
    p(req)
    write {
      code = 200,
      headers = {
        { "Content-Type", "text/plain" },
        { "Content-Length", #req.url },
        { "Server", "Luvit" },
      }
    }
    print("Writing body")
    write(req.url)
  end
end

local function chain(...)
  local args = {...}
  local nargs = select("#", ...)
  return function (read, write)
    threads = {} -- coroutine thread for each item
    local waiting = {} -- flag when waiting to pull from upstream
    local boxes = {}   -- storage when waiting to write to downstream
    for i = 1, nargs do
      threads[i] = coroutine.create(args[i])
      waiting[i] = false
      local r, w
      if i == 1 then
        r = read
      else
        function r()
          local j = i - 1
          if boxes[j] then
            print(i .. " reads from boxed " .. j)
            local data = boxes[j]
            boxes[j] = nil
            assert(coroutine.resume(threads[j]))
            return unpack(boxes)
          else
            print(i .. " wants to read from " .. j)
            waiting[i] = true
            return coroutine.yield()
          end
        end
      end
      if i == nargs then
        w = write
      else
        function w(...)
          local j = i + 1
          if waiting[j] then
            print(i .. " writes to waiting " .. j)
            waiting[j] = false
            assert(coroutine.resume(threads[j], ...))
          else
            print(i .. " wants to write to " .. j)
            boxes[i] = {...}
            coroutine.yield()
          end
        end
      end
      print("rw", i, r, w)
      assert(coroutine.resume(threads[i], r, w))
    end
  end
end

local server = uv.new_tcp()
uv.tcp_bind(server, "127.0.0.1", 8080)
uv.listen(server, 128, function (err)
  assert(not err, err)
  local client = uv.new_tcp()
  local paused = true
  local queue = {}
  local waiting
  uv.accept(server, client)

  local onRead

  local function read()
    if #queue > 0 then
      print("data read from tcp queue")
      return unpack(table.remove(queue, 1))
    end
    if paused then
      print("Read requested, resuming tcp read")
      paused = false
      uv.read_start(client, onRead)
    end
    waiting = coroutine.running()
    return coroutine.yield()
  end

  function onRead(err, chunk)
    local data = err and {nil, err} or {chunk}
    if waiting then
      print("Data arrived, feeding to paused reader")
      local thread = waiting
      waiting = nil
      return coroutine.resume(thread, unpack(data))
    end
    print("Data arrived, putting in queuereader")
    queue[#queue + 1] = data
    if not paused then
      print("Pausing tcp input")
      paused = true
      uv.read_stop(client)
    end
  end

  local function write(chunk)
    -- TODO: add backpressure by pausing and resuming coroutine
    -- when write buffer is full.
    print("Writing to tcp stream")
    uv.write(client, chunk)
  end

  chain(codec.decoder, app, codec.encoder)(read, write)

end)