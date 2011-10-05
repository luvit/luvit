local uv = require('uv');

p("uv", uv)

uv.fs_open("license.txt", 'r', 420, function (fd)
  p("on_open", {fd=fd})
  uv.fs_read(fd, 0, 4096, function (chunk, length)
    p("on_read", chunk, length)
    uv.fs_close(fd, function (chunk, length)
      p("on_close")
    end)
  end)
end)
