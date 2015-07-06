-- A simple keepalive benchmark to see how fast we can make http
-- test with one of the following tools:
--   luvit examples/http-bench.lua
--   ab -t 10 -n 500000 -c 100 -k http://127.0.0.1:8080/
--   httperf --hog 127.0.0.1 --port 8080 --num-conns=100  --num-calls=1000
--
local net = require('net')
local table = require('table')
local iStream = require('core').iStream
local HttpParser = require('http_parser')

local function formatResponse(code, reason, headers, body)
  local lines = {"HTTP/1.1 " .. code .. " " .. reason .. "\r\n"}
  for field, value in pairs(headers) do
    table.insert(lines, field .. ": " .. value .. "\r\n")
  end
  table.insert(lines, "\r\n" .. body)
  return table.concat(lines, "")
end

local function onRequest(req)
  -- p(req)
  local headers = {["Content-Length"] = 6}
  local shouldClose = true
  if req.info.should_keep_alive then
    shouldClose = false
    if req.info.version_minor == 0 then
      headers.Connection = "Keep-Alive"
    end
  else
    if req.info.version_minor == 1 then
      headers.Connection = "Close"
    end
  end

  req.socket:write(formatResponse(200, "OK", headers, "Hello\n"))
  if shouldClose then
    req.socket:close()
  end
end

net.createServer(function (client)
  local request
  local headers
  local url
  local current_field
  local parser = HttpParser.new("request", {
    onMessageBegin = function ()
      headers = {}
    end,
    onUrl = function (value)
      url = value
    end,
    onHeaderField = function (field)
      current_field = field
    end,
    onHeaderValue = function (value)
      headers[current_field:lower()] = value
    end,
    onHeadersComplete = function (info)
      request = iStream:new()
      request.readable = true
      request.parser = parser
      request.socket = client
      request.info = info
      request.headers = headers
      request.url = url
      onRequest(request)
    end,
    onBody = function (chunk)
      request:emit("data", chunk)
    end,
    onMessageComplete = function ()
      request:emit("end")
    end
  });

  client:on("data", function (chunk)
    local length = #chunk
    if length == 0 then return end
    local nparsed = parser:execute(chunk, 0, length)
    if nparsed < length and request then
      request:emit("error", "parse error")
    end
  end)

  client:once("end", function ()
    parser:finish()
  end)

  client:once("close", function ()
    parser:finish()
  end)


end):listen(8080)
print("http server listening on 8080")