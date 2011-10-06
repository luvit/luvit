#ifndef LUV_HANDLE
#define LUV_HANDLE

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"

typedef struct {
  lua_State* L;
  int r;
  uv_connect_t connect_req;
} luv_connect_ref_t;

// Registers a callback, callback_index can't be negative
void luv_register_event(lua_State* L, int userdata_index, const char* name, int callback_index);

// Emit an event of the current userdata consuming nargs
// Assumes userdata is right below args
void luv_emit_event(lua_State* L, const char* name, int nargs);

void luv_after_connect(uv_connect_t* req, int status);

uv_buf_t luv_on_alloc(uv_handle_t* handle, size_t suggested_size);

void luv_on_close(uv_handle_t* handle);

int luv_close (lua_State* L);
int luv_set_handler(lua_State* L);

#endif
