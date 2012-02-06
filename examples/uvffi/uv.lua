-- This is an experiment to see how fast ffi calls are and how ugly/pretty
-- the bindings are.

local ffi = require('ffi')
local fs = require('fs')
local path = require('path')

-- Read the combined libuv and http_parser header file
ffi.cdef(fs.readFileSync(path.join(__dirname, "ffi_uv.h")))

-- Use the built-in alloc_cb function
ffi.cdef("uv_buf_t luv_on_alloc(uv_handle_t* handle, size_t suggested_size);")

local C = ffi.C

--------------------------------------------------------------------------------
-- minimal libuv bindings using ffi

local function uv_assert(r)
  if r == -1 then
    local err = C.uv_last_error(C.uv_default_loop())
    local name = ffi.string(C.uv_err_name(err))
    local message = ffi.string(C.uv_strerror(err))
    error(name .. ": " .. message)
  end
end

local handle_prototype = {}

function handle_prototype:close(close_cb)
  C.uv_close(ffi.cast("uv_handle_t*", self), close_cb)
end

local stream_prototype = setmetatable({}, {__index=handle_prototype})

function stream_prototype:listen(onConnection)
  uv_assert(C.uv_listen(ffi.cast("uv_stream_t*", self), 128, onConnection))
end

function stream_prototype:accept(client)
  uv_assert(C.uv_accept(ffi.cast("uv_stream_t*", self), ffi.cast("uv_stream_t*", client)))
end

function stream_prototype:readStart(onRead)
  uv_assert(C.uv_read_start(ffi.cast("uv_stream_t*", self), C.luv_on_alloc, onRead))
end

function stream_prototype:write(strings, writeCb)
  local bufs, length
  if type(strings) == "table" then
    length = #strings
    bufs = ffi.new("uv_buf_t[" .. length .. "]")
    for i = 1, length do
      local string = strings[i]
      local buf = bufs[i - 1]
      buf.base = ffi.cast("char*", string)
      buf.len = #string
    end
  else
    length = 1
    bufs = ffi.new("uv_buf_t[1]")
    local string = strings
    bufs[0].base = ffi.cast("char*", string)
    bufs[0].len = #string
  end
  p({bufs=bufs})

  local ref = ffi.new("uv_write_t")

  uv_assert(C.uv_write(ffi.cast("uv_write_t*", ref), ffi.cast("uv_stream_t*", self), bufs, length, function (req, status)
    uv_assert(status)
    writeCb(req, status)
  end))
end

local tcp_prototype = setmetatable({}, {__index=stream_prototype})
function tcp_prototype:bind(port, host)
  local address = C.uv_ip4_addr(host or "0.0.0.0", port)
  uv_assert(C.uv_tcp_bind(ffi.cast("uv_tcp_t*", self), address))
end
function tcp_prototype:init()
  C.uv_tcp_init(C.uv_default_loop(), self)
end

local Tcp = ffi.metatype("uv_tcp_t", {
  __index = tcp_prototype
})

local function newTcp()
  local handle = Tcp()
  handle:init()
  return handle
end

--------------------------------------------------------------------------------

local server = newTcp()

server:bind(8080)

server:listen(function(server_handle, status)
  p("on_connection", {server_handle=server_handle, status=status})

  local client = newTcp()

  server:accept(client)
  p("accepted", {server=server,client=client})

  client:readStart(function (...)
    p("on_read", ...)
  end)

--  p("writing...")
--  client:write({"HTTP/1.1 200 Success\r\n",
--                "Server: Luvit ffi\r\n",
--                "Content-Length: 0\r\n",
--                "\r\n"}, function (req, status)
--    p("written", {req=req,status=status})

--    p("closing...")
--    client:close(function (handle)
--      p("closed", {handle=handle})
--    end)

--  end)

end)

print("server listening at http://localhost:8080/")

