#ifndef LUV_STREAM
#define LUV_STREAM

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_handle.h"

typedef struct {
  lua_State* L;
  int r;
  uv_write_t write_req;
  uv_buf_t refbuf;
} luv_write_ref_t;

typedef struct {
  lua_State* L;
  int r;
  uv_shutdown_t shutdown_req;
} luv_shutdown_ref_t;

void luv_on_connection(uv_stream_t* handle, int status);
void luv_on_read(uv_stream_t* handle, ssize_t nread, uv_buf_t buf);
void luv_after_shutdown(uv_shutdown_t* req, int status);
void luv_after_write(uv_write_t* req, int status);

int luv_shutdown(lua_State* L);
int luv_listen (lua_State* L);
int luv_accept (lua_State* L);
int luv_read_start (lua_State* L);
int luv_read_start2(lua_State* L);
int luv_read_stop(lua_State* L);
int luv_write (lua_State* L);
int luv_write2(lua_State* L);

#endif
