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

end)
