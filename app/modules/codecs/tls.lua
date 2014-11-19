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

local openssl = require('openssl')
local bit = require('bit')

--[[
callbacks
   onsecureConnect -- When handshake completes successfully
--]]

return function (options)
  local ctx, bin, bout, ssl, outerWrite, outerRead, waiting, handshake, sslRead

  local tls = {}

  -- Both sides will call handshake as they are hooked up
  -- But the first to call handshake will simply wait
  -- And the second will perform the handshake and then
  -- resume the other.
  function handshake()
    if outerWrite and outerRead then
      while true do
        if ssl:handshake() then
          if tls.onsecureConnect then tls.onsecureConnect() end
          break
        end
        outerWrite(bout:read())
        bin:write(outerRead())
      end
      assert(coroutine.resume(waiting))
      waiting = nil
    else
      waiting = coroutine.running()
      coroutine.yield()
    end
  end

  function sslRead()
    return ssl:read()
  end

  function tls.createContext(options)
    ctx = openssl.ssl.ctx_new("TLSv1_2")
    ctx:set_verify({"none"})
    ctx:options(bit.bor(
                  openssl.ssl.no_sslv2,
                  openssl.ssl.no_sslv3,
                  openssl.ssl.no_compression))
    bin, bout = openssl.bio.mem(8192), openssl.bio.mem(8192)
    ssl = ctx:ssl(bin, bout, false)

    tls.ctx = ctx
    tls.ssl = ssl
  end

  function tls.decoder(read, write)
    outerRead = read
    handshake()
    for cipher in read do
      bin:write(cipher)
      for data in sslRead do
        write(data)
      end
    end
    write()
  end

  function tls.encoder(read, write)
    outerWrite = write
    handshake()
    for plain in read do
      ssl:write(plain)
      while bout:pending() > 0 do
        local data = bout:read()
        write(data)
      end
    end
    ssl:shutdown()
    write()
  end

  tls.createContext(options)

  return tls
end
