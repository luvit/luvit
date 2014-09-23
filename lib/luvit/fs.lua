--[[

Copyright 2012 The Luvit Authors. All Rights Reserved.

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

local Error = require('core').Error
local native = require('uv_native')
local table = require('table')
local pathlib = require('path')
local iStream = require('core').iStream
local fs = {}

local function passthrough(arg)
   return arg
end

local function longpath(arg)
   return pathlib._makeLong(arg)
end

local func_descs = {
  Close = { passthrough },
  Read = { passthrough, passthrough, passthrough },
  Write = { passthrough, passthrough, passthrough },
  Unlink = { longpath },
  Mkdir = { longpath, passthrough},
  Rmdir = { longpath },
  Readdir = { longpath },
  Stat = { longpath },
  Fstat = { passthrough },
  Rename = { longpath, longpath },
  Fsync = { passthrough },
  Fdatasync = { passthrough },
  Sendfile = { passthrough, passthrough, passthrough, passthrough },
  Chmod = { longpath, passthrough},
  Utime = { longpath, passthrough, passthrough },
  Futime = { passthrough, passthrough, passthrough },
  Lstat = { longpath },
  Link = { longpath, longpath },
  Symlink = { longpath, longpath, passthrough },
  Readlink = { longpath },
  Fchmod = { passthrough, passthrough},
  Chown = { longpath, passthrough, passthrough },
  Fchown = { passthrough, passthrough, passthrough },
}

-- Default callback if one isn't given for async operations
local function default(err, ...)
  if err then error(err) end
end

-- Wrap the core fs functions in forced sync and async versions
for name, param_handlers in pairs(func_descs) do
  local sync, async
  local real = native["fs" .. name]
  if #param_handlers == 1 then
    async = function (arg, callback)
      return real(param_handlers[1](arg), callback or default)
    end
    sync = function (arg)
      return real(param_handlers[1](arg))
    end
  elseif #param_handlers == 2 then
    async = function (arg1, arg2, callback)
      return real(param_handlers[1](arg1), param_handlers[2](arg2), callback or default)
    end
    sync = function (arg1, arg2)
      return real(param_handlers[1](arg1), param_handlers[2](arg2))
    end
  elseif #param_handlers == 3 then
    async = function (arg1, arg2, arg3, callback)
      return real(param_handlers[1](arg1), param_handlers[2](arg2), param_handlers[3](arg3), callback or default)
    end
    sync = function (arg1, arg2, arg3)
      return real(param_handlers[1](arg1), param_handlers[2](arg2), param_handlers[3](arg3))
    end
  elseif #param_handlers == 4 then
    async = function (arg1, arg2, arg3, arg4, callback)
      return real(param_handlers[1](arg1), param_handlers[2](arg2), param_handlers[3](arg3), param_handlers[4](arg4), callback or default)
    end
    sync = function (arg1, arg2, arg3, arg4)
      return real(param_handlers[1](arg1), param_handlers[2](arg2), param_handlers[3](arg3), param_handlers[4](arg4))
    end
  end
  fs[name:lower()] = async
  fs[name:lower() .. "Sync"] = sync
end

local function modeNum(m, def)
  local t = type(m)
  if t == 'number' then
    return m
  elseif t == 'string' then
    return tonumber(m, 8)
  else
    return def and modeNum(def) or nil
  end
end

function fs.open(path, flags, mode, callback)
  if callback == nil then
    callback = mode
    mode = nil
  end
  mode = modeNum(mode, 438 --[[=0666]])
  native.fsOpen(pathlib._makeLong(path), flags, mode, callback or default)
end

function fs.openSync(path, flags, mode)
  return native.fsOpen(pathlib._makeLong(path), flags, modeNum(mode, 438 --[[=0666]]))
end

function fs.exists(path, callback)
  native.fsStat(pathlib._makeLong(path), function (err)
    if not err then
      return callback(nil, true)
    end
    if err.code == "ENOENT" or err.code == "ENOTDIR" then
      return callback(nil, false)
    end
    callback(err)
  end)
end

function fs.existsSync(path)
  local success, err = pcall(function ()
    native.fsStat(pathlib._makeLong(path))
  end)
  if not err then return true end
  if err.code == "ENOENT" or err.code == "ENOTDIR" then
    return false
  end
  error(err)
end

local function writeAll(fd, offset, buffer, callback)
  fs.write(fd, offset, buffer, function(err, written)
    if err then
      fs.close(fd, function()
        if callback then callback(err) end
      end)
    end
    if written == #buffer then
      fs.close(fd, callback)
    else
      offset = offset + written
      writeAll(fd, offset, buffer, callback)
    end
  end)
end

function fs.appendFile(path, data, callback)
  fs.open(pathlib._makeLong(path), 'a', 438 --[[0666]], function(err, fd)
    if err then return callback(err) end
    writeAll(fd, -1, tostring(data), callback)
  end)
end

function fs.appendFileSync(path, data)
  data = tostring(data)
  local fd = fs.openSync(pathlib._makeLong(path), 'a')
  local written = 0
  local length = #data

  local ok, err
  ok, err = pcall(function()
    while written < length do
      written = written + fs.writeSync(fd, -1, data)
    end
  end)
  if not ok then
    return err
  end
  fs.closeSync(fd)
end

function fs.ftruncate(fd, len, callback)
  if callback == nil then
    callback = len
    len = nil
  end
  native.fsFtruncate(fd, len or 0, callback or default)
end

function fs.ftruncateSync(fd, len)
  return native.fsFtruncate(fd, len or 0)
end

function fs.truncate(path, len, callback)
  if callback == nil then
    callback = len
    len = nil
  end
  fs.open(pathlib._makeLong(path), 'w', function(err, fd)
    if err then return callback(err) end
    native.fsFtruncate(fd, len or 0, function(err)
      fs.close(fd, function(err2)
        (callback or default)(err or err2)
      end)
    end)
  end)
end

function fs.truncateSync(path, len)
  local fd = fs.openSync(pathlib._makeLong(path), 'w')
  local ok, err
  ok, err = pcall(native.fsFtruncate, fd, len or 0)
  if not ok then
    return err
  end
  fs.closeSync(fd)
end

local CHUNK_SIZE = 65536

local read_options = {
  flags = "r",
  mode = "0644",
  chunk_size = CHUNK_SIZE,
  offset = 0,
  fd = nil,
  reading = nil,
  length = nil -- nil means read to EOF
}
local read_meta = {__index=read_options}

-- TODO: Implement backpressure here and in tcp streams
local ReadStream = iStream:extend()
fs.ReadStream = ReadStream

function ReadStream:initialize(path, options)

  if not options then
    options = read_options
  else
    setmetatable(options, read_meta)
  end

  self.options = options
  self.offset = options.offset
  self.last = options.length and self.offset + options.length

  if (options.fd ~= nil) then
    self.fd = options.fd
    self:_read()
    return
  end

  fs.open(pathlib._makeLong(path), options.flags, options.mode, function (err, fd)
    if err then return self:emit("error", err) end
    self.fd = fd
    self:_read()
  end)
end

function ReadStream:readStart()
  if (self.reading) then
    return
  end
  self:_read()
end

function ReadStream:_read()
  local options = self.options

  local chunk_size = options.chunk_size
  local to_read = chunk_size
  if self.last ~= nil then
    -- indicating length was set in option; need to check boundary
    if chunk_size + self.offset > self.last then
      to_read = self.last - self.offset
    end
  end

  self.reading = true

  fs.read(self.fd, self.offset, to_read, function (err, chunk, len)
    if err or len == 0 then
      fs.close(self.fd, function (err)
        if err then return self:emit("error", err) end
        self:emit("close")
      end)
      if err then return self:emit("error", err) end

      self.reading = false
      self:emit("end")
    else
      self:emit("data", chunk, len)
      self.offset = self.offset + len
      self:_read()
    end
  end)
end

-- TODO: Implement backpressure here and in tcp streams
function fs.createReadStream(path, options)
  return ReadStream:new(pathlib._makeLong(path), options)
end

function fs.readFileSync(path)
  local fd = fs.openSync(pathlib._makeLong(path), "r", "0666")
  local parts = {}
  local length = 0
  local offset = 0
  repeat
    local chunk, len = fs.readSync(fd, offset, CHUNK_SIZE)
    if len > 0 then
      offset = offset + len
      length = length + 1
      parts[length] = chunk
    end
  until len == 0
  fs.closeSync(fd)
  return table.concat(parts)
end

function fs.readFile(path, callback)
  local stream = fs.createReadStream(pathlib._makeLong(path))
  local parts = {}
  local num = 0
  stream:on("data", function (chunk, len)
    num = num + 1
    parts[num] = chunk
  end)
  stream:on("end", function ()
    return callback(nil, table.concat(parts, ""))
  end)
  stream:on("error", callback)
end

function fs.writeFileSync(path, data)
  local fd = fs.openSync(pathlib._makeLong(path), "w", "0666")
  fs.writeSync(fd, 0, data)
  fs.closeSync(fd)
end

function fs.writeFile(path, data, callback)
  if not type(data) == 'string' then
    error('data parameter must be a string')
  end
  fs.open(pathlib._makeLong(path), "w", "0666", function (err, fd)
    if err then return callback(err) end
    local offset = 0
    local length = #data
    local function writechunk()
      fs.write(fd, offset, data:sub(offset + 1, CHUNK_SIZE + offset), function (err, bytes_written)
        if err then return callback(err) end
        if bytes_written + offset < length then
          offset = offset + bytes_written
          writechunk()
        else
          fs.close(fd, callback)
        end
      end)
    end
    writechunk()
  end)
end

local SyncWriteStream = iStream:extend()
fs.SyncWriteStream = SyncWriteStream

-- Copy hack from nodejs to stdout and stderr to piped file
function SyncWriteStream:initialize(fd)
  self.fd = fd
  self.offset = 0
  self.closed = false
end

function SyncWriteStream:write(chunk)
  if self.closed then
    self:emit('error', Error:new('write after end'))
    return
  end
  local len = fs.writeSync(self.fd, self.offset, chunk)
  self.offset = self.offset + len
  return len
end

function SyncWriteStream:finish(chunk)
  if chunk then
    self:write(chunk)
  end
  self:_closeStream()
  self:emit("end")
end

function SyncWriteStream:_closeStream()
  if self.closed then
    return
  end
  fs.closeSync(self.fd)
  self.closed = true
  self:emit("closed")
end

-- TODO: Create non-sync writestream
local WriteStream = SyncWriteStream:extend()
fs.WriteStream = WriteStream

local write_options = {
  flags = "w",
  mode = "0644",
  chunk_size = CHUNK_SIZE,
  offset = 0,
}
local write_meta = {__index=write_options}

function fs.createWriteStream(path, options)
  if not options then
    options = write_options
  else
    setmetatable(options, write_meta)
  end

  if (options.fd ~= nil) then
    return WriteStream:new(options.fd)
  end

  local fd = fs.openSync(pathlib._makeLong(path), options.flags, options.mode)
  return WriteStream:new(fd)
end

function WriteStream:open(fd)
  self:initialize(fd)
end

return fs
