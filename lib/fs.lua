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

local UV = require('uv')
local Table = require('table')
local Stream = require('stream')
local FS = {}
local sizes = {
  open = 3,
  close = 1,
  read = 3,
  write = 3,
  unlink = 1,
  mkdir = 2,
  rmdir = 1,
  readdir = 1,
  stat = 1,
  fstat = 1,
  rename = 2,
  fsync = 1,
  fdatasync = 1,
  ftruncate = 2,
  sendfile = 4,
  chmod = 2,
  utime = 3,
  futime = 3,
  lstat = 1,
  link = 2,
  symlink = 3,
  readlink = 1,
  fchmod = 2,
  chown = 3,
  fchown = 3,
}

-- Default callback if one isn't given for async operations
local function default(err, ...)
  if err then error(err) end
end

-- Wrap the core fs functions in forced sync and async versions
for name, arity in pairs(sizes) do
  local sync, async
  local real = UV["fs_" .. name]
  if arity == 1 then
    async = function (arg, callback)
      return real(arg, callback or default)
    end
    sync = function (arg)
      return real(arg)
    end
  elseif arity == 2 then
    async = function (arg1, arg2, callback)
      return real(arg1, arg2, callback or default)
    end
    sync = function (arg1, arg2)
      return real(arg1, arg2)
    end
  elseif arity == 3 then
    async = function (arg1, arg2, arg3, callback)
      return real(arg1, arg2, arg3, callback or default)
    end
    sync = function (arg1, arg2, arg3)
      return real(arg1, arg2, arg3)
    end
  elseif arity == 4 then
    async = function (arg1, arg2, arg3, arg4, callback)
      return real(arg1, arg2, arg3, arg4, callback or default)
    end
    sync = function (arg1, arg2, arg3, arg4)
      return real(arg1, arg2, arg3, arg4)
    end
  end
  FS[name] = async
  FS[name .. "_sync"] = sync
end

function FS.exists(path, callback)
  UV.fs_stat(path, function (err)
    if not err then
      return callback(nil, true)
    end
    if err.code == "ENOENT" or err.code == "ENOTDIR" then
      return callback(nil, false)
    end
    callback(err)
  end)
end

function FS.exists_sync(path)
  local success, err = pcall(function ()
    UV.fs_stat(path)
  end)
  if not err then return true end
  if err.code == "ENOENT" or err.code == "ENOTDIR" then
    return false
  end
  error(err)
end

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

  local stream = Stream:new()
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

function FS.read_file_sync(path)
  local fd = FS.open_sync(path, "r", "0666")
  local parts = {}
  local length = 0
  local offset = 0
  repeat
    local chunk, len = FS.read_sync(fd, offset, CHUNK_SIZE)
    if len > 0 then
      offset = offset + len
      length = length + 1
      parts[length] = chunk
    end
  until len == 0
  FS.close_sync(fd)
  return Table.concat(parts)
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

