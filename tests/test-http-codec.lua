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

local codec = require('http-codec')


require('tap')(function (test)

  local function testCodec(processor, inputs)
    local outputs = {}
    local i = 0
    processor(function ()
      i = i + 1
      return inputs[i]
    end, function (value)
      outputs[#outputs + 1] = value
    end)
    return outputs
  end

  test("http server parser", function ()
    local output = testCodec(codec.server.decoder, {
      "GET /path HTTP/1.1\r\n",
      "User-Agent: Luvit-Test\r\n\r\n"
    })
    p(output)
    assert(#output == 1)
    local req = output[1]
    assert(req.method == "GET")
    assert(req.path == "/path")
    assert(req.version == 1.1)
    local headers = req.headers
    assert(#headers == 1)
    assert(headers[1][1] == "User-Agent")
    assert(headers[1][2] == "Luvit-Test")
  end)

  test("http client parser", function ()
    local output = testCodec(codec.client.decoder, {
      "HTTP/1.0 200 OK\r\n",
      "User-Agent: Luvit-Test\r\n\r\n"
    })
    p(output)
    assert(#output == 1)
    local res = output[1]
    assert(res.code == 200)
    assert(res.reason == "OK")
    assert(res.version == 1.0)
    local headers = res.headers
    assert(#headers == 1)
    assert(headers[1][1] == "User-Agent")
    assert(headers[1][2] == "Luvit-Test")
  end)

  test("http 1.0 Keep-Alive", function ()
    local output = testCodec(codec.server.decoder, {
      "GET / HTTP/1.0\r\n",
      "Connection: Keep-Alive\r\n\r\n",
      "DELETE /bad-resource HTTP/1.0\r\n",
      "Connection: Keep-Alive\r\n\r\n",
    })
    p(output)
    assert(type(output[2]) == "table")
    assert(output[1].keepAlive)
    assert(#output == 2)
  end)

  test("http 1.0 Raw body", function ()
    local output = testCodec(codec.server.decoder, {
      "GET / HTTP/1.0\r\n",
      "User-Agent: Test\r\n\r\n",
      "DELETE /bad-resource HTTP/1.0\r\n",
      "Connection: Keep-Alive\r\n\r\n",
    })
    p(output)
    assert(type(output[1]) == "table")
    assert(not output[1].keepAlive)
    assert(type(output[2]) == "string")
  end)

  test("http 1.1 Keep-Alive", function ()
    local output = testCodec(codec.server.decoder, {
      "HEAD / HTTP/1.1\r\n\r\n",
      "DELETE /bad-resource HTTP/1.1\r\n\r\n",
    })
    p(output)
    assert(type(output[2]) == "table")
    assert(output[1].keepAlive)
    assert(#output == 2)
  end)

  test("http 1.1 Keep-Alive with bodies", function ()
    local output = testCodec(codec.server.decoder, {
      "POST /upload HTTP/1.1\r\n",
      "Content-Length: 12\r\n",
      "\r\nHello World\nDELETE ",
      "/ HTTP/1.1\r\n\r\n",
    })
    p(output)
    assert(type(output[1]) == "table")
    assert(type(output[2]) == "string")
    assert(type(output[3]) == "table")
    assert(#output == 3)
  end)

  test("http 1.1 Raw body", function ()
    local output = testCodec(codec.server.decoder, {
      "GET / HTTP/1.0\r\n",
      "Connection: Close\r\n\r\n",
      "User-Agent: Test\r\n\r\n",
      "DELETE /bad-resource HTTP/1.0\r\n",
    })
    p(output)
    assert(type(output[1]) == "table")
    assert(not output[1].keepAlive)
    assert(type(output[2]) == "string")
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
  end)

  test("server encoder", function ()
    local output = testCodec(codec.server.encoder, {
      { code = 200 }
    })
    p(output)
    assert(output[1] == "HTTP/1.1 200 OK\r\n\r\n")
    assert(#output == 1)
  end)

  test("server encoder - Keepalive", function ()
    local output = testCodec(codec.server.encoder, {
      { code = 200, headers = {
        {"Content-Length", 12}
      }},
      "Hello World\n",
      { code = 304 },
    })
    p(output)
    assert(output[1] == "HTTP/1.1 200 OK\r\nContent-Length: 12\r\n\r\n")
    assert(output[2] == "Hello World\n")
    assert(output[3] == "HTTP/1.1 304 Not Modified\r\n\r\n")
    assert(#output == 3)
  end)

  test("server encoder - Chunked Encoding", function ()
    local output = testCodec(codec.server.encoder, {
      { code = 200, headers = {
        {"Transfer-Encoding", "chunked"}
      }},
      "Hello World\n",
      "Another Chunk",
      false,
      { code = 304 },
    })
    p(output)
    assert(output[1] == "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n")
    assert(output[2] == "c\r\nHello World\n\r\n")
    assert(output[3] == "d\r\nAnother Chunk\r\n")
    assert(output[4] == "0\r\n\r\n")
    assert(output[5] == "HTTP/1.1 304 Not Modified\r\n\r\n")
    assert(#output == 5)
  end)

  test("client encoder", function ()
    local output = testCodec(codec.client.encoder, {
      { method = "GET", path = "/my-resource", headers = {
        {"Accept", "*/*"}
      }},
      { method = "GET", path = "/favicon.ico", headers = {
        {"Accept", "*/*"}
      }},
    })
    p(output)
  end)

end)
