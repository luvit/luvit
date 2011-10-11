local UV = require('uv')
local Table = require('table')
local Stream = require('stream')

local FS = {
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

local CHUNK_SIZE = 4096

function FS.read_file(path, callback)
  FS.open(path, "r", "0666", function (err, fd)
    if err then return callback(err) end
    local parts = {}
    local offset = 0
    local index = 1
    local function readchunk()
      FS.read(fd, offset, CHUNK_SIZE, function (err, chunk)
        if err then return callback(err) end
        if #chunk == 0 then
          FS.close(fd, function (err)
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

function FS.write_file(path, data, callback)
  FS.open(path, "w", "0666", function (err, fd)
    if err then return callback(err) end
    local offset = 0
    local length = #data
    local function writechunk()
      FS.write(fd, offset, data:sub(offset + 1, CHUNK_SIZE + offset), function (err, bytes_written)
        if err then return callback(err) end
        if bytes_written + offset < length then
          offset = offset + bytes_written
          writechunk()
        else
          FS.close(fd, callback)
        end
      end)
    end
    writechunk()
  end)
end

function FS.create_read_stream(path, options)
  local stream = Stream.new()
  FS.open(path, "r", "0666", function (err, fd)
    if err then return stream:emit("error", err) end
    local offset = 0
    function read_chunk()
      FS.read(fd, offset, CHUNK_SIZE, function (err, chunk, len)
        if err then return stream:emit("error", err) end
        if len == 0 then
          stream:emit("end")
          FS.close(fd, function (err)
            if err then return stream:emit("error", err) end
            stream:emit("closed")
          end)
        else
          stream:emit("data", chunk, len)
          offset = offset + len
          read_chunk()
        end
      end)
    end
    read_chunk()
  end)
  return stream
end

return FS

