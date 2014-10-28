local env = require('env')

local testv_name = 'TEST_VARIABLE'
local testv_value = 'Test Value'


env.set(testv_name, testv_value, 1)
assert(testv_value == env.get(testv_name))
