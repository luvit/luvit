local UV = require('uv')

local stdin = UV.new_tty(0)
p(stdin)

-- Set raw mode
--UV.tty_set_mode(stdin, 1)

UV.read_start(stdin)

UV.set_handler(stdin, 'read', function (chunk)
  p("on_read", chunk)
end)

UV.set_handler(stdin, 'end', function ()
  p("on_end")
  UV.close(stdin)
end)

--UV.tty_reset_mode()


