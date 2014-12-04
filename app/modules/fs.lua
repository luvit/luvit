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
local adapt = require('utils').adapt
local bind = require('utils').bind
local fs = exports
local Writable = require('stream_writable').Writable

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
    offset = -1
  end
  return adapt(callback, uv.fs_read, fd, size, offset)
end
function fs.readSync(fd, size, offset)
  if size == nil then
    size = 4096
  end
  if offset == nil then
    offset = -1
  end
  return uv.fs_read(fd, size, offset)
end
function fs.unlink(path, callback)
  return adapt(callback, uv.fs_unlink, path)
end
function fs.unlinkSync(path)
  return uv.fs_unlink(path)
end
function fs.write(fd, offset, data, callback)
  local ot = type(offset)
  if (ot == 'function' or ot == 'thread') and
     (callback == nil) then
    callback, offset = offset, nil
  end
  if offset == nil then
    offset = -1 -- -1 means append
  end
  return adapt(callback, uv.fs_write, fd, data, offset)
end
function fs.writeSync(fd, data, offset)
  if offset == nil then
    offset = -1 -- -1 means append
  end
  return uv.fs_write(fd, data, offset)
end
function fs.mkdir(path, mode, callback)
  local mt = type(mode)
  if (mt == 'function' or mt == 'thread') and
     (callback == nil) then
    callback, mode = mode, nil
  end
  if mode == nil then
    mode = 511 -- 0777
  end
  return adapt(callback, uv.fs_mkdir, path, mode)
end
function fs.mkdirSync(path, mode)
  if mode == nil then
    mode = 511
  end
  return uv.fs_mkdir(path, mode)
end
function fs.mkdtemp(template, callback)
  return adapt(callback, uv.fs_mkdtemp, template)
end
function fs.mkdtempSync(template)
  return uv.fs_mkdtemp(template)
end
function fs.rmdir(path, callback)
  return adapt(callback, uv.fs_rmdir, path)
end
function fs.rmdirSync(path)
  return uv.fs_rmdir(path)
end
local function readdir(path, callback)
  uv.fs_scandir(path, function (err, req)
    if err then return callback(err) end
    local files = {}
    local i = 1
    while true do
      local ent = uv.fs_scandir_next(req)
      if not ent then break end
      files[i] = ent.name
      i = i + 1
    end
    callback(nil, files)
  end)
end
function fs.readdir(path, callback)
  return adapt(callback, readdir, path)
end
function fs.readdirSync(path)
  local req = uv.fs_scandir(path)
  local files = {}
  local i = 1
  while true do
    local ent = uv.fs_scandir_next(req)
    if not ent then break end
    files[i] = ent.name
    i = i + 1
  end
  return files
end
local function scandir(path, callback)
  uv.fs_scandir(path, function (err, req)
    if err then return callback(err) end
    callback(nil, function ()
      local ent = uv.fs_scandir_next(req)
      if ent then
        return ent.name, ent.type
      end
    end)
  end)
end
function fs.scandir(path, callback)
  return adapt(callback, scandir, path)
end
function fs.scandirSync(path)
  local req = uv.fs_scandir(path)
  return function ()
    local ent = uv.fs_scandir_next(req)
    if ent then
      return ent.name, ent.type
    end
  end
end
function fs.stat(path, callback)
  return adapt(callback, uv.fs_stat, path)
end
function fs.statSync(path)
  return uv.fs_stat(path)
end
function fs.fstat(fd, callback)
  return adapt(callback, uv.fs_fstat, fd)
end
function fs.fstatSync(fd)
  return uv.fs_fstat(fd)
end
function fs.lstat(path, callback)
  return adapt(callback, uv.fs_lstat, path)
end
function fs.lstatSync(path)
  return uv.fs_lstat(path)
end
function fs.rename(path, newPath, callback)
  return adapt(callback, uv.fs_rename, path, newPath)
end
function fs.renameSync(path, newPath)
  return uv.fs_rename(path, newPath)
end
function fs.fsync(fd, callback)
  return adapt(callback, uv.fs_fsync, fd)
end
function fs.fsyncSync(fd)
  return uv.fs_fsync(fd)
end
function fs.fdatasync(fd, callback)
  return adapt(callback, uv.fs_fdatasync, fd)
end
function fs.fdatasyncSync(fd)
  return uv.fs_fdatasync(fd)
end
function fs.ftruncate(fd, offset, callback)
  local ot = type(offset)
  if (ot == 'function' or ot == 'thread') and
     (callback == nil) then
    callback, offset = offset, nil
  end
  if offset == nil then
    offset = 0
  end
  return adapt(callback, uv.fs_ftruncate, fd, offset)
end
function fs.ftruncateSync(fd, offset)
  if offset == nil then
    offset = 0
  end
  return uv.fs_ftruncate(fd, offset)
end
function fs.sendfile(outFd, inFd, offset, length, callback)
  return adapt(callback, uv.fs_sendfile, outFd, inFd, offset, length)
end
function fs.sendfileSync(outFd, inFd, offset, length)
  return uv.fs_sendfile(outFd, inFd, offset, length)
end
function fs.access(path, flags, callback)
  local ft = type(flags)
  if (ft == 'function' or ft == 'thread') and
     (callback == nil) then
    callback, flags = flags, nil
  end
  if flags == nil then
    flags = 0
  end
  return adapt(callback, uv.fs_access, path, flags)
