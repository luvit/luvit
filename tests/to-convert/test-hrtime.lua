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
timer = require("timer")

local hrtime = require('uv').Process.hrtime

t1 = hrtime()
expect("timeout")
timer.setTimeout(200, function (arg1)
  t2 = hrtime()
  fulfill("timeout")
  assert((t2 - t1) > 0 and (t2 - t1) < 400)
end, "test1")
