require('helper')

local path = require('path')
local spawn = require('childprocess').spawn

local os = require('os')

local childPath = path.join(__dirname, 'fixtures', 'parent-process-nonpersistent.lua')
local persistentPid = -1

if os.type() == 'win32' then
  return
end

local child = spawn(process.execPath, { childPath })
child.stdout:on('data', function(data)
  persistentPid = tonumber(data)
end)

process:on('exit', function()
  assert(persistentPid ~= -1)
  local err = pcall(function()
    process.kill(child.pid)
  end)
  process.kill(persistentPid)
end)
