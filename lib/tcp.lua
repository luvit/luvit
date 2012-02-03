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
local Stream = require('core').Stream

local tcp = {}

local Tcp = Stream:extend()
tcp.Tcp = Tcp

function Tcp:initialize()
  --_oldprint("Tcp:initialize")
  self.userdata = uv.newTcp()
end

function Tcp:nodelay(enable)
  --_oldprint("Tcp:nodelay")
  return uv.tcpNodelay(self.userdata, enable)
end

function Tcp:keepalive(enable, delay)
  --_oldprint("Tcp:keepalive")
  return uv.tcpKeepalive(self.userdata, enable, delay)
end

--TODO: put port first, make host optional and possibly merge bind and bind6
function Tcp:bind(host, port)
  --_oldprint("Tcp:bind")
  return uv.tcpBind(self.userdata, host, port)
end

function Tcp:bind6(host, port)
  --_oldprint("Tcp:bind6")
  return uv.tcpBind6(self.userdata, host, port)
end

function Tcp:getsockname()
  --_oldprint("Tcp:getsockname")
  return uv.tcpGetsockname(self.userdata)
end

function Tcp:getpeername()
  --_oldprint("Tcp:getpeername")
  return uv.tcpGetpeername(self.userdata)
end

function Tcp:connect(ip_address, port)
  --_oldprint("Tcp:connect")
  return uv.tcpConnect(self.userdata, ip_address, port)
end

function Tcp:connect6(ip_address, port)
  --_oldprint("Tcp:connect6")
  return uv.tcpConnect6(self.userdata, ip_address, port)
end

return tcp
