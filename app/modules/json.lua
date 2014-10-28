local ffi = require('ffi')

local function null_tostring()
  return "null"
end

local function null_index()
  error "Attempt to index null"
end

local jsonNull = setmetatable({}, {
  __tostring = null_tostring,
  __index = null_index,
  __newindex = null_index,
  __pairs = null_index,
})

local function fail(json, offset)
  local index = offset + 1
  local i = index
  while string.sub(json, i, i) ~= "\n" and i > 1 do
    i = i - 1
  end
  local j = index
  while string.sub(json, j, j) ~= "\n" and j < #json do
    j = j + 1
  end

  return "JSON Syntax Error:\n" .. string.sub(json, i, j) .. "\n" .. string.rep(" ", index - i) .. "^"
end

local function parse(json, keepNull)
  -- Choose between real nil and fake null
  local null = keepNull and jsonNull or nil

  -- Copy to ffi buffer for faster access
  local length = #json
  local buffer = ffi.new("char[?]", length)
  ffi.copy(buffer, json)

  -- Setup the state-machine
  local state = "value"
  local value

  local i = 0
  while i < length do
    if state == 'value' then
      if value then
        error(fail(json, i))
      end
      if buffer[i] == 0x6e then       -- `n`
        if buffer[i + 1] == 0x75 and  -- `u`
           buffer[i + 2] == 0x6c and  -- `l`
           buffer[i + 3] == 0x6c then -- `l`
          value = null
          i = i + 4
        else
          error(fail(json, i))
        end
      elseif buffer[i] == 0x2d or   -- `-`
            (buffer[i] >= 0x30 and  -- `0` to
             buffer[i] <  0x40) then -- `9`

        local start = i
        local decimal = false

        -- Check optional leading minus
        if buffer[i] == 0x2d then -- `-`
          i = i + 1
        end

        -- Check the integer half of the number
        if buffer[i] == 0x30 then -- `0`
          i = i + 1
          if buffer[i] == 0x2e then -- `.`
            i = i + 1
            decimal = true
          end
        elseif buffer[i] > 0x30 and  -- `1` to
               buffer[i] < 0x40 then -- `9`
          i = i + 1
          while buffer[i] >= 0x30 and -- `0` to
                buffer[i] <  0x40 do  -- `9`
            i = i + 1
          end
          if buffer[i] == 0x2e then -- `.`
            i = i + 1
            decimal = true
          end
        else
          error(fail(json, start))
        end

        -- If there was a decimal, consume the one or more digits
        if decimal then
          if buffer[i] >= 0x30 and -- `0` to
             buffer[i] < 0x40 then -- `9`
            i = i + 1
            while buffer[i] >= 0x30 and -- `0` to
                  buffer[i] <  0x40 do  -- `9`
              i = i + 1
            end
          else
            error(fail(json, start))
          end
        end

        -- Check for optional scientific notation
        if buffer[i] == 0x45 or   -- `E`
           buffer[i] == 0x65 then -- `e`
          i = i + 1
          if buffer[i] == 0x2b or   -- `+`
             buffer[i] == 0x2d then -- `-`
            i = i + 1
          end
          if buffer[i] >= 0x30 and -- `0` to
             buffer[i] < 0x40 then -- `9`
            i = i + 1
            while buffer[i] >= 0x30 and -- `0` to
                  buffer[i] <  0x40 do  -- `9`
              i = i + 1
            end
          else
            error(fail(json, start))
          end
        end

        value = tonumber(ffi.string(buffer + start, i - start))

      elseif buffer[i] == 0x5b then -- `[`
        value = {}
        state = 'array'
        i = i + 1
      elseif buffer[i] == 0x7b then -- `{`
        value = {}
        state = 'object'
        i = i + 1
      else
        error "TODO: implement more parsers"
      end
    elseif state == 'array' then
      error "TODO: implement array parser"
    end
  end


  return value
end

local function stringify(value)
  error "TODO: Implement JSON.stringify"
end

exports.null = jsonNull
exports.parse = parse
exports.stringify = stringify
