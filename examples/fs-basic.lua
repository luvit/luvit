local FS = require('fs');

FS.open("license.txt", 'r', "0644", function (err, fd)
  p("on_open", {err=err,fd=fd})
  if (err) then return end
  FS.read(fd, 0, 4096, function (err, chunk)
    p("on_read", {err=err,chunk=chunk,length=#chunk})
    if (err) then return end
    FS.close(fd, function (err)
      p("on_close", {err=err})
      if (err) then return end
    end)
  end)
end)

FS.mkdir("temp", "0755", function (err)
  p("on_mkdir", {err=err})
  if (err) then return end
  FS.rmdir("temp", function (err)
    p("on_rmdir", {err=err})
    if (err) then return end
  end)
end)

FS.open("tempfile", "w", "0644", function (err, fd)
  p("on_open2", {err=err,fd=fd})
  if (err) then return end
  FS.write(fd, 0, "Hello World\n", function (err, bytes_written)
    p("on_write", {err=err,bytes_written=bytes_written})
    if (err) then return end
    FS.close(fd, function (err)
      p("on_close2", {err=err})
      if (err) then return end
      FS.unlink("tempfile", function (err)
        p("on_unlink", {err=err})
        if (err) then return end
      end)
    end)
  end)
end)

FS.readdir(".", function (err, files)
  p("on_readdir", {err=err,files=files})
end)