end
function fs.accessSync(path, flags)
  if flags == nil then
    flags = 0
  end
  return uv.fs_access(path, flags)
end
function fs.chmod(path, mode, callback)
  return adapt(callback, uv.fs_chmod, path, mode)
end
function fs.chmodSync(path, mode)
  return uv.fs_chmod(path, mode)
end
function fs.fchmod(fd, mode, callback)
  return adapt(callback, uv.fs_fchmod, fd, mode)
end
function fs.fchmodSync(fd, mode)
  return uv.fs_fchmod(fd, mode)
end
function fs.utime(path, atime, mtime, callback)
  return adapt(callback, uv.fs_utime, path, atime, mtime)
end
function fs.utimeSync(path, atime, mtime)
  return uv.fs_utime(path, atime, mtime)
end
function fs.futime(fd, atime, mtime, callback)
  return adapt(callback, uv.fs_futime, fd, atime, mtime)
end
function fs.futimeSync(fd, atime, mtime)
  return uv.fs_futime(fd, atime, mtime)
end
function fs.link(path, newPath, callback)
  return adapt(callback, uv.fs_link, path, newPath)
end
function fs.linkSync(path, newPath)
  return uv.fs_link(path, newPath)
end
function fs.symlink(path, newPath, options, callback)
  local ot = type(options)
  if (ot == 'function' or ot == 'thread') and
     (callback == nil) then
    callback, options = options, nil
  end
  return adapt(callback, uv.fs_symlink, path, newPath, options)
end
function fs.symlinkSync(path, newPath, options)
  return uv.fs_symlink(path, newPath, options)
end
function fs.readlink(path, callback)
  return adapt(callback, uv.fs_readlink, path)
end
function fs.readlinkSync(path)
  return uv.fs_readlink(path)
end
function fs.chown(path, uid, gid, callback)
  return adapt(callback, uv.fs_chown, path, uid, gid)
end
function fs.chownSync(path, uid, gid)
  return uv.fs_chown(path, uid, gid)
end
function fs.fchown(fd, uid, gid, callback)
  return adapt(callback, uv.fs_fchown, fd, uid, gid)
end
function fs.fchownSync(fd, uid, gid)
  return uv.fs_fchown(fd, uid, gid)
end
local function noop() end
local function readFile(path, callback)
  local fd, onStat, onRead
  uv.fs_open(path, "r", 438 --[[ 0666 ]], function (err, result)
    if err then return callback(err) end
    fd = result
    uv.fs_fstat(fd, onStat)
  end)
  function onStat(err, stat)
    if err then return onRead(err) end
    uv.fs_read(fd, stat.size, 0, onRead)
  end
  function onRead(err, chunk)
    uv.fs_close(fd, noop)
    return callback(err, chunk)
  end
end
function fs.readFile(path, callback)
  return adapt(callback, readFile, path)
end
function fs.readFileSync(path)
  local fd, stat, chunk, err
  fd, err = uv.fs_open(path, "r", 438 --[[ 0666 ]])
  if err then return false, err end
  stat, err = uv.fs_fstat(fd)
  if stat then
    chunk, err = uv.fs_read(fd, stat.size, 0)
  end
  uv.fs_close(fd, noop)
  return chunk, err
end
local function writeFile(path, data, callback)
  local fd, onWrite
  uv.fs_open(path, "w", 438 --[[ 0666 ]], function (err, result)
    if err then return callback(err) end
    fd = result
    uv.fs_write(fd, data, 0, onWrite)
  end)
  function onWrite(err)
    uv.fs_close(fd, noop)
    return callback(err)
  end
end
function fs.writeFile(path, data, callback)
  adapt(callback, writeFile, path, data)
end
function fs.writeFileSync(path, data)
  local _, fd, err
  fd, err = (uv.fs_open(path, "w", 438 --[[ 0666 ]]))
  if err then return false, err end
  _, err = uv.fs_write(fd, data, 0)
  uv.fs_close(fd, noop)
  return not err, err
end

fs.WriteStream = Writable:extend()
function fs.WriteStream:initialize(path, options)
  Writable.initialize(self)

  self.options = options or {}
  self.path = path
  self.fd = nil
  self.pos = nil
  self.bytesWritten = 0

  if self.options.fd then self.fd = self.options.fd end
  if self.options.flags then self.flags = self.options.flags else self.flags = 'w' end
  if self.options.mode then self.mode = self.options.mode else self.mode = 438 end
  if self.options.start then self.start = self.options.start end

  self.pos = self.start

  if not self.fd then self:open() end

  self:on('finish', bind(self.close, self))
end
function fs.WriteStream:open()
  fs.open(self.path, "a", nil, function(err, fd)
    if err then
      self:destroy()
      self:emit('error', err)
      if callback then return callback(err) end
    end
    self.fd = fd
    self:emit('open', fd)
    if callback then callback() end
  end)
end
function fs.WriteStream:_write(data, encoding, callback)
  if not self.fd then
    return self:once('open', bind(self._write, self, data, encoding, callback))
  end
  fs.write(self.fd, nil, data, function(err, bytes)
    if err then
      self:destroy()
      return callback(err)
    end
    self.bytesWritten = self.bytesWritten + bytes
    callback()
  end)
end
function fs.WriteStream:close()
  self:destroy()
end
function fs.WriteStream:destroy()
  if self.fd then
    fs.close(self.fd)
    self.fd = nil
  end
end
