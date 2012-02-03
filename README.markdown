# Luvit (Lua + libUV + jIT = pure awesomesauce)

[![Build Status](https://secure.travis-ci.org/luvit/luvit.png)](http://travis-ci.org/luvit/luvit)

Luvit is an attempt to do something crazy by taking nodeJS's awesome
architecture and dependencies and seeing how it fits in the Lua language.

This project is still under heavy development, but it's showing promise.  In initial benchmarking with a hello world server, this is between 2 and 4 times faster than nodeJS.


    -- Load the http library
    local HTTP = require("http")

    -- Create a simple nodeJS style hello-world server
    HTTP.create_server("0.0.0.0", 8080, function (req, res)
      local body = "Hello World\n"
      res:write_head(200, {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = #body
      })
      res:finish(body)
    end)

    -- Give a friendly message
    print("Server listening at http://localhost:8080/")


This is an alpha project and still has rough edges.  It's complete enough to start writing programs with it and having fun.

## Questions?

Send me an email or github message or come visit #luvit on freenode irc.
