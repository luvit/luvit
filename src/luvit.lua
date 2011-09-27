function p(first, ...)
  local dump = require('lib/utils').dump
  local l = dump(first)
  for i, v in ipairs{...} do
    l = l .. "\t" .. dump(v)
  end
  print(l)
end


require('examples/http_server')
--require('examples/tcp_test')

require('uv').run()

