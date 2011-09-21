print("uv", uv, "version " .. uv.VERSION_MAJOR .. "." .. uv.VERSION_MINOR)
print("http_parser", http_parser, "version " .. http_parser.VERSION_MAJOR .. "." .. http_parser.VERSION_MINOR)

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      s = s .. dump(k) ..' = ' .. dump(v) .. ', '
    end
    return s .. '} '
  elseif type(o) == 'string' then
    return ('"' .. o:gsub("\n","\\n"):gsub("\r","\\r") .. '"')
  else
    return tostring(o)
  end
end


local request = ([[
POST /documentation/apache/ HTTP/1.0
Connection: Keep-Alive
User-Agent: Mozilla/4.01 [en] (Win95; I)
Host: hal.etc.com.au
Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, */*
Accept-Language: en
Accept-Charset: iso-8859-1,*,utf-8
Content-Length: 13

Hello World
]]):gsub("\n","\r\n")


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
parser:reinitialize("request")
local nparsed = parser:execute(request, 0, #request)
print("executed " .. nparsed .. " bytes")
parser:finish()



--local parser = http_parser.new("request", {})
--print(parser)
--print(parser:execute("Hello", 4, 1))
--parser.execute()
--print(http_parser.new())
--print(http_parser.new("Hello"))
--print(http_parser.new("request"))
--print(http_parser.new("REQUEST", {}))
--print(http_parser.new("request", {}))


--local HTTPParser = require('http_parser')

