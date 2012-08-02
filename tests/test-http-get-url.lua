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
local PORT = process.env.PORT or 10080

local seen_req = false

local server
server = http.createServer(function(req, res)
  assert('GET' == req.method)
  assert('/foo?bar' == req.url)
  res:writeHead(200, {['Content-Type'] = 'text/plain'})
  res:write('hello\n')
  res:finish()
  server:close()
  seen_req = true
end)

server:listen(PORT, function()
  http.get('http://127.0.0.1:' .. PORT .. '/foo?bar');
end)

process:on('exit', function()
  assert(seen_req);
end)
