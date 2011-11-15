-- This is an experiment to see how fast ffi calls are and how ugly/pretty
-- the bindings are.

local FFI = require('ffi')
local Fs = require('fs')
local Path = require('path')

-- Read the combined libuv and http_parser header file
FFI.cdef(Fs.read_file_sync(Path.join(__dirname, "ffi_uv.h")))

local C = FFI.C

local server = FFI.new("uv_stream_t")
local settings = FFI.new("http_parser_settings")
local refbuf = FFI.new("uv_buf_t")

local RESPONSE = 
  "HTTP/1.1 200 OK\r\n" ..
  "Content-Type: text/plain\r\n" ..
  "Content-Length: 12\r\n" ..
  "\r\n"

FFI.cdef([[
typedef struct {
  uv_tcp_t handle;
  http_parser parser;
  uv_write_t write_req;
} client_t;
]])

local function on_close(handle)
  p("on_close", handle)
  -- TODO: free the handle
end

local function on_alloc(handle, suggested_size)
  p("on_alloc", handle, suggested_size)
--uv_buf_t on_alloc(uv_handle_t* handle, size_t suggested_size) {
--  uv_buf_t buf;
--  buf.base = malloc(suggested_size);
--  buf.len = suggested_size;
--  return buf;
end

local function on_read(stream, nread, buf)
  p("on_read", stream, nread, buf)
--void on_read(uv_stream_t* stream, ssize_t nread, uv_buf_t buf) {
--  client_t* client = stream->data;

--  size_t parsed;

--  if (nread >= 0) {
--    parsed = http_parser_execute(&client->parser, &settings, buf.base, nread);

--    if (parsed < nread) {
--      uv_close((uv_handle_t*)stream, on_close);
--      fprintf(stderr, "parse error\n");
--    }

--  } else {
--    uv_err_t err = uv_last_error(uv_default_loop());
--    if (err.code == UV_EOF) {
--      uv_close((uv_handle_t*)stream, on_close);
--    } else {
--      fprintf(stderr, "read: %s\n", uv_strerror(err));
--    }
--  }

--  free(buf.base);
end

local function on_connection(server_handle, status)
  p("on_connection", server_handle, status)
--  assert(server_handle == &server);
--  // printf("connected\n");

--  client_t* client = malloc(sizeof(client_t));
--  uv_tcp_init(uv_default_loop(), &client->handle);
--  client->handle.data = client;
--  client->parser.data = client;

--  int r = uv_accept(&server, (uv_stream_t*)&client->handle);

--  if (r) {
--    uv_err_t err = uv_last_error(uv_default_loop());
--    fprintf(stderr, "accept: %s\n", uv_strerror(err));
--    exit(-1);
--  }

--  http_parser_init(&client->parser, HTTP_REQUEST);

--  uv_read_start((uv_stream_t*)&client->handle, on_alloc, on_read);

end

local function after_write(req, status)
  p("after_write", req, status)
--  //printf("after_write\n");
--  uv_close((uv_handle_t*)req->handle, on_close);
end

local function on_headers_complete(parser)
  p("on_headers_complete", parser)
--  client_t* client = parser->data;

--  // printf("http message!\n");

--  uv_write(&client->write_req, (uv_stream_t*)&client->handle, &refbuf, 1, after_write);

--  return 1;
end

refbuf.base = FFI.new("char[" .. (#RESPONSE + 1) .. "]")
FFI.copy(refbuf.base, RESPONSE)

refbuf.len = #RESPONSE

settings.on_headers_complete = on_headers_complete

C.uv_tcp_init(C.uv_default_loop(), server)
--  uv_tcp_init(uv_default_loop(), (uv_tcp_t*)&server);
--  struct sockaddr_in address = uv_ip4_addr("0.0.0.0", 8080);
--  int r = uv_tcp_bind((uv_tcp_t*)&server, address);

--  if (r) {
--    uv_err_t err = uv_last_error(uv_default_loop());
--    fprintf(stderr, "bind: %s\n", uv_strerror(err));
--    return -1;
--  }

--  r = uv_listen(&server, 128, on_connection);

--  if (r) {
--    uv_err_t err = uv_last_error(uv_default_loop());
--    fprintf(stderr, "listen: %s\n", uv_strerror(err));
--    return -1;
--  }

--  // Block in the main loop
--  uv_run(uv_default_loop());

--  return 0;
--}


p({server=server,settings=settings,refbuf=refbuf})

