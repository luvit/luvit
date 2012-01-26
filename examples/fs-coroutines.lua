local FS = require('fs');
local Timer = require('timer');
local Fiber = require('fiber')

Fiber:new(function (resume, wait)

  print("opening...")
  FS.open("LICENSE.txt", "r", "0644", resume)
  local err, fd = wait()
  p("on_open", {err=err,fd=fd})

  print("fstatting...")
  FS.fstat(fd, resume)
  local err, stat = wait()
  p("stat", {err=err,stat=stat})

  print("reading...")
  local offset = 0
  repeat
    FS.read(fd, offset, 72, resume)
    local err, chunk, length = wait()
    p("on_read", {err=err,chunk=chunk, offset=offset, length=length})
    offset = offset + length
  until length == 0

  print("pausing...")
  Timer:set_timeout(400, resume)
  wait()

  print("closing...")
  FS.close(fd, resume)
  local err = wait()
  p("on_close", {err=err})

end)

Fiber:new(function (resume, wait)

  print("scanning directory...")
  FS.readdir(".", resume)
  local err, files = wait()
  p("on_open", {err=err,files=files})

end)


