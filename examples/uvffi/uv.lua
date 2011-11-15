-- This is an experiment to see how fast ffi calls are and how ugly/pretty
-- the bindings are.

local FFI = require('ffi')
local Fs = require('fs')
local Path = require('path')

-- Read the combined libuv and http_parser header file
FFI.cdef(Fs.read_file_sync(Path.join(__dirname, "ffi_uv.h")))

local C = FFI.C

--------------------------------------------------------------------------------
-- minimal libuv bindings using ffi

local function uv_assert(r)
  if r == -1 then
    local err = C.uv_last_error(C.uv_default_loop())
    local name = FFI.string(C.uv_err_name(err))
    local message = FFI.string(C.uv_strerror(err))
    error(name .. ": " .. message)
  end
end

local handle_prototype = {}

function handle_prototype:close(close_cb)
  C.uv_close(FFI.cast("uv_handle_t*", self), close_cb)
end

local stream_prototype = setmetatable({}, {__index=handle_prototype})

function stream_prototype:listen(on_connection)
  uv_assert(C.uv_listen(FFI.cast("uv_stream_t*", self), 128, on_connection))
end

function stream_prototype:accept(client)
  uv_assert(C.uv_accept(FFI.cast("uv_stream_t*", self), FFI.cast("uv_stream_t*", client)))
end

local function on_alloc(...)
  p("on_alloc", ...)
end

function stream_prototype:read_start(on_read)
  uv_assert(C.uv_read_start(FFI.cast("uv_stream_t*", self), on_alloc, on_read))
end

function stream_prototype:write(strings, write_cb)
  local bufs, length
  if type(strings) == "table" then
    length = #strings
    bufs = FFI.new("uv_buf_t[" .. length .. "]")
    for i = 1, length do
      local string = strings[i]
      local buf = bufs[i - 1]
      buf.base = FFI.cast("char*", string)
      buf.len = #string
    end
  else
    length = 1
    bufs = FFI.new("uv_buf_t[1]")
    local string = strings
    bufs[0].base = FFI.cast("char*", string)
    bufs[0].len = #string
  end
  p({bufs=bufs})

  local ref = FFI.new("uv_write_t")

  uv_assert(C.uv_write(FFI.cast("uv_write_t*", ref), FFI.cast("uv_stream_t*", self), bufs, length, function (req, status)
    uv_assert(status)
    write_cb(req, status)
  end))
end

local tcp_prototype = setmetatable({}, {__index=stream_prototype})
function tcp_prototype:bind(port, host)
  local address = C.uv_ip4_addr(host or "0.0.0.0", port)
  uv_assert(C.uv_tcp_bind(FFI.cast("uv_tcp_t*", self), address))
end
function tcp_prototype:init()
  C.uv_tcp_init(C.uv_default_loop(), self)
end

local Tcp = FFI.metatype("uv_tcp_t", {
  __index = tcp_prototype
})

local function new_tcp()
  local handle = Tcp()
  handle:init()
  return handle
end

--------------------------------------------------------------------------------

local server = new_tcp()

server:bind(8080)

server:listen(function(server_handle, status)
  p("on_connection", {server_handle=server_handle, status=status})

  local client = new_tcp()

  server:accept(client)
  p("accepted", {server=server,client=client})

  client:read_start(function (...)
    p("on_read", ...)
  end)

--[[
  p("writing...")
  client:write({"HTTP/1.1 200 Success\r\n",
                "Server: Luvit FFI\r\n",
                "Content-Length: 0\r\n",
                "\r\n"}, function (req, status)
    p("written", {req=req,status=status})

    p("closing...")
    client:close(function (handle)
      p("closed", {handle=handle})
    end)

  end)
]]

end)

print("server listening at http://localhost:8080/")

