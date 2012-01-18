local utils = require('utils')
require('helper')

local BindHelper = {}
utils.inherits(BindHelper, {})

function BindHelper.prototype:func1(arg1, callback)
  assert(self ~= nil)
  callback(arg1)
end

function BindHelper.prototype:func2(arg1, arg2, callback)
  assert(self ~= nil)
  callback(arg1, arg2)
end

function BindHelper.prototype:func3(arg1, arg2, arg3, callback)
  assert(self ~= nil)
  callback(arg1, arg2, arg3)
end

local testObj = BindHelper.new_obj()
local bound

bound = utils.bind(BindHelper.prototype.func1, testObj)
bound('hello world', function(arg1)
  assert(arg1 == 'hello world')
end)
bound('hello world1', function(arg1)
  assert(arg1 == 'hello world1')
end)

bound = utils.bind(BindHelper.prototype.func1, testObj, 'hello world')
bound(function(arg1)
  assert(arg1 == 'hello world')
end)
bound(function(arg1)
  assert(arg1 == 'hello world')
end)
bound(function(arg1)
  assert(arg1 == 'hello world')
end)

bound = utils.bind(BindHelper.prototype.func2, testObj)
bound('hello', 'world', function(arg1, arg2)
  assert(arg1 == 'hello')
  assert(arg2 == 'world')
end)
bound('hello', 'world', function(arg1, arg2)
  assert(arg1 == 'hello')
  assert(arg2 == 'world')
end)

bound = utils.bind(BindHelper.prototype.func2, testObj, 'hello')
bound('world', function(arg1, arg2)
  assert(arg1 == 'hello')
  assert(arg2 == 'world')
end)

bound = utils.bind(BindHelper.prototype.func3, testObj)
bound('hello', 'world', '!', function(arg1, arg2, arg3)
  assert(arg1 == 'hello')
  assert(arg2 == 'world')
  assert(arg3 == '!')
end)

bound = utils.bind(BindHelper.prototype.func3, testObj, 'hello', 'world')
bound('!', function(arg1, arg2, arg3)
  assert(arg1 == 'hello')
  assert(arg2 == 'world')
  assert(arg3 == '!')
end)
