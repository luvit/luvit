mlocal fiber = require 'fiber'

local function logic(wrap)
  -- Wrap some functions for sync-style calling
  local sleep = wrap(require('timer').setTimeout)
  -- Can wrap modules too
  local fs = wrap(require('fs'), true) -- true means to auto-handle errors

  print("opening...")
  local fd = fs.open(__filename, "r", "0644")
  p("on_open", {fd=fd})

  print("fstatting...")
  local stat = fs.fstat(fd)
  p("stat", {stat=stat})

  print("reading...")
  local offset = 0
  repeat
    local chunk, length = fs.read(fd, offset, 40)
    p("on_read", {chunk=chunk, offset=offset, length=length})
    offset = offset + length
  until length == 0

  print("pausing...")
  sleep(1000)

  print("closing...")
  fs.close(fd)
  p("on_close", {})

  return fd, stat, offset

end

print "Starting fiber."
fiber.new(logic, function (err, fd, stat, offset)
  if err then
    p("ERROR", err)
    error(err)
  else
    p("SUCCESS", { fd = fd, stat = stat, offset = offset })
  end
end)
print "started."

print "Starting another fiber."
fiber.new(function (wrap)

  local readdir = wrap(require('fs').readdir)
  print("scanning directory...")
  local err, files = readdir(".")
  p("on_open", {err=err,files=files})

end)
print "started second."


