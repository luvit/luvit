local UV = require('uv')
local user_meta = require('utils').user_meta
local emitter_meta = require('events').emitter_meta



local tcp_prototype = {}
-- TODO: don't skip straight to emitter, go to stream first
setmetatable(tcp_prototype, emitter_meta)

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
  tcp_prototype = tcp_prototype
}
