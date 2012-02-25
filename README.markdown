# Luvit (Lua + libUV + jIT = pure awesomesauce)

[![Build Status](https://secure.travis-ci.org/luvit/luvit.png)](http://travis-ci.org/luvit/luvit)

Luvit is an attempt to do something crazy by taking node.js' awesome architecture and dependencies and seeing how it fits in the Lua language.

This project is still under heavy development, but it's showing promise. In initial benchmarking with a hello world server, this is between 2 and 4 times faster than node.js. Version 0.2.0 is the first stable release.

Do you have a question/want to learn more? Make sure to check out the [mailing list](http://groups.google.com/group/luvit/) and drop by our IRC channel, #luvit on Freenode.

```lua
-- Load the http library
local HTTP = require("http")

-- Create a simple nodeJS style hello-world server
HTTP.createServer(function (req, res)
  local body = "Hello World\n"
  res:writeHead(200, {
    ["Content-Type"] = "text/plain",
    ["Content-Length"] = #body
  })
  res:finish(body)
end):listen(8080)

-- Give a friendly message
print("Server listening at http://localhost:8080/")
```

