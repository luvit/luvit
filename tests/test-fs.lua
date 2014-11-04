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
local fs = require('fs')
require('tap')(function (test)

  test("readfile with callbacks", function (expect)
    fs.open(module.path, "r", expect(function (err, fd)
      assert(not err, err)
      p{fd=fd}
      fs.fstat(fd, expect(function (err, stat)
        assert(not err, err)
        p(stat)
        fs.read(fd, stat.size, expect(function (err, data)
          assert(not err, err)
          assert(#data == stat.size)
          fs.close(fd, expect(function (err)
            assert(not err, err)
          end))
        end))
      end))
    end))
  end)

  test("readfile sync", function ()
    local fd = assert(fs.openSync(module.path))
    p{fd=fd}
    local stat = assert(fs.fstatSync(fd))
    p(stat)
    local chunk = assert(fs.readSync(fd, stat.size))
    assert(stat.size == #chunk)
    p{chunk=#chunk}
    fs.closeSync(fd)
  end)

  test("readfile coroutine", function (expect)
    local finish = expect(function () end)
    coroutine.wrap(function ()
      local thread = coroutine.running()
      p{thread=thread}
      local fd = assert(fs.open(module.path, "r", thread))
      p{fd=fd}
      local stat = assert(fs.fstat(fd, thread))
      p(stat)
      local chunk = assert(fs.read(fd, stat.size, thread))
      p{chunk=#chunk}
      assert(fs.close(fd, thread))
      finish()
    end)()
  end)

end)
