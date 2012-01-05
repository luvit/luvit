local Debug = require('debug')
local Utils = require('utils')
local source = Debug.getinfo(3, "S").source:sub(2)
print_stderr("Running " .. Utils.color("Bblue") .. source .. Utils.color() .. "... ")

local table_concat = require('table').concat
local expectations = {}

function _G.expect(name)
  if expectations[name] then 
    error("Expectation " .. name .. " already registered!")
  end
  expectations[name] = true
end

function _G.fulfill(name)
  if expectations[name] == false then 
    error("Expectation " .. name .. " already fulfilled!")
  elseif expectations[name] == nil then
    error("Expectation " .. name .. " was never registered!")
  end
  expectations[name] = false
end

process:on('exit', function (code, signal)
  local errors = {}
  for name, value in pairs(expectations) do
    if value then
      errors[#errors + 1] = "\n\tExpectation '" .. name .. "' was never fulfilled." 
    end
  end
  if #errors > 0 then
    print_stderr(Utils.color("Bred") .. "FAIL" .. Utils.color() .. "\n")

    error("\n" .. source .. ":on_exit:" .. table_concat(errors, ""))
  end
  print_stderr(Utils.color("Bgreen") .. "PASS" .. Utils.color() .. "\n")

end)

_G.equal = function(a, b)
  return a == b
end

_G.deep_equal = function(expected, actual)
  if type(expected) == 'table' and type(actual) == 'table' then
    if #expected ~= #actual then return false end
    for k, v in pairs(expected) do
      if not deep_equal(v, actual[k]) then return false end
    end
    return true
  else
    return equal(expected, actual)
  end
end
