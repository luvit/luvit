#ifndef LUV_TCP
#define LUV_TCP

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_stream.h"

int luv_new_tcp (lua_State* L);
int luv_tcp_bind (lua_State* L);
int luv_tcp_bind6(lua_State* L);
int luv_tcp_nodelay(lua_State* L);
int luv_tcp_getsockname(lua_State* L);
int luv_tcp_getpeername(lua_State* L);
int luv_tcp_connect(lua_State* L);
int luv_tcp_connect6(lua_State* L);

#endif
