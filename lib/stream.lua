--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

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
