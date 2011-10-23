local Debug = require('debug')
debug(Debug.getinfo(3, "S").source)

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
      errors[#errors + 1] = "\n\tExpectation " .. name .. " was never fulfilled"
    end
  end
  if #errors > 0 then
    error("Failed Expectations:" .. table_concat(errors, ""))
  end
end)
    

