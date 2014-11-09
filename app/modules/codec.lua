--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]
local uv = require('uv')

-- Given a raw uv_stream_t userdara, return coro-friendly read/write functions.
function exports.wrapStream(socket)
  local paused = true
  local queue = {}
  local waiting

  local onRead

  local function read()
    if #queue > 0 then
      return unpack(table.remove(queue, 1))
    end
    if paused then
      paused = false
      uv.read_start(socket, onRead)
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
      uv.read_stop(socket)
    end
  end

  local function write(chunk)
    if chunk then
      -- TODO: add backpressure by pausing and resuming coroutine
      -- when write buffer is full.
      uv.write(socket, chunk)
    else
      uv.shutdown(socket)
    end
  end

  return read, write
end
function exports.chain(...)
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
