local childprocess = require('childprocess')
local utils = require('utils')
local fs = require('fs')
local string = require('string')
local table = require('table')
local path = require('path')

local results = {}
local ports = 10001

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

  process.stdout:write(utils.color("B") .. filename .. utils.color())

  ports = ports + 100

  local lenv = {}
  lenv.PORT = "" .. ports
  lenv.PATH = process.env.PATH
  local child = childprocess.spawn(process.argv[0], {filename}, {env = lenv})
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

local function run(callback)
  fs.readdir('.', function(err, files)
    assert(err == nil)
    test_files = {}

    for i, v in ipairs(files) do
      local _, _, ext = string.find(v, '^test-.*%.(.*)')
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
        callback()
        process.exit(1)
      end
    end)
  end)
end

local tmp_dir = path.join(__dirname, 'tmp')

local remove_recursive
remove_recursive = function(dir, done)
  fs.readdir(dir, function(err, files)
    if files == nil then
      done()
      return
    end

    if err then
      done(err)
      return
    end

    for i, v in ipairs(files) do
      local file = path.join(dir, v)
      fs.stat(file, function(err, stat)
        if err then
          done(err)
          return
        end

        if stat.is_directory then
          remove_recursive(file, function(err)
            fs.rmdir(file, function() end)
          end)
        elseif stat.is_file then
          fs.unlink(file, function() end)
        end
      end)
    end
    done()
  end)
end

remove_recursive(tmp_dir, function ()
  fs.mkdir(tmp_dir, "0755", function()
    run(remove_tmp)
  end)
end)
