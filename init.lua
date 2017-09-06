--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]
local uv = require('uv')

return function (main, ...)
  -- Inject the global process table
  _G.process = require('process').globalProcess()

  -- Seed Lua's RNG
  do
    local math = require('math')
    local os = require('os')
    math.randomseed(os.time())
  end

  -- Load Resolver
  do
    local dns = require('dns')
    dns.loadResolver()
  end

  -- EPIPE ignore
  do
    if jit.os ~= 'Windows' then
      local sig = uv.new_signal()
      uv.signal_start(sig, 'sigpipe')
      uv.unref(sig)
    end
  end

  local args = {...}
  local success, err = xpcall(function ()
    -- Call the main app
    main(unpack(args))

    -- Start the event loop
    uv.run()
  end, debug.traceback)

  if success then
    -- Allow actions to run at process exit.
    require('hooks'):emit('process.exit')
    uv.run()
  else
    _G.process.exitCode = -1
    require('pretty-print').stderr:write("Uncaught exception:\n" .. err .. "\n")
  end

  -- When the loop exits, close all unclosed uv handles (flushing any streams found).
  uv.walk(function (handle)
    if handle then
      local function close()
        if not handle:is_closing() then handle:close() end
      end
      if handle.shutdown then
        handle:shutdown(close)
      else
        close()
      end
    end
  end)
  uv.run()

  -- Send the exitCode to luvi to return from C's main.
  return _G.process.exitCode
end
