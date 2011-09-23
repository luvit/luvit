local dump = require('lib/utils').dump
function p(...)
  local l = ""
  for i, v in ipairs{...} do
    if (i > 1) then
      l = l .. "\t" .. dump(v)
    else
      l = l .. dump(v)
    end
  end
  print(l)
end



