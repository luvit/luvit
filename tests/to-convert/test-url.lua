require('helper')

local url = require('url')

local path = '/somepath?test=bar&ponies=foo'

local parsed = url.parse(path)
assert(parsed.pathname == '/somepath')
assert(parsed.query == 'test=bar&ponies=foo')

local parsed = url.parse(path, true)
assert(parsed.pathname == '/somepath')
assert(deep_equal(parsed.query, {test = 'bar', ponies = 'foo'}))
