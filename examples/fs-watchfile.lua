local UV = require('uv')

local watcher = UV.new_fs_watcher(".")
watcher:set_handler("change", function (event, path)
  p("on_change", {event=event,path=path})
end);

p(watcher)
