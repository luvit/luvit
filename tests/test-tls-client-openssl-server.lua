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

local childprocess = require('childprocess')
local los = require('los')
local tls = require('tls')
local timer = require('timer')
local path = require('luvi').path
local uv = require('uv')

require('tap')(function(test)
  test('tls client econnreset', function(expect)
    local port, args, child, key, cert
    local onInterval, client, data
    local count, maxCount, startClient

    if los.type() == 'win32' then return end

    count = 0
    maxCount = 5
    data = ''
    port = 32312
    key = path.join(module.dir, 'fixtures', 'keys', 'agent1-key.pem')
    cert = path.join(module.dir, 'fixtures', 'keys', 'agent1-cert.pem')
    args = { 's_server', '-accept', '127.0.0.1:'..port, '-key', key, '-cert', cert }

    function onInterval()
      p('onInterval')
      child.stdin:write('hello world\r\n')
      count = count + 1
      if count < maxCount then
        timer.setTimeout(200, onInterval)
      end
    end

    function startClient()
      local onData
      local count = 0
      local options = {
        port = port,
        host = '127.0.0.1',
        rejectUnauthorized = false,
      }

      p('startClient')

      function onData(_data)
        p('client data', _data)
        data = data .. _data
        count = count + 1
        if count == 5 then
          p('kill')
          --client:destroy()
          --child:kill()
        end
      end

      client = tls.connect(options)
      client:on('data', onData)
      client:on('error', p)
    end

    child = childprocess.spawn('openssl', args)
    child.stdout:on('data', function(data)
      if data:match('ACCEPT') then
        p('starting interval')
        timer.setTimeout(700, onInterval)
      end
    end)
    timer.setTimeout(200, startClient)
  end)

end)

