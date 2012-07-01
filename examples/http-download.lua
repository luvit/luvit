local http = require('http')

local options = {
  host = 'creationix.com',
  path = "/wordle.jpg",
  headers = {
    HOST = 'creationix.com'
  }
}
local req
req = http.request(options, function(res)
  p("on_connect", {status_code = res.statusCode, headers = res.headers})
  res:on('data', function (chunk)
    p("on_data", #chunk)
  end)
  res:on("end", function ()
    p("on_end")
    req:done()
  end)
end)

