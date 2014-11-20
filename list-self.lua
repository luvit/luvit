local miniz = require('miniz')
local uv = require('uv')
local pathJoin = require('luvi').path.join

local reader = miniz.new_reader(uv.exepath())
for i = 1, reader:get_num_files() do
  local path = reader:get_filename(i)
  print(path)
end

-- Build a new luvi* binary given a list of zip files and/or folders.
local function build(...)
  local files = {}
  local cwd = uv.cwd()
  local args = {...}

  for i = 1, #args do
    local path = pathJoin(cwd, args[i])
    local stat = assert(uv.fs_stat(path))
    if stat.type == "FILE" then
      local reader = miniz.new_reader(path)
      print("Importing zip file: " .. path)
      for j = 1, reader:get_num_files() do
        if not reader:is_directory(j) then
          local filename = reader:get_filename(j)
          print("  " .. filename)
          files[filename] = reader:extract(j)
        end
      end
      print()
    elseif stat.type == "DIRECTORY" then
      local function importFolder(path)
        local req = uv.fs_scandir(path)
        local function getNext()
          return uv.fs_scandir_next(req)
        end
        for path in  do
          print(path)
        end
      end
      p(path, "FOLDER")
      importFolder(path)
    else
      error("Not sure how to embed " .. path)
    end
  endgit
  return files
end

build(uv.exepath(), "app")
