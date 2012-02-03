local fs = require('fs')
local timer = require('timer')
local Fiber = require('fiber')

Fiber:new(function (resume, wait)

  print("opening...")
  fs.open("LICENSE.txt", "r", "0644", resume)
  local err, fd = wait()
  p("on_open", {err=err,fd=fd})

  print("fstatting...")
  fs.fstat(fd, resume)
  local err, stat = wait()
  p("stat", {err=err,stat=stat})

  print("reading...")
  local offset = 0
  repeat
    fs.read(fd, offset, 72, resume)
    local err, chunk, length = wait()
    p("on_read", {err=err,chunk=chunk, offset=offset, length=length})
    offset = offset + length
  until length == 0

  print("pausing...")
  timer.setTimeout(400, resume)
  wait()

  print("closing...")
  fs.close(fd, resume)
  local err = wait()
  p("on_close", {err=err})

end)

Fiber:new(function (resume, wait)

  print("scanning directory...")
  fs.readdir(".", resume)
  local err, files = wait()
  p("on_open", {err=err,files=files})

end)


