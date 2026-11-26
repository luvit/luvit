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

local fs = require('fs')
local path = require('luvi').path
local tls = require('tls')

require('tap')(function(test)
  test('set null cipher', function(expect)
    -- TLS 1.3 has a separate cipher list. Exercise the legacy suite on
    -- loopback using the same TLS implementation on every platform.
    local cipher = 'NULL-MD5:@SECLEVEL=0'
    local noTls13 = 0x20000000 -- SSL_OP_NO_TLSv1_3
    local keys = path.join(module.dir, 'fixtures', 'keys')
    local reply = 'I AM THE WALRUS\n'
    local server = tls.createServer({
      cert = fs.readFileSync(path.join(keys, 'agent1-cert.pem')),
      key = fs.readFileSync(path.join(keys, 'agent1-key.pem')),
      ciphers = cipher,
      secureOptions = noTls13
    }, expect(function(conn, err)
      assert(not err, tostring(err))
      assert(conn.ssl:current_cipher().name == 'NULL-MD5')
      conn:write(reply, function() conn:destroy() end)
    end))

    server:listen(0, '127.0.0.1', expect(function()
      local client = tls.connect({
        host = '127.0.0.1',
        port = server:address().port,
        ciphers = cipher,
        rejectUnauthorized = false
      })
      local response = ''
      client:on('data', function(chunk) response = response .. chunk end)
      client:on('end', expect(function()
        assert(response == reply)
        server:close()
      end))
    end))
  end)
end)
