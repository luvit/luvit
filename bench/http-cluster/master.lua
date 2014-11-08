local uv = require('uv')
local pathJoin = require('luvi').path.join

local server = uv.new_tcp()
uv.tcp_bind(server, "127.0.0.1", 8080)

local workerPath = pathJoin(module.dir, "worker.lua")
for i = 1, #uv.cpu_info() do
  local pipe = uv.new_pipe(true)
  local child, pid
  child, pid = uv.spawn(uv.exepath(), {
    args = {workerPath},
    stdio = {0,1,2,pipe},
  }, function (code, signal)
    print("Worker " .. i .. " exited with code " .. code .. " and signal " .. signal)
    uv.close(child)
  end)
  uv.write2(pipe, ".", server, function (err)
    assert(not err, err)
    uv.close(pipe)
  end)
  print("Worker " .. i .. " spawned at pid " .. pid)
end
print("Test HTTP server at http://127.0.0.1:8080/")
