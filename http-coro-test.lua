local codec = require('http-coro').server

-- local function test(inputs, outputs)
--   local i = 0
--   return function ()
--     i = i + 1
--     return inputs[i]
--   end, function (value)
--     outputs[#outputs + 1] = value
--   end
-- end

-- local inputs = {
--   "GET / HTTP/1.0\r\n",
--   "User-Agent: Manual-Test\r\n",
--   "Connection: Keep-Alive\r\n",
--   "Content-Length: 0\r\n",
--   "\r\nGET /favicon.ico HTTP/1.1\r\n",
--   "User-Agent: Manual-Test\r\n",
--   "Connection: Keep-Alive\r\n",
--   "\r\n",
--   "DELETE /bad-file HTTP/1.1\r\n\r\n",
--   "PUT /myfile HTTP/1.0\r\n",
--   "\r\nThis is the whole file",
--   " with lots of data.",
-- }
-- local outputs = {}
-- codec.decoder(test(inputs, outputs))
-- p(outputs)

local uv = require('uv')

local function app(read, write)
  for req in read do
    local keepAlive = req.version >= 1.1
    for i = 1, #req.headers do
      local pair = req.headers[i]
      local key = string.lower(pair[1])
      if key == "connection" then
        keepAlive = string.lower(pair[2]) == "keep-alive"
      end
    end
    -- print("Writing response headers")
    local body = req.path .. "\n"
    local headers = {
      { "Server", "Luvit" },
      { "Content-Type", "text/plain" },
      { "Content-Length", #body },
    }
    if keepAlive then
      headers[#headers + 1] = { "Connection", "Keep-Alive" }
    end

    write {
      code = 200,
      headers = headers
    }
    -- print("Writing body")
    write("out", body)

    if not keepAlive then
      break
    end
  end
  write()
end

local function chain(...)
  local args = {...}
  local nargs = select("#", ...)
  return function (read, write)
    local threads = {} -- coroutine thread for each item
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
            local data = boxes[j]
            boxes[j] = nil
            assert(coroutine.resume(threads[j]))
            return unpack(data)
          else
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
            waiting[j] = false
            assert(coroutine.resume(threads[j], ...))
          else
            boxes[i] = {...}
            coroutine.yield()
          end
        end
      end
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

end)
print("Test HTTP server at http://127.0.0.1:8080/")
