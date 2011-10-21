local user_meta = require('utils').user_meta
local TCP = require('tcp')
local Request = {}

Request.prototype = {}
setmetatable(Request.prototype, TCP.meta)

-- Don't register new event types with the userdata, this should be a plain lua emitter
function Request.prototype.add_handler_type() end

function Request.new(client)
  local request = {
    userdata = client.userdata,
    prototype = Request.prototype,
  }
  setmetatable(request, user_meta)
  return request
end

return Request
