--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

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

local Debug = require('debug')
local Utils = require('utils')
local string = require('string')
local source = Debug.getinfo(3, "S").source:sub(1)

local table_concat = require('table').concat
local expectations = {}

local fail = function(name, msg, default_msg)
  local debug_info = Debug.getinfo(3)
  local str = string.format("  %sFAIL %s - %s - Line: %i%s\n",
    Utils.color("Bred"),
    name,
    msg or default_msg,
    debug_info.currentline,
    Utils.color())
  print_stderr(str)
  exit_process(1)
end

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
    exit_process(1)
  end
  print_stderr(Utils.color("Bgreen") .. "PASS" .. Utils.color() .. "\n")
  exit_process(0)
end)

_G.equal = function(a, b)
  return a == b
end

_G.deep_equal = function(expected, actual, msg)
  if type(expected) == 'table' and type(actual) == 'table' then
    if #expected ~= #actual then return false end
    for k, v in pairs(expected) do
      if not deep_equal(v, actual[k]) then return false end
    end
    return true
  else
    local rv = equal(expected, actual)
    if not rv then
      fail("deep_equal", msg, "deep_equal failed")
    end
  end
end

local orig_assert = _G.assert
_G.assert = function(assertion, msg)
  if not assertion then
    fail("assert", msg, "assertion failed")
  end
end
