require('helper')
local spawn = require('childprocess').spawn
local os = require('os')

local environmentTestResult = false

function test()
  local options = {
    env = { TEST1 = 1 }
  }
  local child
  if os.type() == 'win32' then
    child = spawn('cmd.exe', {'/C', 'set'}, options)
  else
    child = spawn('bash', {'-c', 'set'}, options)
  end
  child.stdout:on('data', function(chunk)
    print(chunk)
    if chunk:find('TEST1=1') then
      environmentTestResult = true
    end
  end)
end

test()

assert(process.pid ~= nil)

process:on('exit', function()
  assert(environmentTestResult == true)
end)
