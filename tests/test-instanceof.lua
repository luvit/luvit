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

local core = require("core")
Object = core.Object
Emitter = core.Emitter
instanceof = core.instanceof

local uv = require("uv")
Handle = uv.Handle

local o = Object:new()
local e = Emitter:new()
local h = Handle:new()

assert(instanceof(o, Object))
assert(not instanceof(o, Emitter))
assert(not instanceof(o, Handle))

assert(instanceof(e, Emitter))
assert(instanceof(e, Object))
assert(not instanceof(e, Handle))

assert(instanceof(h, Handle))
assert(instanceof(h, Emitter))
assert(instanceof(h, Object))

assert(not instanceof({}, Object))
assert(not instanceof(2, Object))
assert(not instanceof('a', Object))
assert(not instanceof(function() end, Object))

-- Caveats: We would like to these to be false, but we could not.
assert(instanceof(Object, Object))
assert(instanceof(Emitter, Object))
