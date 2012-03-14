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

local binding = require('zlib_native')

--
-- generic zlib stream
--

local Zlib = require('core').iStream:extend()

function Zlib:initialize(what, ...)
  self.zlib = binding.new(what, ...)
end

function Zlib:write(chunk, flag)
  if not flag then
    flag = chunk == nil and 'finish' or nil
  end
  local text, err = self.zlib:write(chunk, flag)
  if not text then
    self:emit('error', err)
  else
    if #text > 0 then
      self:emit('data', text)
    end
    self:emit('drain')
  end
end

function Zlib:done()
  self.zlib = nil
  self:emit('end')
end

function Zlib:close()
  self.zlib = nil
end

--
-- module
--

return {
  Zlib = Zlib,
}
