local Watcher = require('uv').Watcher

local watcher = Watcher:new('.')
watcher:on("change", function (event, path)
  p("on_change", {event=event,path=path})
end);

p(watcher)
