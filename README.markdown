# Luvit (Lua + libUV + jIT = pure awesomesauce)

Luvit is an attempt to do something crazy by taking nodeJS's awesome
architecture and dependencies and seeing how it fits in the Lua language.

This project is still under heavy development, but it's showing promise.  In initial benchmarking with a hello world server, this is between 2 and 4 times faster than nodeJS.

    -- Load the http library
    local HTTP = require("lib/http")

    -- Create a simple nodeJS style hello-world server
    HTTP.create_server(function (req, res)
      res:write_head(200, {
        ["Content-Type"] = "text/plain",
        ["Content-Length"] = "11"
      })
      res:write("Hello World")
      res:finish()
    end):listen(8080)

    -- Give a friendly message
    print("Server listening at http://localhost:8080/")


This is NOT a complete project and may never finish.  But for now I'm
having fun trying to broaden my understanding.

## Questions?

Send me an email or github message or come visit #luvit on freenode irc.
