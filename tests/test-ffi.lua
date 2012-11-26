local ffi = require('ffi')
local timer = require('timer')
local os = require('os')

local is_windows = os.type() == 'win32'
local timeout = 20
local success = false

if is_windows then
  -- approximated the call signature DWORDs are unsinged ints and BOOLs are ints
  ffi.cdef[[ unsigned int  SleepEx(unsigned int dwMilliseconds, int bAlertable); ]]
else
  ffi.cdef[[ int poll(struct pollfd *fds, unsigned long nfds, int timeout); ]]
end

-- On the next tick the poll will have unblocked the run loop
timer.setTimeout(1, function()
  p(success)
  assert(success)
end)

if is_windows then
  if ffi.C.SleepEx(timeout, 0) then
    success = true
  end
else
  if ffi.C.poll(nil, 0, timeout) then
    success = true
  end
end