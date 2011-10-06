local FS = require('fs');

local co
co = coroutine.create(function (filename)

  print("opening...")
  local fd = FS.open(co, filename, 'r', "0644")
  p("on_open", {fd=fd})

  print("fstatting...")
  local stat = FS.fstat(co, fd)
  p("stat", {stat=stat})

  print("reading...")
  local offset = 0
  repeat
    local chunk, length = FS.read(co, fd, offset, 128)
    p("on_read", {chunk=chunk, offset=offset, length=length})
    offset = offset + length
  until length == 0

  print("closing...")
  FS.close(co, fd)
  p("on_close")

end)
coroutine.resume(co, "license.txt")


