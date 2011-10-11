local emitter_meta = require('emitter').meta
local Stream = {prototype = {}}
local stream_prototype = Stream.prototype
setmetatable(stream_prototype, emitter_meta)
local stream_meta = {__index=stream_prototype}

function Stream.new()
  local stream = {}
  setmetatable(stream, stream_meta)
  return stream
end

return Stream
