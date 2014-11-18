--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

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

local Emitter = require('core').Emitter
local codec = require('codec')

require('tap')(function(test)
  test('test emitter encoder', function(expect)
    local e, read, write, encoder, onData
    local helloWorld = 'hello world'

    function encoder(read, write)
      write(helloWorld)
    end

    function onData(data)
      assert(#data)
      assert(data == helloWorld)
    end

    e = Emitter:new()
    e:on('data', expect(onData))

    read, write = codec.wrapEmitter(e)
    codec.chain(encoder)(read, write)
  end)
end)
