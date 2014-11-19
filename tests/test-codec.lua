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
local deepEqual = require('deep-equal')
local setImmediate = require('timer').setImmediate

require('tap')(function(test)
  test('test emitter encoder', function(expect)
    local e, read, write, encoder, onData, onEnd, onDrain
    local emittedEvents = {}
    local readEvents = {}

    local check = expect(function ()
      assert(deepEqual({'e1', 'e2'}, readEvents))
    end)

    function encoder(read, write)
      coroutine.wrap(function ()
        for item in read do
          p{"read", item=item}
          readEvents[#readEvents + 1] = item
        end
        p{"read end"}
        check()
      end)()
      coroutine.wrap(function ()
        write('w1')
        e:pause()
        write('w2')
        write()
      end)()
    end

    function onData(data)
      p{'on data',data=data}
      assert(#data)
      emittedEvents[#emittedEvents + 1] = data
    end

    function onDrain()
      p{'on drain'}
    end

    function onEnd()
      p{'on end'}
      assert(deepEqual({'w1','w2'}, emittedEvents))
    end

    e = Emitter:new()
    e:on('data', expect(onData))
    e:on('end', expect(onEnd))
    e:on('drain', expect(onDrain))

    read, write = codec.wrapEmitter(e)
    codec.chain(encoder)(read, write)

    e:write('e1')
    setImmediate(function ()
      e:resume()
      setImmediate(function ()
        e:write('e2')
        e:shutdown()
      end)
    end)
  end)
end)
