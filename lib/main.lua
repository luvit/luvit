print(http_parser, uv, dump)
local http_parser = require('http_parser')
local uv = require('uv')
local dump = require('lib/utils').dump
local mock = require('lib/mock')

print("uv", dump(uv))
print("http_parser", dump(http_parser))

local parser = http_parser.new("request", {
  on_message_begin = function ()
    print("on_message_begin")
  end,
  on_url = function (url)
    print("on_url", dump(url))
  end,
  on_header_field = function (field)
    print("on_header_field", dump(field))
  end,
  on_header_value = function (value)
    print("on_header_value", dump(value))
  end,
  on_headers_complete = function (info)
    print("on_headers_complete", dump(info))
  end,
  on_body = function (chunk)
    print("on_body", dump(chunk))
  end,
  on_message_complete = function ()
    print("on_message_complete")
  end
})
local nparsed = parser:execute(mock.request, 0, #mock.request)
print("executed " .. nparsed .. " bytes")
parser:finish()

parser:reinitialize("response")
local nparsed = parser:execute(mock.response, 0, #mock.response)
print("executed " .. nparsed .. " bytes")
parser:finish()


