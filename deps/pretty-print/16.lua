
-- nice color theme using 16 ansi colors

return {
  property     = "0;37", -- white
  sep          = "1;30", -- bright-black
  braces       = "1;30", -- bright-black

  ["nil"]      = "1;30", -- bright-black
  boolean      = "0;33", -- yellow
  number       = "1;33", -- bright-yellow
  string       = "0;32", -- green
  quotes       = "1;32", -- bright-green
  escape       = "1;32", -- bright-green
  ["function"] = "0;35", -- purple
  thread       = "1;35", -- bright-purple

  table        = "1;34", -- bright blue
  userdata     = "1;36", -- bright cyan
  cdata        = "0;36", -- cyan

  err          = "1;31", -- bright red
  success      = "1;33;42", -- bright-yellow on green
  failure      = "1;33;41", -- bright-yellow on red
  highlight    = "1;36;44", -- bright-cyan on blue
}
