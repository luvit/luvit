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
local fs  = require('fs')

local PORT = 8081
local HOST = '127.0.0.1'
local server

server = http.createServer(function(request, response)
  p('SERV REQ', request)
  request:on('data', function (chunk) p('SERV DATA', #chunk) end)
  request:on('finish', function ()
    p('SERV END')
    response:writeHead(200)
    response:finish()
  end)
end):listen(PORT, HOST)

local request
request = http.request({
  method = 'POST',
  host = HOST,
  port = PORT,
  path = '/'
}, function (err, response)
  if err then error(err.message) end

  fs.createReadStream(__dirname .. '/fixtures/test-pipe.txt'):pipe(request)

  response:on('finish', function ()
    p('REQ END')
    server:close()
  end)
end)

