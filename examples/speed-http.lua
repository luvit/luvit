-- A simple keepalive benchmark to see how fast we can make http
-- test with one of the following tools:
--   luvit examples/http-bench.lua
--   ab -t 10 -n 500000 -c 100 -k http://127.0.0.1:8080/
--   httperf --hog 127.0.0.1 --port 8080 --num-conns=100  --num-calls=1000
--
local http = require('http')
local table = require('table')

local function onRequest(req, res)
  res.statusCode = 200
  res.headers = {{"Content-Length",6}}
  res.keepAlive = true
  res:flushHeaders()
  res.socket:write('Hello\n')
end

http.createServer(onRequest):listen(8080)
print("Server listening at http://localhost:8080/")

print("http server listening on 8080")
