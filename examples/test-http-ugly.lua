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

pcall(require, "helper")

local http = require('http')
local delay = require('timer').setTimeout

local HOST = "127.0.0.1"
local PORT = process.env.PORT or 10080
local server = nil
local client = nil

server = http.createServer(function(request, response)
  debug('server connection start')
  assert(request.method == "GET" or request.method == "POST")
  assert(request.url == "/foo")
  local income = ''
  request:on('data', function (data)
    debug('server request data', data)
    income = income .. data
  end)
  request:on('end', function ()
    debug('server request end')
    debug('server replies with', income)
    response:write(income)
    response:finish()
    --response.socket:close()
  end)
  request:on('error', function (err)
    debug('server request error', err)
  end)
  response:on('data', function (data)
    debug('server response data', data)
  end)
  response:on('end', function ()
    debug('server response end')
    --[[delay(500, function ()
      process.exit()
    end)]]--
  end)
  response:on('error', function (err)
    debug('server response error', err)
  end)
  debug('server connection handled')
end):listen(PORT, HOST, function ()

------ CLIENT -----
print("Server listening at http://" .. HOST .. ":" .. PORT)

local payload = 'THIS-NEVER-REACHES-THE-SERVER:('

debug('client request create')
local request
request = http.request(
  {
    host = HOST,
    port = PORT,
    path = "/foo",
    method = 'POST',
    headers = {
      bar = "cats",
      --['Content-Length'] = #payload * 2 + 4,
    }
  },
  function (conn)
    debug('conn open')
    assert(conn.status_code == 200)
    assert(conn.version_major == 1)
    assert(conn.version_minor == 1)
    conn:on('data', function (data)
      debug('conn data', data)
    end)
    conn:on('end', function ()
      debug('conn end')
    end)
    conn:on('error', function (err)
      debug('conn error', err)
    end)
    --[[delay(500, function ()
      debug('client closes socket')
      -- FIXME: wonder what to call?! :)
      request:close()
      --conn:finish()
      --conn:close()
      --conn.socket:close()
    end)]]--
end)

request:on('data', function (data)
  debug('client request data', data)
end)
request:on('end', function ()
  debug('client request end')
end)
request:on('error', function (err)
  debug('client request error', err)
end)

debug('client request send', payload)
request:write(payload)
request:write(payload)
request:close('PLUS')

---------
end)
