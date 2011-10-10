local user_meta = require('utils').user_meta
local TCP = require('tcp')
local Request = {}

Request.prototype = {}
setmetatable(Request.prototype, TCP.meta)

function Request.new(client)
  local request = {
    userdata = client.userdata,
    prototype = Request.prototype,
  }
  setmetatable(request, user_meta)
  return request
end

return Request
