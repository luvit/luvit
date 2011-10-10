local UV = require('uv')
local user_meta = require('utils').user_meta
local stream_meta = require('stream').meta

local pipe_prototype = {}
setmetatable(pipe_prototype, stream_meta)

local function new_pipe(ipc)
  local pipe = {
    userdata = UV.new_pipe(ipc and 1 or 0),
    prototype = pipe_prototype
  }
  setmetatable(pipe, user_meta)
  return pipe
end

return {
  new = new_pipe,
  prototype = pipe_prototype,
  meta = pipe_meta
}
