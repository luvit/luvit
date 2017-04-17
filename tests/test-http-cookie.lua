local cookie = require("http-cookie")
local deepEqual = require('deep-equal')

require('tap')(function(test)
  test('build Basic', function(expected)
    assert("foo=bar" == cookie.build({ foo="bar" }))
  end)

  test('build Max-Age', function (expected)
    local options = { max_age = 1 }
    assert("foo=bar; Max-Age=1" == cookie.build({ foo="bar" }, options))
  end)

  test('build Domain', function (expected)
    local options = { domain = ".example.com" }
    assert("foo=bar; Domain=.example.com" == cookie.build({ foo="bar" }, options))
  end)

  test('build Path', function (expected)
    local options = { path = "/base" }
    assert("foo=bar; Path=/base" == cookie.build({ foo="bar" }, options))
  end)


  test('build Expires', function (expected)
    local time = 1398283214
    local options = { expires = time }
    assert(string.gsub(
      "foo=bar; Expires=Thu, 24 Apr 2014 04:04:14 GMT",
      'Thu, 24 Apr 2014 04:04:14 GMT',
      os.date("%a, %d %b %Y %H:%I:%S GMT", time)
      ) == cookie.build({ foo="bar" }, options))
  end)

  test('build HttpOnly', function (expected)
    local options = { http_only = true }
    assert("foo=bar; HttpOnly" ==
        cookie.build({ foo="bar" }, options))
  end)

  test('build Secure', function(expected)
    local options = { secure = true }
    assert("foo=bar; Secure" ==
        cookie.build({ foo="bar" }, options))
  end)

  test('build Everything', function(expected)
    -- case 8: Everything
    local time = 1398283214

    local options = {
        max_age = 3600,
        domain = ".example.com",
        path = "/",
        expires = time,
        http_only = true,
        secure = true
    }

    local expected =
        "foo=bar; Max-Age=3600; Domain=.example.com; " ..
        "Path=/; Expires=Thu, 24 Apr 2014 04:04:14 GMT; " ..
        "HttpOnly; Secure"
    expected = string.gsub(expected,
        'Thu, 24 Apr 2014 04:04:14 GMT',
        os.date("%a, %d %b %Y %H:%I:%S GMT", time))

    assert(expected ==
        cookie.build({ foo="bar" }, options))
  end)

  test('parse',function(excepted)
    assert(deepEqual({ foo="bar", bar="baz" },
        cookie.parse("foo=bar; bar=baz")))

    assert(deepEqual({ foo="bar", bar="baz" },
        cookie.parse('foo=bar; bar="baz"')))

    assert(deepEqual({ foo="bar", bar="baz" },
        cookie.parse('foo=bar; bar="baz"; foo=baz')))

    assert(deepEqual({ foo="bar", bar="baz" },
        cookie.parse('foo=bar; bar="baz"; barabaz')))
  end)
end)
