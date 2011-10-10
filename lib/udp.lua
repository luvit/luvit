local UV = require('uv')
local user_meta = require('utils').user_meta
local emitter_meta = require('emitter').meta

local udp_prototype = {}
setmetatable(udp_prototype, emitter_meta)

local function new_udp()
  local udp = {
    userdata = UV.new_udp(),
    prototype = udp_prototype
  }
  setmetatable(udp, user_meta)
  return udp
end

return {
  new = new_udp,
  prototype = udp_prototype,
  meta = udp_meta
}
