local Process = require('process')
local utils = require('utils')
local fs = require('fs')
local string = require('string')
local table = require('table')

local results = {}

local async = {}
async.forEachSeries = function(arr, iterator, callback)
  if #arr == 0 then
    return callback()
  end
  local completed = 0
  local iterate
  iterate = function()
    iterator(arr[completed + 1], function(err)
      if err then
        callback(err)
        callback = function() end
      else
        completed = completed + 1
        if completed == #arr then
          callback()
        else
          iterate()
        end
      end
    end)
  end
  iterate()
end

local function runTest(filename, callback)
  results[filename] = {}
  results[filename].stdout_data = ''
  results[filename].stderr_data = ''
  results[filename].filename = filename

  process.stdout:write(utils.color("Bwhite") .. filename .. utils.color())

  local child = Process:spawn(process.argv[0], {filename}, {})
  child:on('exit', function (exit_status, term_signal)
    results[filename].exit_status = exit_status
    if exit_status ~= 0 then
      process.stdout:write(' ' .. utils.color("Bred") .. 'FAILED' .. utils.color() .. '\n')
    else
      process.stdout:write(' ' .. utils.color("Bgreen") .. 'SUCCESS' .. utils.color() .. '\n')
    end
    callback()
  end)
  child.stdout:on("data", function (chunk)
    results[filename].stdout_data = results[filename].stdout_data .. chunk
  end)
  child.stderr:on("data", function (chunk)
    results[filename].stderr_data = results[filename].stderr_data .. chunk
  end)
end

fs.readdir('.', function(err, files)
  assert(err == nil)
  test_files = {}

  for i, v in ipairs(files) do
    local _, _, ext = string.find(v, 'test-.*%.(.*)') 
    if ext == 'lua' then
      table.insert(test_files, v)
    end
  end

  async.forEachSeries(test_files, runTest, function()
    local nerr = 0;
    local nran = 0;

    for k, v in pairs(results) do
      nran = nran + 1
      if v.exit_status ~= 0 then
        nerr = nerr + 1
        process.stdout:write('\n\n')
        process.stdout:write(utils.color("Bred") .. "FAIL (" .. v.filename .. ')' .. utils.color() .. "\n")
        process.stdout:write(v.stdout_data)
        process.stdout:write(v.stderr_data)
      end
    end
    process.stdout:write('Done\n')
    if nerr ~= 0 then
      process.exit(1)
    end
  end)
end)

