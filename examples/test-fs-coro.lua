local uv = require('uv');

local co
co = coroutine.create(function (filename)

  print("opening...")
  uv.fs_open(filename, 'r', "0644", resume)
  p("yielding", co, coroutine.status(co))
  local fd = coroutine.yield()
  p("on_open", {fd=fd})

  print("reading...")
  uv.fs_read(fd, 0, 4096, resume)
  p("yielding", co, coroutine.status(co))
  local chunk, length = coroutine.yield()
  p("on_read", {chunk=chunk, length=length})

  print("closing...")
  uv.fs_close(fd, resume)
  p("yielding", co, coroutine.status(co))
  coroutine.yield()
  p("on_close")

end)

function resume(...)
  p("Resuming1...", co, coroutine.status(co), ...)
  p("result", coroutine.resume(co, ...))
  p("After...", co, coroutine.status(co), ...)
end

resume("license.txt")

