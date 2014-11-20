local miniz = require('miniz')
local uv = require('uv')
local pathJoin = require('luvi').path.join
local fs = require('fs')

-- Build a new luvi* binary given a list of zip files and/or folders.
local function build(...)
  local files = {}
  local cwd = uv.cwd()
  local args = {...}

  for i = 1, #args do
    local path = args[i]
    path = path == "self" and uv.exepath() or pathJoin(cwd, path)
    local stat = assert(uv.fs_stat(path))
    if stat.type == "FILE" then
      local reader = miniz.new_reader(path)
      print("Importing zip file: " .. path)
      for j = 1, reader:get_num_files() do
        if not reader:is_directory(j) then
          local filename = reader:get_filename(j)
          print("  " .. filename)
          files[filename] = {reader, j}
        end
      end
      print()
    elseif stat.type == "DIRECTORY" then
      print("Importing folder: " .. path)
      local function importFolder(sub)
        local fullPath = pathJoin(path, sub)
        for name, t in fs.scandirSync(fullPath) do
          local filename = pathJoin(sub, name)
          if t == 'FILE' then
            print("  " .. filename)
            files[filename] = pathJoin(fullPath, name)
          elseif t == 'DIR' then
            importFolder(filename)
          end
        end
      end
      importFolder("")
    else
      error("Not sure how to embed " .. path)
    end
  end


  -- Save the files to the zip in sorted order.
  local paths = {}
  for path in pairs(files) do
    paths[#paths + 1] = path
  end
  table.sort(paths)
  local writer = miniz.new_writer()
  for i = 1, #paths do
    local path = paths[i]
    local file = files[path]
    if type(file) == "string" then
      p("Loading", path, file)
      writer:add(path, fs.readFileSync(file), 9)
    else
      writer:add_from_zip(unpack(file))
    end
  end
  return writer:finalize()
end

print("Creating new binary `newapp`")
local fd = assert(fs.openSync("newapp", "w", 511)) -- 0777
local reader = miniz.new_reader(uv.exepath())
local binSize = reader:get_offset()
print("Copying initial " .. binSize .. " bytes from " .. uv.exepath())
local fd2 = assert(fs.openSync(uv.exepath()))
local bin = assert(fs.readSync(fd2, binSize))
fs.closeSync(fd2)
fs.writeSync(fd, bin)
print("Appending zip file")
local zip = build("self", "overlay")
fs.writeSync(fd, zip)
print("Closing")
fs.closeSync(fd)
print("Done")
