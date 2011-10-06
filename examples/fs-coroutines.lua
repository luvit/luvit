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
  local chunk, length = FS.read(co, fd, 0, 4096)
  p("on_read", {chunk=chunk, length=length})

  print("closing...")
  FS.close(co, fd)
  coroutine.yield()
  p("on_close")

end)
coroutine.resume(co, "license.txt")


