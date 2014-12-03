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

local codec = require('codecs/http')
local uv = require('uv')
local chain = require('codec').chain
local wrapStream = require('codec').wrapStream
local deepEqual = require('deep-equal')
local testCodec = require('test-codec')

require('tap')(function (test)

  test("http server parser", function ()
    local output = testCodec(codec.server.decoder, {
      "GET /path HTTP/1.1\r\n",
      "User-Agent: Luvit-Test\r\n\r\n"
    })
    p(output)
    assert(deepEqual({
      { method = "GET", path = "/path", version = 1.1, keepAlive = true,
        {"User-Agent", "Luvit-Test"}
      },
      ""
    }, output))
  end)

  test("http client parser", function ()
    local output = testCodec(codec.client.decoder, {
      "HTTP/1.0 200 OK\r\n",
      "User-Agent: Luvit-Test\r\n\r\n"
    })
    p(output)
    assert(deepEqual({
      { code = 200, reason = "OK", version = 1.0, keepAlive = false,
        {"User-Agent", "Luvit-Test"}
      },
      ""
    }, output))
  end)

  test("http 1.0 Keep-Alive", function ()
    local output = testCodec(codec.server.decoder, {
      "GET / HTTP/1.0\r\n",
      "Connection: Keep-Alive\r\n\r\n",
      "DELETE /bad-resource HTTP/1.0\r\n",
      "Connection: Keep-Alive\r\n\r\n",
    })
    p(output)
    assert(deepEqual({
      { method = "GET", path = "/", version = 1.0, keepAlive = true,
        {"Connection", "Keep-Alive"},
      },
      "",
      { method = "DELETE", path = "/bad-resource", version = 1.0, keepAlive = true,
        {"Connection", "Keep-Alive"},
      },
      "",
    }, output))
  end)

  test("http 1.0 Raw body", function ()
    local output = testCodec(codec.server.decoder, {
      "GET / HTTP/1.0\r\n",
      "User-Agent: Test\r\n\r\n",
      "DELETE /bad-resource HTTP/1.0\r\n",
      "Connection: Keep-Alive\r\n\r\n",
    })
    p(output)
    assert(deepEqual({
      { method = "GET", path = "/", version = 1.0, keepAlive = false,
        {"User-Agent", "Test"},
      },
      "DELETE /bad-resource HTTP/1.0\r\n",
      "Connection: Keep-Alive\r\n\r\n",
      ""
    }, output))
  end)

  test("http 1.1 Keep-Alive", function ()
    local output = testCodec(codec.server.decoder, {
      "HEAD / HTTP/1.1\r\n\r\n",
      "DELETE /bad-resource HTTP/1.1\r\n\r\n",
    })
    p(output)
    assert(deepEqual({
      { method = "HEAD", path = "/", version = 1.1, keepAlive = true },
      "",
      { method = "DELETE", path = "/bad-resource", version = 1.1, keepAlive = true },
      "",
    }, output))
  end)

  test("http 1.1 Keep-Alive with bodies", function ()
    local output = testCodec(codec.server.decoder, {
      "POST /upload HTTP/1.1\r\n",
      "Content-Length: 12\r\n",
      "\r\nHello World\nDELETE ",
      "/ HTTP/1.1\r\n\r\n",
    })
    p(output)
    assert(deepEqual({
      { method = "POST", path = "/upload", version = 1.1, keepAlive = true,
        {"Content-Length", "12"},
      },
      "Hello World\n",
      "",
      { method = "DELETE", path = "/", version = 1.1, keepAlive = true },
      ""
    }, output))
  end)

  test("http 1.1 Raw body", function ()
    local output = testCodec(codec.server.decoder, {
      "GET / HTTP/1.1\r\n",
      "Connection: Close\r\n\r\n",
      "User-Agent: Test\r\n\r\n",
      "DELETE /bad-resource HTTP/1.0\r\n",
    })
    p(output)
    assert(deepEqual({
      { method = "GET", path = "/", version = 1.1, keepAlive = false,
        {"Connection", "Close"},
      },
      "User-Agent: Test\r\n\r\n",
      "DELETE /bad-resource HTTP/1.0\r\n",
      "",
    }, output))
  end)

  test("chunked encoding parser", function ()
    local output = testCodec(codec.server.decoder, {
      "PUT /my-file.txt HTTP/1.1\r\n",
      "Transfer-Encoding: chunked\r\n\r\n",
      "4\r\n",
      "Wiki\r\n",
      "5\r\n",
      "pedia\r\n",
      "e\r\n",
      " in\r\n\r\nchunks.\r\n",
      "0\r\n",
      "\r\n",
    })
    p(output)
    assert(deepEqual({
      { method = "PUT", path = "/my-file.txt", version = 1.1, keepAlive = true,
        {"Transfer-Encoding", "chunked"},
      },
      "Wiki",
      "pedia",
      " in\r\n\r\nchunks.",
      ""
    }, output))
  end)

  test("server encoder", function ()
    local output = testCodec(codec.server.encoder, {
      { code = 200 }
    })
    p(output)
    assert(deepEqual({
      "HTTP/1.1 200 OK\r\n\r\n"
    }, output))
  end)

  test("server encoder - Keepalive", function ()
    local output = testCodec(codec.server.encoder, {
      { code = 200,
        {"Content-Length", 12}
      },
      "Hello World\n",
      "",
      { code = 304 },
    })
    p(output)
    assert(deepEqual({
      "HTTP/1.1 200 OK\r\nContent-Length: 12\r\n\r\n",
      "Hello World\n",
      "HTTP/1.1 304 Not Modified\r\n\r\n",
    }, output))
  end)

  test("server encoder - Chunked Encoding, explicit end", function ()
    local output = testCodec(codec.server.encoder, {
      { code = 200,
        {"Transfer-Encoding", "chunked"}
      },
      "Hello World\n",
      "Another Chunk",
      "",
      { code = 304 },
    })
    p(output)
    assert(deepEqual({
      "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n",
      "c\r\nHello World\n\r\n",
      "d\r\nAnother Chunk\r\n",
      "0\r\n\r\n",
      "HTTP/1.1 304 Not Modified\r\n\r\n",
    }, output))
  end)

  test("server encoder - Chunked Encoding, auto end", function ()
    local output = testCodec(codec.server.encoder, {
      { code = 200,
        {"Transfer-Encoding", "chunked"}
      },
      "Hello World\n",
      "Another Chunk",
    })
    p(output)
    assert(deepEqual({
      "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n",
      "c\r\nHello World\n\r\n",
      "d\r\nAnother Chunk\r\n",
      "0\r\n\r\n",
    }, output))
  end)

  test("server encoder - Chunked Encoding, auto keepalive end", function ()
    local output = testCodec(codec.server.encoder, {
      { code = 200,
        {"Transfer-Encoding", "chunked"}
      },
      "Hello World\n",
      "Another Chunk",
      { code = 304 },
    })
    p(output)
    assert(deepEqual({
      "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n",
      "c\r\nHello World\n\r\n",
      "d\r\nAnother Chunk\r\n",
      "0\r\n\r\n",
      "HTTP/1.1 304 Not Modified\r\n\r\n",
    }, output))
  end)

  test("client encoder", function ()
    local output = testCodec(codec.client.encoder, {
      { method = "GET", path = "/my-resource",
        {"Accept", "*/*"}
      },
      "",
      { method = "GET", path = "/favicon.ico",
        {"Accept", "*/*"}
      },
      { method = "GET", path = "/orgs/luvit",
        {"User-Agent", "Luvit Unit Tests"},
        {"Host", "api.github.com"},
        {"Accept", "*/*"},
        {"Authorization", "token 6d2fc6ae08215d69d693f5ca76ea87c7780a4275"},
      }
    })
    p(output)
    assert(deepEqual({
      "GET /my-resource HTTP/1.1\r\nAccept: */*\r\n\r\n",
      "GET /favicon.ico HTTP/1.1\r\nAccept: */*\r\n\r\n",
      "GET /orgs/luvit HTTP/1.1\r\nUser-Agent: Luvit Unit Tests\r\nHost: api.github.com\r\nAccept: */*\r\nAuthorization: token 6d2fc6ae08215d69d693f5ca76ea87c7780a4275\r\n\r\n"
    }, output))
  end)

  test("Real HTTP request", function (expect)
    uv.getaddrinfo("luvit.io", "http", {
      socktype = "stream",
      family = "inet",
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
        chain(codec.client.decoder, expect(function (read, write)
          local req = {
            method = "GET", path = "/",
            {"Host", "luvit.io"},
            {"User-Agent", "luvit"},
            {"Accept", "*/*"},
          }
          p(req)
          write(req)
          local res = read()
          -- luvit.io should redirect to https version
          assert(res.code == 301)
          p(res)
          local contentLength
          for i = 1, #res do
            if string.lower(res[i][1]) == "content-length" then
              contentLength = tonumber(res[i][2])
              break
            end
          end
          for item in read do
            if item == "" then
              write()
            else
              contentLength = contentLength - #item
              p(item)
            end
          end
          assert(contentLength == 0)
        end), codec.client.encoder)(read, write)
      end))
    end))
  end)

end)
