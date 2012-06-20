local fmt = require('string').fmt
local http = require('http')
local tls = require('tls')

function createConnection(...)
  local args = {...}
  local options = {}
  local callback
  if type(args[1]) == 'table' then
    options = args[1]
  elseif type(args[2]) == 'table' then
    options = args[2]
    options.port = args[1]
  elseif type(args[3]) == 'table' then
    options = args[3]
    options.port = args[2]
    options.host = args[1]
  else
    if type(args[1]) == 'number' then
      options.port = args[1]
    end
    if type(args[2]) == 'string' then
      options.host = args[2]
    end
  end

  if type(args[#args]) == 'function' then
    callback = args[#args]
  end

  return tls.connect(options, callback)
end

function request(options, callback)
  if options.protocol and options.protocol ~= 'https:' then
    error(fmt('Protocol %s not supported', options.protocol))
  end
  options.createConnection = createConnection
  options.port = options.port or 443
  return http.request(options, callback)
end

local https = {}
https.request = request
return https
