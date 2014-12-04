local HTTP = require "http"
local Stack = require "stack"

local MethodEcho = require "method_echo"
local UrlEcho = require "url_echo"

HTTP.createServer("0.0.0.0", 8080, Stack.stack(
  Stack.mount("/methods",
    MethodEcho("PUT"),
    MethodEcho("GET")
  ),
  Stack.mount("/echo", UrlEcho),
  MethodEcho("DELETE")
))

print("Server listening at http://localhost:8080/")
