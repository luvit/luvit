local los = require('los')
local spawn = require('childprocess').spawn

local count = 40
local onExitCount = count
local function createChild(k)
  local child
  local buffer = {}
  local function onExit(code)
    onExitCount = onExitCount - 1
    local data = table.concat(buffer)
    p(k, 'exit', code, 'onExitCount', onExitCount, '#data', #data, 'stdout._read_count', child.stdout._read_count)
    assert(code == 0)
    assert(#data == 2400000)
  end
  local function onData(data)
    buffer[#buffer + 1] = data
  end
  if los.type() == 'win32' then
    child = spawn('cmd.exe', {'/C', 'set'})
  else
    child = spawn('./test.sh', {})
  end
  child.stdout:on('data', onData)
  child:on('exit', onExit)
end
for k=1, count do
  p('spawning process', k)
  createChild(k)
end
