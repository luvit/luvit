local UV = require('uv')
local Table = require('table')
local Fibers = require('fibers')

local CHUNK_SIZE = 4096

local function read_file(path, callback)
  UV.fs_open(path, "r", "0666", function (err, fd)
    if err then return callback(err) end
    local parts = {}
    local offset = 0
    local index = 1
    local function readchunk()
      UV.fs_read(fd, offset, CHUNK_SIZE, function (err, chunk)
        if err then return callback(err) end
        if #chunk == 0 then
          UV.fs_close(fd, function (err)
            if err then return callback(err) end
            return callback(nil, Table.concat(parts, ""))
          end)
        else
          parts[index] = chunk
          index = index + 1
          offset = offset + #chunk
          readchunk()
        end
      end)
    end
    readchunk()
  end)
end

local function write_file(path, data, callback)
  UV.fs_open(path, "w", "0666", function (err, fd)
    if err then return callback(err) end
    local offset = 0
    local length = #data
    local function writechunk()
      UV.fs_write(fd, offset, data:sub(offset + 1, CHUNK_SIZE + offset), function (err, bytes_written)
        if err then return callback(err) end
        if bytes_written + offset < length then
          offset = offset + bytes_written
          writechunk()
        else
          UV.fs_close(fd, callback)
        end
      end)
    end
    writechunk()
  end)
end

return {
  read_file = Fibers.wrap(read_file, 1),
  write_file = Fibers.wrap(write_file, 2),
  open = Fibers.wrap(UV.fs_open, 3),
  close = Fibers.wrap(UV.fs_close, 1),
  read = Fibers.wrap(UV.fs_read, 3),
  write = Fibers.wrap(UV.fs_write, 3),
  unlink = Fibers.wrap(UV.fs_unlink, 1),
  mkdir = Fibers.wrap(UV.fs_mkdir, 2),
  rmdir = Fibers.wrap(UV.fs_rmdir, 1),
  readdir = Fibers.wrap(UV.fs_readdir, 1),
  stat = Fibers.wrap(UV.fs_stat, 1),
  fstat = Fibers.wrap(UV.fs_fstat, 1),
  rename = Fibers.wrap(UV.fs_rename, 2),
  fsync = Fibers.wrap(UV.fs_fsync, 1),
  fdatasync = Fibers.wrap(UV.fs_fdatasync, 1),
  ftruncate = Fibers.wrap(UV.fs_ftruncate, 2),
  sendfile = Fibers.wrap(UV.fs_sendfile, 4),
  chmod = Fibers.wrap(UV.fs_chmod, 2),
  utime = Fibers.wrap(UV.fs_utime, 3),
  futime = Fibers.wrap(UV.fs_futime, 3),
  lstat = Fibers.wrap(UV.fs_lstat, 1),
  link = Fibers.wrap(UV.fs_link, 2),
  symlink = Fibers.wrap(UV.fs_symlink, 3),
  readlink = Fibers.wrap(UV.fs_readlink, 1),
  fchmod = Fibers.wrap(UV.fs_fchmod, 2),
  chown = Fibers.wrap(UV.fs_chown, 3),
  fchown = Fibers.wrap(UV.fs_fchown, 3),
}

