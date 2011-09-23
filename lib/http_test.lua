local utils = require('lib/utils')
local http_parser = require('http_parser')
local uv = require('uv')
local mock = require('lib/mock')

print("uv", utils.dump(uv))
print("http_parser", utils.dump(http_parser))
print("utils", utils.dump(utils))
print("mock", utils.dump(mock))

local parser = http_parser.new("request", {
  on_message_begin = function ()
    print("on_message_begin")
  end,
  on_url = function (url)
    print("on_url", utils.dump(url))
  end,
  on_header_field = function (field)
    print("on_header_field", utils.dump(field))
  end,
  on_header_value = function (value)
    print("on_header_value", utils.dump(value))
  end,
  on_headers_complete = function (info)
    print("on_headers_complete", utils.dump(info))
  end,
  on_body = function (chunk)
    print("on_body", utils.dump(chunk))
  end,
  on_message_complete = function ()
    print("on_message_complete")
  end
})

print("\nParsing sample HTTP request")
local nparsed = parser:execute(mock.request, 0, #mock.request)
print("executed " .. nparsed .. " bytes")
parser:finish()

print("\nParsing sample HTTP response")
parser:reinitialize("response")
local nparsed = parser:execute(mock.response, 0, #mock.response)
print("executed " .. nparsed .. " bytes")
parser:finish()

print(dump(parser))


