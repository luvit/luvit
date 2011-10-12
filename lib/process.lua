local UV = require('uv')
local user_meta = require('utils').user_meta
local emitter_meta = require('emitter').meta
local Pipe = require('pipe')
local Process = {}

local process_prototype = {}
setmetatable(process_prototype, emitter_meta)
Process.prototype = process_prototype

function Process.spawn(command, args, options)
  local stdin = Pipe.new(0)
  local stdout = Pipe.new(0)
  local stderr = Pipe.new(0)
  
  local process = {
    userdata = UV.spawn(stdin, stdout, stderr, command, args, options),
    prototype = process_prototype,
    stdin = stdin,
    stdout = stdout,
    stderr = stderr
  }
  setmetatable(process, user_meta)
  process.stdout:read_start()
  process.stderr:read_start()
  process.stdout:on('end', function ()
    process.stdout:close()
  end)
  process.stderr:on('end', function ()
    process.stderr:close()
  end)
  process:on('exit', function ()
    process.stdin:close()
    process:close()
  end)

  return process
end

return Process

