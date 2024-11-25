local function overflow(v)
  local tbl = {}
  local i = 0
  repeat
    i = i + 1
    local a = bit.band(v, 0xff)
    tbl[i] = a
    v = bit.rshift(v, 8)
  until v == 0
  return tbl
end
return overflow
