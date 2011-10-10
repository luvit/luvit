local UV = require('uv')
local user_meta = require('utils').user_meta
local stream_meta = require('stream').meta
local PIPE = {}

local pipe_prototype = {}
setmetatable(pipe_prototype, stream_meta)
PIPE.prototype = pipe_prototype

function PIPE.new(ipc)
  local pipe = {
    userdata = UV.new_pipe(ipc and 1 or 0),
    prototype = pipe_prototype
  }
  setmetatable(pipe, user_meta)
  return pipe
end

return PIPE

