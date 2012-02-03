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
local Handle = require('handle')

local Udp = Handle:extend()

function Udp.prototype:initialize()
  self.userdata = uv.newUdp()
end

function Udp.prototype:bind(host, port)
  return uv.udpBind(self.userdata, host, port)
end

function Udp.prototype:bind6(host, port)
  return uv.udpBind6(self.userdata, host, port)
end

function Udp.prototype:setMembership(multicast_addr, interface_addr, option)
  return uv.udpSetMembership(self.userdata, multicast_addr, interface_addr, option)
end

function Udp.prototype:getsockname()
  return uv.udpGetsockname(self.userdata)
end

function Udp.prototype:send(...)
  return uv.udpSend(self.userdata, ...)
end

function Udp.prototype:send6(...)
  return uv.udpSend6(self.userdata, ...)
end

function Udp.prototype:recvStart()
  return uv.udpRecvStart(self.userdata)
end

function Udp.prototype:recvStop()
  return uv.udpRecvStop(self.userdata)
end

return Udp
