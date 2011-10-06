local uv = require('uv');

local co = coroutine.create(function (filename) 
  
  uv.fs_open(filename, 'r', "0644", resume)
  local fd = coroutine.yield()
  p("on_open", {fd=fd})

  uv.fs_read(fd, 0, 4096, resume)
  local chunk, length = coroutine.yield()
  p("on_read", {chunk=chunk, length=length})
  
  uv.fs_close(fd, resume)
  coroutine.yield()
  p("on_close")

end)

function resume(...)
  p("Resuming...", co, ...)
  p(coroutine.resume(co, ...))
end

resume("license.txt")

