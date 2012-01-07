local HTTP = require('http')

local DOMAIN = "creationix.com"
HTTP.request({
  host = DOMAIN ,
  path = "/wordle.jpg",
  headers = {
    HOST = DOMAIN
  }
}, function (err, res)
  p("on_connect", {status_code = res.status_code, headers = res.headers})
  res:on('data', function (chunk)
    p("on_data", #chunk)
  end)
  res:on("end", function ()
    p("on_end")
    res:close()
  end)
end)
