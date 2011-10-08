local FS = require('fs');
local Fibers = require('fibers')

Fibers.new(function (co)

  print("opening...")
  local err, fd = FS.open(co, "license.txt", "r", "0644")
  p("on_open", {err=err, fd=fd})
  if (err) then return end

  print("fstatting...")
  local err, stat = FS.fstat(co, fd)
  p("stat", {err=err, stat=stat})
  if (err) then return end

  print("reading...")
  local offset = 0
  repeat
    local err, chunk = FS.read(co, fd, offset, 128)
    local length = #chunk
    p("on_read", {err=err, chunk=chunk, offset=offset, length=length})
    if (err) then return end
    offset = offset + length
  until length == 0

  print("closing...")
  local err = FS.close(co, fd)
  p("on_close", {err=err})
  if (err) then return end

end)

Fibers.new(function (co)

  print("scanning directory...")
  local err, files = FS.readdir(co, ".")
  p("on_open", {err=err, files=files})
  if (err) then return end

end)


