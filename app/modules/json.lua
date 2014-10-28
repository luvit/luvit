
local function null_tostring()
  return "null"
end

local function null_index()
  error "Attempt to index null"
end

local null = setmetatable({}, {
  __tostring = null_tostring,
  __index = null_index,
  __newindex = null_index,
  __pairs = null_index,
})

local function parse(json)
  error "TODO: Implement JSON.parse"
end

local function stringify(value)
  error "TODO: Implement JSON.stringify"
end

exports.null = null
exports.parse = parse
exports.stringify = stringify
