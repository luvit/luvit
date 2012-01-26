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
local UV = require('uv')
local Handle = require('handle')

local Stream = Handle:extend()

function Stream.prototype:shutdown()
  --_oldprint("Stream.prototype:shutdown")
  return UV.shutdown(self.userdata)
end

function Stream.prototype:listen(callback)
  --_oldprint("Stream.prototype:listen")
  return UV.listen(self.userdata, callback)
end


function Stream.prototype:accept(other_stream)
  --_oldprint("Stream.prototype:accept")
  return UV.accept(self.userdata, other_stream)
end

function Stream.prototype:read_start()
  --_oldprint("Stream.prototype:read_start")
  return UV.read_start(self.userdata)
end

function Stream.prototype:read_stop()
  --_oldprint("Stream.prototype:read_stop")
  return UV.read_stop(self.userdata)
end

function Stream.prototype:write(chunk, callback)
  --_oldprint("Stream.prototype:write")
  return UV.write(self.userdata, chunk, callback)
end

function Stream.prototype:pipe(target)
  --_oldprint("Stream.prototype:pipe")
  self:on('data', function (chunk, len)
    target:write(chunk)
  end)
  self:on('end', function ()
    target:close()
  end)
end

return Stream
