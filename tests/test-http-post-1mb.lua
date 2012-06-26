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

require("helper")

local http = require('http')
local string = require('string')

local HOST = "127.0.0.1"
local PORT = process.env.PORT or 10080
local MB = 1024 * 1024
local server = nil
local client = nil

local a = string.rep('a', 1024)
local data = string.rep(a, 1024)

server = http.createServer(function(request, response)
  p('server:onConnection')
  local postBuffer = ''
  assert(request.method == "POST")
  assert(request.url == "/foo")
  assert(request.headers.bar == "cats")
  request:on('data', function(chunk)
    postBuffer = postBuffer .. chunk
  end)
  request:on('end', function()
    assert(postBuffer == data)
    response:write("Hello")
    response:finish()
    server:close()
  end)
end)

server:listen(PORT, HOST, function()
  local headers = {
    bar = 'cats',
    ['Content-Length'] = MB
  }
  local req = http.request({
    host = HOST,
    port = PORT,
    method = 'POST',
    path = "/foo",
    headers = headers
  }, function(response)
    assert(response.status_code == 200)
    assert(response.version_major == 1)
    assert(response.version_minor == 1)
    -- TODO: fix refcount so this isn't needed.
    process.exit()
  end)
  req:write(data)
  req:done()
end)

