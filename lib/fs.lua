local UV = require('uv')

function resume(...)
  coroutine.resume(co, ...)
end

-- Make functions work with coros or callbacks
function wrap(fn, nargs)
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

function fiber(fn)
  local co = coroutine.create(fn)
  assert(coroutine.resume(co, co))
end

return {
  fiber = fiber,
  open = wrap(UV.fs_open, 3),
  close = wrap(UV.fs_close, 1),
  read = wrap(UV.fs_read, 3),
  write = wrap(UV.fs_write, 3),
  unlink = wrap(UV.fs_unlink, 1),
  mkdir = wrap(UV.fs_mkdir, 2),
  rmdir = wrap(UV.fs_rmdir, 1),
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
}

