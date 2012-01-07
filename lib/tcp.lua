--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

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

local UV = require('uv')
local user_meta = require('utils').user_meta
local stream_meta = require('stream').meta
local TCP = {}

local tcp_prototype = {}
setmetatable(tcp_prototype, stream_meta)
TCP.prototype = tcp_prototype

-- Used by things like Response that "inherit" from tcp
TCP.meta = {__index=TCP.prototype}

function TCP.new()
  local tcp = {
    userdata = UV.new_tcp(),
    prototype = tcp_prototype
  }
  setmetatable(tcp, user_meta)
  return tcp
end

function TCP.create_server(ip, port, on_connection)
  local server = TCP.new()
  server:bind(ip, port)

  server:listen(function (err)
    if (err) then
      return server:emit("error", err)
    end
    local client = TCP.new()
    server:accept(client)
    client:read_start()
    on_connection(client)
  end)

  return server
end

return TCP
