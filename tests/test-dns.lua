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

local dns = require('dns')

require('tap')(function (test)
  test("resolve4", function (expect)
    dns.resolve4('luvit.io', expect(function(err, answers)
      assert(not err)
      assert(#answers > 0)
      p(answers)
    end))
  end)
  test("resolve6", function (expect)
    dns.resolve6('luvit.io', expect(function(err, answers)
      assert(not err)
      p(answers)
      assert(#answers > 0)
    end))
  end)
  test("resolve6", function (expect)
    dns.resolve6('luvit.io', expect(function(err, answers)
      assert(not err)
      p(answers)
      assert(#answers > 0)
    end))
  end)
  test("resolveSrv", function (expect)
    dns.resolveSrv('_jabber._tcp.google.com', expect(function(err, answers)
      assert(not err)
      p(answers)
      assert(#answers > 0)
    end))
  end)
  test("resolveMx", function (expect)
    dns.resolveMx('luvit.io', expect(function(err, answers)
      assert(not err)
      p(answers)
      assert(#answers > 0)
    end))
  end)
  test("resolveNs", function (expect)
    dns.resolveNs('luvit.io', expect(function(err, answers)
      assert(not err)
      p(answers)
      assert(#answers > 0)
    end))
  end)
  test("resolveCname", function (expect)
    dns.resolveCname('ghs.google.com', expect(function(err, answers)
      assert(not err)
      p(answers)
      assert(#answers > 0)
    end))
  end)
  test("resolveTxt", function (expect)
    dns.resolveTxt('google.com', expect(function(err, answers)
      assert(not err)
      p(answers)
      assert(#answers > 0)
    end))
  end)
end)
