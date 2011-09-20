print("Using uv version " .. uv.VERSION_MAJOR .. "." .. uv.VERSION_MINOR)
print(uv)

print("Using http_parser version " .. http_parser.VERSION_MAJOR .. "." .. http_parser.VERSION_MINOR)
print(http_parser)
--print(http_parser.new())
--print(http_parser.new("Hello"))
--print(http_parser.new("request"))
print(http_parser.new("request", {}))

