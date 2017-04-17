exports.name = "luvit/mail"
exports.version = "0.0.1"
exports.dependencies = {}
exports.license = "Apache 2"
exports.homepage = "https://github.com/zhaozg/luvit/blob/master/deps/mail"
exports.description = "mailmodule for luvit."
exports.tags = {"luvit", "mail"}

local smtp = require('./smtp')
exports.smtp = smtp

exports.send = function(mailt,callback)
  local client = smtp:new()
  client:open(mailt.port or 25, mailt.server or '127.0.0.1', function()
    if type(mailt.message)=='table' then
      mailt.source = mailt.source or smtp.message(mailt.message)
    end
    client:send(mailt)
  end)
  client:on('done',callback)
  client:on('error',function(err,module)
    callback(err,module)
  end)
end
