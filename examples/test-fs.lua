local uv = require('uv');

p("uv", uv)

uv.fs_open("license.txt", 'r', 420, function (fd)
  p("on_open", {fd=fd})
  uv.fs_close(fd, function ()
    p("on_close")
  end)
end)
