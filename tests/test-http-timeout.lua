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

local PORT = process.env.PORT or 10081

local options = {
  method = 'GET',
  port = PORT,
  host = '127.0.0.1',
  path = '/'
}

local server
server = http.createServer(function(req, res)
end)

server:listen(PORT, function()
  local req = http.request(options, function(res)
  end)
  function destroy()
    server:close()
    req:destroy()
  end
  req:setTimeout(1, destroy)
  req:on('error', function(err)
    assert(err.code == "ECONNRESET")
  end)
end)
