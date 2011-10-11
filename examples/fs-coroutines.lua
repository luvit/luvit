local FS = require('fs');
local Fiber = require('fiber')
local open = Fiber.wrap(FS.open, 3)
local fstat = Fiber.wrap(FS.fstat, 1)
local read = Fiber.wrap(FS.read, 3)
local close = Fiber.wrap(FS.close, 1)
local readdir = Fiber.wrap(FS.readdir, 1)


Fiber.new(function (co)

  print("opening...")
  local err, fd = open(co, "license.txt", "r", "0644")
  p("on_open", {err=err, fd=fd})
  if (err) then return end

  print("fstatting...")
  local err, stat = fstat(co, fd)
  p("stat", {err=err, stat=stat})
  if (err) then return end

  print("reading...")
  local offset = 0
  repeat
    local err, chunk = read(co, fd, offset, 128)
    local length = #chunk
    p("on_read", {err=err, chunk=chunk, offset=offset, length=length})
    if (err) then return end
    offset = offset + length
  until length == 0

  print("closing...")
  local err = close(co, fd)
  p("on_close", {err=err})
  if (err) then return end

end)

Fiber.new(function (co)

  print("scanning directory...")
  local err, files = readdir(co, ".")
  p("on_open", {err=err, files=files})
  if (err) then return end

end)


