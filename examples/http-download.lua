local HTTP = require('http')

local CREATIONIX_COM = "72.14.187.119"
HTTP.request({
  host = CREATIONIX_COM,
  path = "/wordle.jpg",
  headers = {
    HOST = "creationix.com"
  }
}, function (res)
  p("on_connect", {status_code = res.status_code, headers = res.headers})
  res:on('data', function (chunk)
    p("on_data", #chunk)
  end)
  res:on("end", function ()
    p("on_end")
    res:close()
  end)
end)
