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


require('tap')(function (test)

  local getinfo = debug.getinfo
  local fakeGetInfo = function(thread, fn, what)
    if type(thread) == "number" then
      thread = thread + 1
    end
    local info = getinfo(thread, fn, what)
    if info.source and info.source:sub(1,1) == "@" then
      info.source = info.source:gsub("test%-require%.lua", "fixtures/fake.lua")
    end
    return info
  end
  _G.num_loaded = 0

  test("native lua require should still be there", function ()
    print(require, _G.require)
    assert(require == _G.require)
  end)

  test("required files should get their package name as ...", function ()
    debug.getinfo = fakeGetInfo
    local moduleKey = require('./module.lua')
    print(moduleKey)
    assert(moduleKey ~= nil)
    debug.getinfo = getinfo
  end)

  test("relative require with extension", function ()
    debug.getinfo = fakeGetInfo
    local mod1 = require('./libs/module1/init.lua')
    assert(_G.num_loaded == 1)
    assert(mod1[1] == "module1")
    debug.getinfo = getinfo
  end)

  test("relative require as package with index", function ()
    debug.getinfo = fakeGetInfo
    local mod1 = require('./libs/module1')
    print(_G.num_loaded)
    assert(_G.num_loaded == 1)
    assert(mod1[1] == "module1")
    debug.getinfo = getinfo
  end)

  test("relative require with auto-extension", function ()
    debug.getinfo = fakeGetInfo
    local mod1 = require('./libs/module1/init')
    assert(_G.num_loaded == 1)
    assert(mod1[1] == "module1")
    debug.getinfo = getinfo
  end)

  test("cached with different paths", function ()
    debug.getinfo = fakeGetInfo
    local mod1_1 = require('./libs/module1/init.lua')
    local mod1_2 = require('./libs/module1/init')
    local mod1_3 = require('./libs/module1')
    assert(_G.num_loaded == 1)
    assert(mod1_1 == mod1_2)
    assert(mod1_2 == mod1_3)
    debug.getinfo = getinfo
  end)

  test("Lots-o-requires", function ()
    debug.getinfo = fakeGetInfo
    local m1 = require("module1")
    local m1_m2 = require("module1/module2")
    local m2_m2 = require("module2/module2")
    local m3 = require("module3")
    local rm1 = require("./libs/module1")
    local rm1_m2 = require("./libs/module1/module2")
    local rm2_m2 = require("./libs/module2/module2")
    local rm3 = require('./libs/module3')
    local rm2sm1_m2 = require("./libs/module2/../module1/module2")
    local rm1sm2_m2 = require("./libs/module1/../module2/module2")
    assert(_G.num_loaded == 4)
    assert(m1 == rm1)
    assert(m1_m2 == rm1_m2 and m1_m2 == rm2sm1_m2)
    assert(m2_m2 == rm2_m2 and m2_m2 == rm1sm2_m2)
    assert(m3 == rm3)
    debug.getinfo = getinfo
  end)

  test("inter-dependencies", function ()
    debug.getinfo = fakeGetInfo
    local callbacks = {}
    _G.onexit = function (fn)
      callbacks[#callbacks + 1] = fn
    end
    local e = require('./a')
    print(e)
    print{
      A=e.A(),
      C=e.C(),
      D=e.D(),
    }
    assert(e.A() == 'A')
    assert(e.C() == 'C')
    assert(e.D() == 'D')
    for i = 1, #callbacks do
      callbacks[i]()
    end
    print(e)
    print{
      A=e.A(),
      C=e.C(),
      D=e.D(),
    }
    assert(e.A() == 'A done')
    assert(e.C() == 'C done')
    assert(e.D() == 'D done')
    debug.getinfo = getinfo
  end)

  test("circular dependencies throw error", function ()
    debug.getinfo = fakeGetInfo
    local ok, err = pcall(require, 'parent')
    assert(not ok)
    assert(err:find("loop or previous error"), "Wrong error. Expecting loop error, got: \n\n-----\n" .. err .. "\n-----\n")
    print(err)
    debug.getinfo = getinfo
  end)

  test("deps folder", function ()
    debug.getinfo = fakeGetInfo
    _G.num_loaded = 0
    local N = require('moduleN')
    print(N, _G.num_loaded)
    assert(_G.num_loaded == 2)
    assert(N[1] == 'moduleN')
    assert(N.M[1] == 'moduleM')
    debug.getinfo = getinfo
  end)

end)
