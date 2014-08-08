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

require("helper")

--
-- test listenerCount
--
assert(2 == require('core').Emitter:new()
  :on("foo", function(a) end)
  :on("foo", function(a,b) end)
  :on("bar", function(a,b) end)
  :listenerCount("foo"))
assert(0 == require('core').Emitter:new():listenerCount("non-exist"))

--
-- chaining works
--
local bCallback = false
require('core').Emitter:new()
  :on("foo", function (x)
    bCallback = true
    assert(deep_equal(x, { a = "b" }))
  end)
  :emit("foo", { a = "b" })

--
-- remove all listeners
--
local dataCallback1 = false
local dataCallback2 = false
local em = require('core').Emitter:new()
em:on('data', function(data)
  dataCallback1 = true
end)
em:removeAllListeners()
em:on('data', function(data)
  dataCallback2 = true
end)
em:emit('data', 'Go Fish')

process:on('exit', function()
  assert(bCallback == true)
  assert(dataCallback1 == false)
  assert(dataCallback2 == true)
end)
