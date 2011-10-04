function p(first, ...)
  local dump = require('utils').dump
  local l = dump(first)
  for i, v in ipairs{...} do
    l = l .. "\t" .. dump(v)
  end
  print(l)
end

if not process.argv[1] then
  print("usage:\n\t" .. process.argv[0] .. " progname.lua\n")
  return;
end

dofile(process.argv[1])

require('uv').run()

