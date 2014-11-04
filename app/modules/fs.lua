--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]
local uv = require('uv')
local fs = exports

local function noop(err)
  if err then print("Unhandled callback error", err) end
end

local function adapt(c, fn, ...)
  local nargs = select('#', ...)
  local args = {...}
  -- No continuation defaults to noop callback
  if not c then c = noop end
  local t = type(c)
  if t == 'function' then
    args[nargs + 1] = c
    return fn(unpack(args))
  elseif t ~= 'thread' then
    error("Illegal continuation type " .. t)
  end
  local err, data, waiting
  args[nargs + 1] = function (err, ...)
    if waiting then
      if err then
        coroutine.resume(c, nil, err)
      else
        coroutine.resume(c, ...)
      end
    else
      error, data = err, {...}
      c = nil
    end
  end
  fn(unpack(args))
  if c then
    waiting = true
    return coroutine.yield(c)
  elseif err then
    return nil, err
  else
    return unpack(data)
  end
end


function fs.close(fd, callback)
  return adapt(callback, uv.fs_close, fd)
end
function fs.closeSync(fd)
  return uv.fs_close(fd)
end

function fs.open(path, flags, mode, callback)
  local ft = type(flags)
  local mt = type(mode)
  -- (path, callback)
  if (ft == 'function' or ft == 'thread') and
     (mode == nil and callback == nil) then
    callback, flags = flags, nil
  -- (path, flags, callback)
  elseif (mt == 'function' or mt == 'thread') and
         (callback == nil) then
    callback, mode = mode, nil
  end
  -- Default flags to 'r'
  if flags == nil then
    flags = 'r'
  end
  -- Default mode to 0666
  if mode == nil then
    mode = 438 -- 0666
  -- Assume strings are octal numbers
  elseif mt == 'string' then
    mode = tonumber(mode, 8)
  end
  return adapt(callback, uv.fs_open, path, flags, mode)
end
function fs.openSync(path, flags, mode)
  if flags == nil then
    flags = "r"
  end
  if mode == nil then
    mode = 438 --  0666
  elseif type(mode) == "string" then
    mode = tonumber(mode, 8)
  end
  return uv.fs_open(path, flags, mode)
end
function fs.read(fd, size, offset, callback)
  local st = type(size)
  local ot = type(offset)
  if (st == 'function' or st == 'thread') and
     (offset == nil and callback == nil) then
    callback, size = size, nil
  elseif (ot == 'function' or ot == 'thread') and
         (callback == nil) then
    callback, offset = offset, nil
  end
  if size == nil then
    size = 4096
  end
  if offset == nil then
    -- TODO: allow nil in luv for append position
    offset = 0
  end
  return adapt(callback, uv.fs_read, fd, size, offset)
end
function fs.readSync(fd, size, offset)
  if size == nil then
    size = 4096
  end
  if offset == nil then
    -- TODO: allow nil in luv for append position
    offset = 0
  end
  return uv.fs_read(fd, size, offset)
end
-- function fs.unlink(callback)
-- end
-- function fs.write(callback)
-- end
-- function fs.mkdir(callback)
-- end
-- function fs.mkdtemp(callback)
-- end
-- function fs.rmdir(callback)
-- end
-- function fs.scandir(callback)
-- end
-- function fs.scandirNext(callback)
-- end
-- function fs.stat(callback)
-- end
function fs.fstat(fd, callback)
  return adapt(callback, uv.fs_fstat, fd)
end
function fs.fstatSync(fd)
  return uv.fs_fstat(fd)
end
-- function fs.lstat(callback)
-- end
-- function fs.rename(callback)
-- end
-- function fs.fsync(callback)
-- end
-- function fs.fdatasync(callback)
-- end
-- function fs.ftruncate(callback)
-- end
-- function fs.sendfile(callback)
-- end
-- function fs.access(callback)
-- end
-- function fs.chmod(callback)
-- end
-- function fs.fchmod(callback)
-- end
-- function fs.utime(callback)
-- end
-- function fs.futime(callback)
-- end
-- function fs.link(callback)
-- end
-- function fs.symlink(callback)
-- end
-- function fs.readlink(callback)
-- end
-- function fs.chown(callback)
-- end
-- function fs.fchown(callback)
-- end
