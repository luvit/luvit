local uv = require('uv')
local httpServer = require('http-codec').server
local codec = require('codec')
local chain = codec.chain
local wrapStream = codec.wrapStream

local app = require('./app')

local server = uv.new_tcp()

local function onconnection(err)
  assert(not err, err)
  local client = uv.new_tcp()
  assert(uv.accept(server, client))
  local read, write = wrapStream(client)
  chain(httpServer.decoder, app, httpServer.encoder)(read, write)
end

-- Get listening socket from master process
local pipe = uv.new_pipe(true)
uv.pipe_open(pipe, 3)
uv.read_start(pipe, function (err)
  assert(not err, err)
  if uv.pipe_pending_count(pipe) > 0 then
    local pending_type = uv.pipe_pending_type(pipe)
    assert(pending_type == "TCP")
    assert(uv.accept(pipe, server))
    assert(uv.listen(server, 256, onconnection))
    uv.close(pipe)
    print("Worker received server handle")
  end
end)
