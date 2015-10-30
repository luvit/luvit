local http = require("http")
local https = require("https")
local pathJoin = require('luvi').path.join
local fs = require('fs')

local snapshot = require('snapshot')
local potential = {}
local S1
local function leakCheck()
  -- Take a heap measurement and snapshot
  collectgarbage()
  collectgarbage()
  local C2 = collectgarbage("count")
  local S2 = snapshot()

  -- If we have history, do some analysis
  if S1 then
    local count = 0

    -- Log all objects that were in the old potential list and are still around.
    -- Also clear the potential list
    for i = #potential, 1, -1 do
      local k = potential[i]
      local v = S2[k]
      if v then
        count = count + 1
        p(k)
        print(v)
      end
      potential[i] = nil
    end

    -- Store the keys for all heap objects that are new since last snapshot.
    for k, v in pairs(S2) do
      if S1[k] == nil then
        potential[#potential + 1] = k
      end
    end

    -- Log some heap statistics
    print("Lua Heap: " .. C2 .. "kb, Leaked Objects: " .. count)

  end

  -- What was new is now old.
  S1 = S2
end

local function onRequest(req, res)
  print(req.socket.options and "https" or "http", req.method, req.url)
  local body = "Hello world\n"
  res:setHeader("Content-Type", "text/plain")
  res:setHeader("Content-Length", #body)
  res:finish(body)
  res:on('close', leakCheck)
end

http.createServer(onRequest):listen(8080)
print("Server listening at http://localhost:8080/")

https.createServer({
  key = fs.readFileSync(pathJoin(module.dir, "key.pem")),
  cert = fs.readFileSync(pathJoin(module.dir, "cert.pem")),
}, onRequest):listen(8443)
print("Server listening at https://localhost:8443/")

