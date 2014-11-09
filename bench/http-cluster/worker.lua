--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

local uv = require('uv')
local httpServer = require('codecs/http').server
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
