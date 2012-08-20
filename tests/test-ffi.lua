local ffi = require('ffi')
local timer = require('timer')

local timeout = 20
local success = false

ffi.cdef[[ int poll(struct pollfd *fds, unsigned long nfds, int timeout); ]]

-- On the next tick the poll will have unblocked the run loop
timer.setTimeout(1, function()
  p(success)
  assert(success)
end)

if ffi.C.poll(nil, 0, timeout) then
  success = true
end
