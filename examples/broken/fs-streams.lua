local fs = require('fs')

print("Reading file as stream")
local stream = fs.createReadStream(__dirname .. "/../README.markdown")

print("Adding data listener")
stream:on('data', function (chunk, len)
  p("on_data", chunk, len)
end)

print("Adding end listener")
stream:on('end', function ()
  p("on_end")
end)

print("Adding close listener")
stream:on('close', function ()
  p("on_close")
end)
