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

local uv = require('uv')
local table = require('table')
local Handle = require('core').Handle
local Stream = require('core').Stream
local fs = {}
local sizes = {
  Open = 3,
  Close = 1,
  Read = 3,
  Write = 3,
  Unlink = 1,
  Mkdir = 2,
  Rmdir = 1,
  Readdir = 1,
  Stat = 1,
  Fstat = 1,
  Rename = 2,
  Fsync = 1,
  Fdatasync = 1,
  Ftruncate = 2,
  Sendfile = 4,
  Chmod = 2,
  Utime = 3,
  Futime = 3,
  Lstat = 1,
  Link = 2,
  Symlink = 3,
  Readlink = 1,
  Fchmod = 2,
  Chown = 3,
  Fchown = 3,
}

-- Default callback if one isn't given for async operations
local function default(err, ...)
  if err then error(err) end
end

-- Wrap the core fs functions in forced sync and async versions
for name, arity in pairs(sizes) do
  local sync, async
  local real = uv["fs" .. name]
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
  fs[name:lower()] = async
  fs[name:lower() .. "Sync"] = sync
end

function fs.exists(path, callback)
  uv.fsStat(path, function (err)
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
    uv.fsStat(path)
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
function fs.createReadStream(path, options)
  if not options then
    options = read_options
  else
    setmetatable(options, read_meta)
  end

  local stream = Stream:new()
  fs.open(path, options.flags, options.mode, function (err, fd)
    if err then return stream:emit("error", err) end
    local offset = options.offset
    local last = options.length and offset + options.length
    local chunk_size = options.chunk_size

    local function readChunk()
      local to_read = (last and chunk_size + offset > last and last - offset) or chunk_size
      fs.read(fd, offset, to_read, function (err, chunk, len)
        if err or len == 0 then
          fs.close(fd, function (err)
            if err then return stream:emit("error", err) end
            stream:emit("close")
          end)
          if err then return stream:emit("error", err) end

          stream:emit("end")
        else
          stream:emit("data", chunk, len)
          offset = offset + len
          readChunk()
        end
      end)
    end
    readChunk()
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

function fs.createWriteStream(path, options)
  if not options then
    options = write_options
  else
    setmetatable(options, write_meta)
  end

  error("TODO: Implement write_stream")
end

function fs.readFileSync(path)
  local fd = fs.openSync(path, "r", "0666")
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
  local stream = fs.createReadStream(path)
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

function fs.writeFile(path, data, callback)
  fs.open(path, "w", "0666", function (err, fd)
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

local Watcher = Handle:extend()
fs.Watcher = Watcher

function Watcher:initialize(path)
  self.userdata = uv.newFsWatcher(path)
end

return fs

