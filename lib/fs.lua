local UV = require('uv')
local Table = require('table')

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
  read_file = read_file,
  write_file = write_file,
  open = UV.fs_open,
  close = UV.fs_close,
  read = UV.fs_read,
  write = UV.fs_write,
  unlink = UV.fs_unlink,
  mkdir = UV.fs_mkdir,
  rmdir = UV.fs_rmdir,
  readdir = UV.fs_readdir,
  stat = UV.fs_stat,
  fstat = UV.fs_fstat,
  rename = UV.fs_rename,
  fsync = UV.fs_fsync,
  fdatasync = UV.fs_fdatasync,
  ftruncate = UV.fs_ftruncate,
  sendfile = UV.fs_sendfile,
  chmod = UV.fs_chmod,
  utime = UV.fs_utime,
  futime = UV.fs_futime,
  lstat = UV.fs_lstat,
  link = UV.fs_link,
  symlink = UV.fs_symlink,
  readlink = UV.fs_readlink,
  fchmod = UV.fs_fchmod,
  chown = UV.fs_chown,
  fchown = UV.fs_fchown,
}

