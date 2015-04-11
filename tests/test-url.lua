local url = require("url")
local deepEqual = require('deep-equal')

require('tap')(function(test)

  test('should parse url http://localhost', function(expected)
  local parsed = url.parse('http://localhost')
  local expected = {href = 'http://localhost', protocol = 'http', host = 'localhost', hostname = 'localhost', path = '/', pathname = '/'}
  assert(deepEqual(expected, parsed))
  end)

  test('should parse url http://localhost/test', function (expected)
  local parsed = url.parse('http://localhost/test')
  local expected = {href = 'http://localhost/test', protocol = 'http', host = 'localhost', hostname = 'localhost', path = '/test', pathname = '/test'}
  assert(deepEqual(expected, parsed))
  end)

  test('should parse url http://localhost.local', function (expected)
      local parsed = url.parse('http://localhost.local')
      local expected = {href = 'http://localhost.local', protocol = 'http', host = 'localhost.local', hostname = 'localhost.local', path = '/', pathname = '/'}
      assert(deepEqual(expected, parsed))
  end)

  test('should parse url http://localhost:9000', function (expected)
  local parsed = url.parse('http://localhost:9000')
  local expected = {href = 'http://localhost:9000', protocol = 'http', host = 'localhost', hostname = 'localhost', path = '/', pathname = '/', port = '9000'}
  assert(deepEqual(expected, parsed)) 
  end)

  test('should parse url http://www.creationix.com/foo/bar?this=sdr', function (expected)
  local parsed = url.parse('https://creationix.com/foo/bar?this=sdr')
  local expected = {href = 'https://creationix.com/foo/bar?this=sdr', protocol = 'https', host = 'creationix.com', hostname = 'creationix.com', path = '/foo/bar?this=sdr', pathname = '/foo/bar', search = '?this=sdr', query = 'this=sdr'}
  assert(deepEqual(expected, parsed))
  end)

  test('should parse url https://GabrielNicolasAvellaneda:s3cr3t@github.com:443/GabrielNicolasAvellaneda/luvit', function (expected)
  local parsed = url.parse('https://GabrielNicolasAvellaneda:s3cr3t@github.com:443/GabrielNicolasAvellaneda/luvit')
  local expected = {href = 'https://GabrielNicolasAvellaneda:s3cr3t@github.com:443/GabrielNicolasAvellaneda/luvit', protocol = 'https', auth = 'GabrielNicolasAvellaneda:s3cr3t', host = 'github.com', hostname = 'github.com', port = '443', path = '/GabrielNicolasAvellaneda/luvit', pathname = '/GabrielNicolasAvellaneda/luvit'}
  assert(deepEqual(expected, parsed))
  end)

  test('should parse url creationix.com/', function (expected)
  local parsed = url.parse('creationix.com/')
  local expected = {href = 'creationix.com/', path = 'creationix.com/', pathname = 'creationix.com/'}
  assert(deepEqual(expected, parsed))
  end)

  test('should parse url https://www.google.com.br/test#q=luvit', function (expected)
  local parsed = url.parse('https://www.google.com.br/test#q=luvit')
  local expected = {href = 'https://www.google.com.br/test#q=luvit', protocol = 'https', host = 'www.google.com.br', hostname = 'www.google.com.br', path = '/test', pathname = '/test', hash = '#q=luvit'}
  assert(deepEqual(expected, parsed))
  end)
end)
