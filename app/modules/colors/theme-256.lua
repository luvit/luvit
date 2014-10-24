
-- nice color theme using ansi 256-mode colors

return {
  property  = "38;5;253",
  braces    = "38;5;247",
  sep       = "38;5;240",

  undefined = "38;5;244",
  boolean   = "38;5;220", -- yellow-orange
  number    = "38;5;202", -- orange
  string    = "38;5;40",  -- green
  quotes    = "38;5;34",  -- darker green
  escape    = "38;5;46",  -- bright green
  func      = "38;5;129", -- purple
  cfunction = "38;5;161", -- purple-red
  thread    = "38;5;199", -- pink

  regexp    = "38;5;214", -- yellow-orange
  date      = "38;5;153", -- blue-purple

  null      = "38;5;27",  -- dark blue
  object    = "38;5;27",  -- blue
  buffer    = "38;5;39",  -- blue2
  dbuffer   = "38;5;69",  -- teal
  pointer   = "38;5;124", -- red

  err       = "38;5;196", -- bright red
  success   = "38;5;120;48;5;22",  -- bright green
  failure   = "38;5;215;48;5;52",  -- bright green
  highlight = "38;5;45;48;5;236",  -- bright teal with grey background
}
