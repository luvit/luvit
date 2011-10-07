local UV = require('uv')

local function resume(...)
  coroutine.resume(co, ...)
end

-- Make functions work with coros or callbacks
local function wrap(fn, nargs)
  return function (coro, ...)
    if (type(coro) == 'thread') then
      local resume = function (...)
        assert(coroutine.resume(coro, ...))
      end
      local args = {...}
      if (nargs == 1) then
        fn(args[1], resume)
      elseif (nargs == 2) then
        fn(args[1], args[2], resume)
      elseif (nargs == 3) then
        fn(args[1], args[2], args[3], resume)
      elseif (nargs == 4) then
        fn(args[1], args[2], args[3], args[4], resume)
      else
        error("Too many nargs")
      end
      return coroutine.yield()
    else
      -- In this case coro is actually the first arg
      fn(coro, ...)
    end
  end
end

local CHUNK_SIZE = 4096

local function read_file(path, callback)
  UV.fs_open(path, "r", "0666", function (err, fd)
    if (err) then return callback(err) end
    local parts = {}
    local offset = 0
    local index = 1
    local function readchunk()
      UV.fs_read(fd, offset, CHUNK_SIZE, function (err, chunk)
        if (err) then return callback(err) end
        if #chunk == 0 then
          UV.fs_close(fd, function (err)
            if (err) then return callback(err) end
            return callback(nil, table.concat(parts, ""))
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
      UV.fs_write(fd, offset, string.sub(data, offset + 1, CHUNK_SIZE + offset), function (err, bytes_written)
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

local function fiber(fn)
  local co = coroutine.create(fn)
  assert(coroutine.resume(co, co))
end

return {
  fiber = fiber,
  read_file = wrap(read_file, 1),
  write_file = wrap(write_file, 2),
  open = wrap(UV.fs_open, 3),
  close = wrap(UV.fs_close, 1),
  read = wrap(UV.fs_read, 3),
  write = wrap(UV.fs_write, 3),
  unlink = wrap(UV.fs_unlink, 1),
  mkdir = wrap(UV.fs_mkdir, 2),
  rmdir = wrap(UV.fs_rmdir, 1),
  readdir = wrap(UV.fs_readdir, 1),
  stat = wrap(UV.fs_stat, 1),
  fstat = wrap(UV.fs_fstat, 1),
  rename = wrap(UV.fs_rename, 2),
  fsync = wrap(UV.fs_fsync, 1),
  fdatasync = wrap(UV.fs_fdatasync, 1),
  ftruncate = wrap(UV.fs_ftruncate, 2),
  sendfile = wrap(UV.fs_sendfile, 4),
  chmod = wrap(UV.fs_chmod, 2),
  utime = wrap(UV.fs_utime, 3),
  futime = wrap(UV.fs_futime, 3),
  lstat = wrap(UV.fs_lstat, 1),
  link = wrap(UV.fs_link, 2),
  symlink = wrap(UV.fs_symlink, 3),
  readlink = wrap(UV.fs_readlink, 1),
  fchmod = wrap(UV.fs_fchmod, 2),
  chown = wrap(UV.fs_chown, 3),
  fchown = wrap(UV.fs_fchown, 3),
}

