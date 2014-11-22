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

require('tap')(function(test)
  test('tls client econnreset', function(expect)
    local port, args, child, interval, timerCallback, key, cert
    local onInterval, onStartClient, onKill, client

    if los.type() == 'win32' then return end

    port = 32311
    key = path.join(module.dir, 'fixtures', 'keys', 'agent1-key.pem')
    cert = path.join(module.dir, 'fixtures', 'keys', 'agent1-cert.pem')
    args = { 's_server', '-accept', port, '-key', key, '-cert', cert }

    child = childprocess.spawn('openssl', args)
    child.stderr:on('data', p)
    child.stdout:on('data', p)

    function onInterval()
      pcall(child.stdin.write, child.stdin, "Hello world")
    end
    interval = timer.setInterval(100, onInterval)

    function onStartClient()
      local options = {
        port = port,
        host = '127.0.0.1',
        rejectUnauthorized = false,
      }
      client = tls.connect(options)
      client:on('data', p)
    end
    timer.setTimeout(200, onStartClient)

    function onKill()
      timer.clearInterval(interval)
      child:kill()
      client:destroy()
    end
    timer.setTimeout(1000, onKill)
  end)
end)

