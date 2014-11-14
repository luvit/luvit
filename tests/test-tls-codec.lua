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

local http = require('codecs/http')
local tlsCodec = require('codecs/tls')
local uv = require('uv')
local chain = require('codec').chain
local wrapStream = require('codec').wrapStream
local x509 = require('openssl').x509
local fs = require('fs')
local pathJoin = require('luvi').path.join

require('tap')(function (test)

  test("reading ca.cer", function ()
    local path = pathJoin(module.dir, "fixtures", "luvit.io-ca.cer")
    local xcert = x509.read(fs.readFileSync(path))
    p(xcert:parse())
  end)

  test("Real HTTPS request", function (expect)
    uv.getaddrinfo("luvit.io", "https", {
      socktype = "STREAM",
      family = "INET",
    }, expect(function (err, res)
      assert(not err, err)
      local client = uv.new_tcp()
      uv.tcp_connect(client, res[1].addr, res[1].port, expect(function (err)
        assert(not err, err)
        p {
          client = client,
          sock = uv.tcp_getsockname(client),
          peer = uv.tcp_getpeername(client),
        }
        local read, write = wrapStream(client)
        local tls = tlsCodec()
        chain(tls.decoder, http.client.decoder, expect(function (read, write)
          local req = {
            method = "GET", path = "/",
            {"Host", "luvit.io"},
            {"User-Agent", "luvit"},
            {"Accept", "*/*"},
          }
          p(req)
          write(req)
          local res = read()
          p(res)
          for item in read do
            if item == "" then
              -- Close the connection when the response body is done.
              write()
            else
              p("HTML BYTES", #item)
            end
          end
        end), http.client.encoder, tls.encoder)(read, write)
      end))
    end))
  end)

end)
