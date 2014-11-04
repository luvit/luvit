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

  test("file not found", function (expect)
    fs.stat("bad-path", expect(function (err, stat)
      p{err=err,stat=stat}
      assert(not stat)
      assert(string.match(err, "^ENOENT:"))
    end))
  end)

  test("optional args", function (expect)
    fs.open("bad-path", "r", tonumber("644", 8), expect(function (err)
      assert(string.match(err, "^ENOENT:"))
    end))
    fs.open("bad-path", "r", expect(function (err)
      assert(string.match(err, "^ENOENT:"))
    end))
    fs.open("bad-path", expect(function (err)
      assert(string.match(err, "^ENOENT:"))
    end))
    local _, err
    _, err = fs.openSync("bad-path", "r", tonumber("644", 8))
    assert(string.match(err, "^ENOENT:"))
    _, err = fs.openSync("bad-path", "r")
    assert(string.match(err, "^ENOENT:"))
    _, err = fs.openSync("bad-path")
    assert(string.match(err, "^ENOENT:"))
  end)

  test("readdir", function (expect)
    fs.readdir(module.dir, expect(function (err, files)
      assert(not err, err)
      p(files)
      assert(type(files) == 'table')
      assert(type(files[1] == 'string'))
    end))
  end)

  test("readdir sync", function ()
    local files = assert(fs.readdirSync(module.dir))
    p(files)
    assert(type(files) == 'table')
    assert(type(files[1] == 'string'))
  end)

  test("scandir callback", function (expect)
    fs.scandir(module.dir, expect(function (err, it)
      assert(not err, err)
      for k, v in it do
        p{name=k,type=v}
      end
    end))
  end)

  test("scandir coroutine", function (expect)
    local done = expect(function () end)
    coroutine.wrap(function ()
      local thread = coroutine.running()
      for k,v in fs.scandir(module.dir, thread) do
        p{name=k,type=v}
      end
      done()
    end)()
  end)

  test("scandir sync", function ()
    for k,v in fs.scandirSync(module.dir) do
      p{name=k,type=v}
    end
  end)
end)
