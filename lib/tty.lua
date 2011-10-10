local UV = require('uv')
local user_meta = require('utils').user_meta
local stream_meta = require('stream').meta
local TTY = {}

local tty_prototype = {}
setmetatable(tty_prototype, stream_meta)
TTY.prototype = tty_prototype

function TTY.new(fd)
  local tty = {
    userdata = UV.new_tty(fd),
    prototype = tty_prototype
  }
  setmetatable(tty, user_meta)
  return tty
end

return TTY
