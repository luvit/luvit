
p(tty)

-- Set raw mode
--tty:set_mode(1)

tty:read_start()

tty:set_handler('read', function (chunk)
  p("on_read", chunk)
end)

tty:set_handler('end', function ()
  p("on_end")
  tty:close()
  tty:reset_mode()
end)



