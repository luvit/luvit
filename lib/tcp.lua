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

local uv = require('uv')
local Stream = require('stream')


local Tcp = Stream:extend()

function Tcp.prototype:initialize()
  --_oldprint("Tcp.prototype:initialize")
  self.userdata = uv.newTcp()
end

function Tcp.prototype:nodelay(enable)
  --_oldprint("Tcp.prototype:nodelay")
  return uv.tcpNodelay(self.userdata, enable)
end

function Tcp.prototype:keepalive(enable, delay)
  --_oldprint("Tcp.prototype:keepalive")
  return uv.tcpKeepalive(self.userdata, enable, delay)
end

--TODO: put port first, make host optional and possibly merge bind and bind6
function Tcp.prototype:bind(host, port)
  --_oldprint("Tcp.prototype:bind")
  return uv.tcpBind(self.userdata, host, port)
end

function Tcp.prototype:bind6(host, port)
  --_oldprint("Tcp.prototype:bind6")
  return uv.tcpBind6(self.userdata, host, port)
end

function Tcp.prototype:getsockname()
  --_oldprint("Tcp.prototype:getsockname")
  return uv.tcpGetsockname(self.userdata)
end

function Tcp.prototype:getpeername()
  --_oldprint("Tcp.prototype:getpeername")
  return uv.tcpGetpeername(self.userdata)
end

function Tcp.prototype:connect(ip_address, port)
  --_oldprint("Tcp.prototype:connect")
  return uv.tcpConnect(self.userdata, ip_address, port)
end

function Tcp.prototype:connect6(ip_address, port)
  --_oldprint("Tcp.prototype:connect6")
  return uv.tcpConnect6(self.userdata, ip_address, port)
end

function Tcp:createServer(ip, port, onConnection)
  --_oldprint("Tcp.createServer")
  local server = Tcp:new()
  server:bind(ip, port)

  server:listen(function (err)
    if (err) then
      return server:emit("error", err)
    end
    local client = Tcp:new()
    server:accept(client)
    client:readStart()
    onConnection(client)
  end)

  return server
end

return Tcp
