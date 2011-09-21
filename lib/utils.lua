function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      s = s .. '[' .. dump(k) ..'] = ' .. dump(v) .. ', '
    end
    return s .. '} '
  elseif type(o) == 'string' then
    return ('"' .. o:gsub("\n","\\n"):gsub("\r","\\r") .. '"')
  else
    return tostring(o)
  end
end

return {
  dump = dump
}
