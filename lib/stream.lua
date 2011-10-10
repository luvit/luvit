local emitter_meta = require('emitter').meta
local stream_prototype = {}
setmetatable(stream_prototype, emitter_meta)
local stream_meta = {__index=stream_prototype}

local function new_stream()
  local stream = {}
  setmetatable(stream, stream_meta)
  return stream
end

return {
  new = new_stream,
  prototype = stream_prototype,
  meta = stream_meta
}
