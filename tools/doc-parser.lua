local Path = require('path')
local Table = require('table')
local FS = require('fs')
local Utils = require('utils')

local function search(code, pattern)
  local data = {}
  for pos, k, v in code:gmatch(pattern) do
    local sub = code:sub(1, pos)
    local comment = sub:match("\n-- ([^\n]+)\n$")
    if not comment then
      local long = sub:match("\n--%[(%b[])%]\n$")
      if long then
        comment = long:sub(3, #long-2)
      end
    end
    data[k] = {v, comment}
  end
  return data
end

local function parse(file)
  local code = FS.readFileSync(file)
  local name = Path.basename(file)
  name = name:sub(1, #name - #(Path.extname(name)))

  local exports = code:match("\nreturn%s+([_%a][_%w]*)")
  local variables = search(code, "()\nlocal ([_%a][_%w]*) = ([^\n]*)\n")
  local props = search(code, "()\n([_%a][_%w]*[.:][_%a][_%w]*) = ([^\n]*)\n")
  local functionNames = search(code, "()\nfunction ([_%a][_%w]*[.:][_%a][_%w]*)%(([^)]*)%)\n")

  if not exports then error("Can't find exports variable in " .. file) end

  -- calculate aliases for variable resolving
  local aliases = {}

  
  if not (name == exports) then
    aliases[exports] = name
  end
  for prop, data in pairs(props) do
    local ref = data[1]
    if ref:match("^[_%a][_%w]*$") then
      aliases[ref] = prop
    end
  end
  for ref, data in pairs(variables) do
    local prop = data[1]
    local m = prop:match("^()[_%a][_%w]*%.[_%a][_%w]*$")
    local extra
    if not m then
      m, extra = prop:match("^require(%b())(%.[_%a][_%w]*)$")
      if not m then
        m = prop:match("^require(%b())$")
      end
    end
    if m then
      if type(m) == "string" then
        aliases[ref] = m:sub(3, #m-2) .. (extra or "")
      else
        aliases[ref] = prop
      end
    end
    
  end

  local function resolve(name)
    repeat
      local before = name
      local start = name:match("^([_%a][_%w]*)")
      if start and aliases[start] then
        name = aliases[start] .. name:sub(#start + 1)
      elseif aliases[name] then 
        name = aliases[name]
      end
    until before == name
    return name
  end

  local items = {}

  for ref, def in pairs(functionNames) do
    items[resolve(ref)] = {
      doc = def[2],
      args = def[1]
    }
  end

  local function processRef(ref, def)
    local value = def[1]
    local parent = value:match("^([_%a][_%w]*):extend%(%)$")
    if parent then
      items[resolve(ref)] = {
        doc = def[2],
        parent = resolve(parent)
      }
    elseif not (value:match("^[_%a][_%w]*%.[_%a][_%w]*$") or value:match("^[_%a][_%w]*$")) then
      items[resolve(ref)] = {
        doc = def[2],
        default = not(value == "{}") and value
      }
    end
  end

  for ref, def in pairs(variables) do
    processRef(ref, def)
  end

  for prop, def in pairs(props) do
    processRef(prop, def)
  end



  local keys = {}
  for key in pairs(items) do
    if key == name or key:match("^" .. name .. "%.") then
      local item = items[key]
      if key == name or item.doc or item.args or item.parent then
        Table.insert(keys, key)
      end
    end
  end

  Table.sort(keys)

  for i, key in ipairs(keys) do
    local item = items[key]
    local title
    if key == name then
      title = "## " .. name
    else
      local short = key:match("%.(.+[.:].+)$")
      if short then
        title = "#### " .. short
      else
        title = "### " .. key
      end
    end
    if item.args then
      title = title .. "(" .. item.args .. ")"
    end
    if item.default then
      title = title .. " = " .. item.default
    end
    print(title .. "\n")
    if item.parent then
      print("Inherits from `" .. item.parent .. "`\n")
    end
    if item.doc then
      print(item.doc .. "\n")
    end
  end
  
end

parse(process.argv[1] or "shapes.lua")

