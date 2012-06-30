--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

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

require('helper')

local timer = require('timer')
local http = require('http')
local net = require('net')
local table = require('table')
local string = require('string')
local PORT = process.env.PORT or 10080
local BODY = 'hello world\n'

--[[
  Test a http server response

  @param {function} handler
  @param {function} reqGen : Generate a string representation of a client
                             request.
  @param {function} resVal : Validate the server response
--]]
function test (handler, reqGen, resVal)
  local server = http.createServer(handler)

  local port = PORT
  PORT = PORT + 1

  local serverResponse = {} -- table (int keys)
  local gotEof = false

  function cleanup ()
    server:close()
    resVal(serverResponse, gotEof, true)
  end

  local timerRef = timer.setTimeout(1000, cleanup)
  process:on('exit', cleanup)

  server:on('listening', function ()
    local c = net.createConnection(port)

    c:on('connect', function ()
      c:write(reqGen())
    end)

    c:on('data', function (chunk)
      serverResponse[#serverResponse + 1] = chunk
    end)

    c:on('end', function ()
      c:done()
      server:close()

      gotEof = true
      timer.clearTimer(timerRef)
      process:removeListener('exit', cleanup)

      resVal(serverResponse, gotEof, false)
    end)
  end)

  server:listen(port)
end

-- Javascript like split
function split (str, sep)
  local start = 0
  local stop = 0
  local init = 1
  local ret = {}
  local len = string.len(str)

  if nil == sep or sep == '' then
    for i = 1, len, 1 do
      ret[#ret + 1] = string.char(string.byte(str, i))
    end
  else
    while true do
      start, stop = string.find(str, sep, init)
      if nil == start then
        break
      end
      ret[#ret + 1] = string.sub(str, init, start - 1)
      if stop == len then
        ret[#ret + 1] = ''
        break
      end
      init = stop + 1
    end
  end

  return ret
end

(function ()
  function handler (req, res)
    res:writeHead(200, { ['Content-Type'] = 'text/plain' })
    res:done(BODY)
  end

  function requestGen ()
    return 'GET / HTTP/1.0\r\n\r\n'
  end

  function responseValidator (res, eof, timeout)
    local m = split(table.concat(res), '\r\n\r\n')
    assert(BODY == m[2])
    assert(true == eof)
    assert(false == timeout)
  end

  test(handler, requestGen, responseValidator)
end)()
