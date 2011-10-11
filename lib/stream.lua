local emitter_meta = require('emitter').meta
local Stream = {prototype = {}}
local stream_prototype = Stream.prototype
setmetatable(stream_prototype, emitter_meta)
local stream_meta = {__index=stream_prototype}
Stream.meta = stream_meta

function Stream.new()
  local stream = {}
  setmetatable(stream, stream_meta)
  return stream
end

function Stream.prototype:pipe(target)
  self:on('data', function (chunk, len)
    target:write(chunk)
  end)
  self:on('end', function ()
    target:close()
  end)
end

return Stream
