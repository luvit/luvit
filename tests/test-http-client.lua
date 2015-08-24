--[[

Copyright 2015 The Luvit Authors. All Rights Reserved.

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

require('tap')(function(test)

  local fs = require('fs')
  local http = require('http')

  test("http-client", function(expect)
    http.get('http://luvit.io', expect(function (res)
      assert(res.statusCode == 301)
      assert(res.httpVersion == '1.1')
      res:on('data', function (chunk)
        p("ondata", {chunk=chunk})
      end)
      res:on('end', expect(function ()
        p('stream ended')
      end))
    end))
  end)

  test("http-client (errors are bubbled)", function(expect)
    local socket = http.get('http://luvit.io:1234', function (res)
      assert(false)
    end)
    socket:on('error',expect(function(err)
      assert(not (err == nil))
    end))
  end)

  test("http-client stream file", function(expect)
    local port = 50010

    local function interceptEmit(stream, logString)
      local oldEmit = stream.emit
      stream.emit = function(self, type, ...)
        print(logString .. type)
        return oldEmit(self, type, ...)
      end
    end

    local server
    server = http.createServer(function (req, res)
      local f = fs.createReadStream(module.path)
      interceptEmit(f, 'readable: ')
      interceptEmit(res, 'response: ')
      res:on('close', function() print('response: close(r)') server:destroy() end)
      f:pipe(res)
    end):listen(port, function()
      print('Server running ' .. port)
      http.get('http://127.0.0.1:' .. port, function (res)
        res:on('data', p)
        assert(res.statusCode == 200, 'validate status code')
      end)
    end)
  end)
end)



