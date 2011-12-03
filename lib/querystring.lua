local QueryString = {}

function QueryString.escape(x)
  -- TODO
  return x
end

function QueryString.unscape(x)
  -- TODO
  return x
end

function QueryString.parse(query)
  local parsed = {}
  local pos = 0

  query = query:gsub("&amp;", "&")
  query = query:gsub("&lt;", "<")
  query = query:gsub("&gt;", ">")

  local function ginsert(qstr)
    local first, last = qstr:find("=")
    if first then
      parsed[qstr:sub(0, first-1)] = qstr:sub(first+1)
    end
  end

  while true do
    local first, last = query:find("&", pos)
    if first then
      ginsert(query:sub(pos, first-1));
      pos = last+1
    else
      ginsert(query:sub(pos));
      break;
    end
  end
  return parsed
end

function QueryString.stringify(obj, sep, eq)
  if not sep then sep = '&' end
  if not eq then eq = '=' end
  s = ""
  for k,v in obj do
    if not (s == "") then s = s..sep end
    s = s..eq..v
  end
  return s
end

return QueryString
