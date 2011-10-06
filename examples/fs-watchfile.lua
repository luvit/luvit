local UV = require('uv')

local watcher = UV.new_fs_watcher(".")
watcher:set_handler("change", function (status, event, path)
  p("on_change", {status=status,event=event,path=path})
end);

p(watcher)
