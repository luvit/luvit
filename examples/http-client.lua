local http = require('http')

http.request({
  host = "luvit.io",
  port = 80,
  path = "/"
}, function (res)
  res:on('data', function (chunk)
    p("ondata", {chunk=chunk})
  end)
  res:on("end", function ()
    res:close()
  end)
end)
