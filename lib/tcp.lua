local UV = require('uv')
local user_meta = require('utils').user_meta
local stream_meta = require('stream').meta

local tcp_prototype = {}
setmetatable(tcp_prototype, stream_meta)

local function new_tcp()
  local tcp = {
    userdata = UV.new_tcp(),
    prototype = tcp_prototype
  }
  setmetatable(tcp, user_meta)
  return tcp
end

return {
  new = new_tcp,
  prototype = tcp_prototype,
  meta = tcp_meta
}
