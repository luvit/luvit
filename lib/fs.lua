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

local CHUNK_SIZE = 65536

local read_options = {
  flags = "r",
  mode = "0644",
  chunk_size = CHUNK_SIZE,
  offset = 0,
  length = nil -- nil means read to EOF
}
local read_meta = {__index=read_options}

-- TODO: Implement backpressure here and in tcp streams
function FS.create_read_stream(path, options)
  if not options then
    options = read_options
  else
    setmetatable(options, read_meta)
  end

  local stream = Stream.new()
  FS.open(path, options.flags, options.mode, function (err, fd)
    if err then return stream:emit("error", err) end
    local offset = options.offset
    local last = options.length and offset + options.length
    local chunk_size = options.chunk_size

    local function read_chunk()
      local to_read = (last and chunk_size + offset > last and last - offset) or chunk_size
      FS.read(fd, offset, to_read, function (err, chunk, len)
        if err or len == 0 then
          FS.close(fd, function (err)
            if err then return stream:emit("error", err) end
            stream:emit("close")
          end)
          if err then return stream:emit("error", err) end

          stream:emit("end")
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

local write_options = {
  flags = "w",
  mode = "0644",
  chunk_size = CHUNK_SIZE,
  offset = 0,
}
local write_meta = {__index=write_options}

function FS.create_write_stream(path, options)
  if not options then
    options = write_options
  else
    setmetatable(options, write_meta)
  end

  error("TODO: Implement write_stream")
end

function FS.read_file(path, callback)
  local stream = FS.create_read_stream(path)
  local parts = {}
  local num = 0
  stream:on("data", function (chunk, len)
    num = num + 1
    parts[num] = chunk
  end)
  stream:on("end", function ()
    return callback(nil, Table.concat(parts, ""))
  end)
  stream:on("error", callback)
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


return FS

