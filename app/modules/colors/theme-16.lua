
-- nice color theme using 16 ansi colors

return {
  property  = "0;37",
  braces    = "1;30",
  sep       = "1;30",

  ["nil"] = "1;30",
  boolean   = "0;33",
  number    = "1;33",
  string    = "0;32",
  quotes    = "1;32",
  escape    = "1;32",
  ["function"] = "0;35",
  thread    = "1;35",

  table     = "1;34",
  userdata  = "1;36",
  cdata     = "0;36",

  err       = "1;31",
  success   = "1;33;42",
  failure   = "1;33;41",
  highlight = "1;36;44",
}
