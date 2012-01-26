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
local Handle = require('handle')

local UDP = Handle:extend()

function UDP.prototype:initialize()
  self.userdata = UV.new_udp()
end

function UDP.prototype:bind(host, port)
  return UV.udp_bind(self.userdata, host, port)
end

function UDP.prototype:bind6(host, port)
  return UV.udp_bind6(self.userdata, host, port)
end

function UDP.prototype:set_membership(multicast_addr, interface_addr, option)
  return UV.udp_set_membership(self.userdata, multicast_addr, interface_addr, option)
end

function UDP.prototype:getsockname()
  return UV.udp_getsockname(self.userdata)
end

function UDP.prototype:send(...)
  return UV.udp_send(self.userdata, ...)
end

function UDP.prototype:send6(...)
  return UV.udp_send6(self.userdata, ...)
end

function UDP.prototype:recv_start()
  return UV.udp_recv_start(self.userdata)
end

function UDP.prototype:recv_stop()
  return UV.udp_recv_stop(self.userdata)
end

return UDP
