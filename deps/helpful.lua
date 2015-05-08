--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

exports.name = "luvit/helpful"
exports.version = "1.0.0-1"
exports.license = "Apache 2"
exports.homepage = "https://github.com/luvit/luvit/blob/master/deps/helpful.lua"
exports.description = "Levenshtein distance for property-not-found hints in modules."
exports.tags = {"levenshtein", "string"}

function string.levenshtein(str1, str2)
  local len1 = string.len(str1)
  local len2 = string.len(str2)
  local matrix = {}
  local cost
  -- quick cut-offs to save time
  if (len1 == 0) then
    return len2
  elseif (len2 == 0) then
    return len1
  elseif (str1 == str2) then
    return 0
  end
    -- initialise the base matrix values
  for i = 0, len1, 1 do
    matrix[i] = {}
    matrix[i][0] = i
  end
  for j = 0, len2, 1 do
    matrix[0][j] = j
  end
    -- actual Levenshtein algorithm
  for i = 1, len1, 1 do
    for j = 1, len2, 1 do
      if (str1:byte(i) == str2:byte(j)) then
        cost = 0
      else
        cost = 1
      end
      matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
    end
  end
  -- return the last value - this is the Levenshtein distance
  return matrix[len1][len2]
end

function string.luvitGlobalExtend()
  getmetatable("").__mod = function(self, values) return self:format(unpack(values)) end
end

local colorize = require('utils').colorize

return function (prefix, mod)
  mod = mod or require(prefix)
  return setmetatable(mod, {
    __index = function (table, wanted)
      if type(wanted) ~= "string" then return end
      local closest = math.huge
      local name = nil
      for key in pairs(table) do
        local distance = string.levenshtein(key, wanted)
        if distance < closest then
          closest = distance
          name = key
        end
      end
      print("Warning: " .. colorize("failure", prefix .. "." .. wanted) .. " is nil, did you mean " .. colorize("success", prefix .. "." .. name) .. "?")
    end
  })
end
