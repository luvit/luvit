
p(stdin)

-- Set raw mode
--UV.tty_set_mode(stdin, 1)

stdin:read_start()

stdin:set_handler('read', function (chunk)
  p("on_read", chunk)
end)

stdin:set_handler('end', function ()
  p("on_end")
  stdin:close();
end)

--UV.tty_reset_mode()


