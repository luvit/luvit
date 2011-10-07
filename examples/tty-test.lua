local UV = require('uv')

p(stdin)

-- Set raw mode
--UV.tty_set_mode(stdin, 1)

UV.read_start(stdin)

UV.set_handler(stdin, 'read', function (chunk)
  p("on_read", chunk)
end)

UV.set_handler(stdin, 'end', function ()
  p("on_end")
  UV.read_stop(stdin);
  UV.close(stdin)
  UV.close(stdout)
  UV.close(stderr)
end)

--UV.tty_reset_mode()


