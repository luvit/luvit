local url = require("url")
local deepEqual = require('deep-equal')

local parseTests = {
  ["http://localhost"] = {href = 'http://localhost/', protocol = 'http', host = 'localhost', hostname = 'localhost', path = '/', pathname = '/'},
  ["http://localhost/test"] = {href = 'http://localhost/test', protocol = 'http', host = 'localhost', hostname = 'localhost', path = '/test', pathname = '/test'},
  ["http://localhost.local"] = {href = 'http://localhost.local/', protocol = 'http', host = 'localhost.local', hostname = 'localhost.local', path = '/', pathname = '/'},
  ["http://localhost:9000"] = {href = 'http://localhost:9000/', protocol = 'http', host = 'localhost', hostname = 'localhost', path = '/', pathname = '/', port = '9000'},
  ["https://creationix.com/foo/bar?this=sdr"] = {href = 'https://creationix.com/foo/bar?this=sdr', protocol = 'https', host = 'creationix.com', hostname = 'creationix.com', path = '/foo/bar?this=sdr', pathname = '/foo/bar', search = '?this=sdr', query = 'this=sdr'},
  ["https://GabrielNicolasAvellaneda:s3cr3t@github.com:443/GabrielNicolasAvellaneda/luvit"] = {href = 'https://GabrielNicolasAvellaneda:s3cr3t@github.com:443/GabrielNicolasAvellaneda/luvit', protocol = 'https', auth = 'GabrielNicolasAvellaneda:s3cr3t', host = 'github.com', hostname = 'github.com', port = '443', path = '/GabrielNicolasAvellaneda/luvit', pathname = '/GabrielNicolasAvellaneda/luvit'},
  ["creationix.com/"] = {href = 'creationix.com/', path = 'creationix.com/', pathname = 'creationix.com/'},
  ["https://www.google.com.br/test#q=luvit"] = {href = 'https://www.google.com.br/test#q=luvit', protocol = 'https', host = 'www.google.com.br', hostname = 'www.google.com.br', path = '/test', pathname = '/test', hash = '#q=luvit'},
}
local parseTestsWithQueryString = {
  ["/somepath?test=bar&ponies=foo"] = { pathname = '/somepath', query = {test = 'bar', ponies = 'foo'},href='/somepath?test=bar&ponies=foo',path='/somepath?test=bar&ponies=foo',search='?test=bar&ponies=foo'},
}

require('tap')(function(test)
  for testUrl, expected in pairs(parseTests) do
    test('should parse url '..testUrl, function ()
      local parsed = url.parse(testUrl)
      assert(deepEqual(expected, parsed))

      local formatted = url.format(expected)
      assert(formatted == expected.href, formatted .. ' should equal '.. expected.href)
    end)
  end

  for testUrl, expected in pairs(parseTestsWithQueryString) do
    test('should parse url '..testUrl..' with querystring', function ()
      local parsed = url.parse(testUrl, true)
      assert(deepEqual(expected, parsed))

      local formatted = url.format(expected)
      assert(formatted == expected.href, formatted .. ' should equal '.. expected.href)
    end)
  end

  test('format should extract port from host', function()
    local parsed = url.parse("http://localhost")
    parsed.host = parsed.host .. ":9000"
    assert(not parsed.port)

    local formatted = url.format(parsed)
    assert(formatted == "http://localhost:9000/")
  end)
end)
