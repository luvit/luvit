local http = require("http")
local https = require("https")
local pathJoin = require('luvi').path.join
local fs = require('fs')

local function onRequest(req, res)
  print(req.socket.options and "https" or "http", req.method, req.url)
  local body = "Hello world\n"
  res:setHeader("Content-Type", "text/plain")
  res:setHeader("Content-Length", #body)
  res:finish(body)
end

http.createServer(onRequest):listen(8080)
print("Server listening at http://localhost:8080/")

https.createServer({
  key = fs.readFileSync(pathJoin(module.dir, "key.pem")),
  cert = fs.readFileSync(pathJoin(module.dir, "cert.pem")),
}, onRequest):listen(8443)
print("Server listening at https://localhost:8443/")

