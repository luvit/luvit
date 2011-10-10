local UV = require('uv')
local user_meta = require('utils').user_meta
local stream_meta = require('stream').meta

local tty_prototype = {}
setmetatable(tty_prototype, stream_meta)

local function new_tty(fd)
  local tty = {
    userdata = UV.new_tty(fd),
    prototype = tty_prototype
  }
  setmetatable(tty, user_meta)
  return tty
end

return {
  new = new_tty,
  prototype = tty_prototype,
  meta = tty_meta
}
