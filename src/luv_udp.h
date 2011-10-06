#ifndef LUV_UDP
#define LUV_UDP

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_handle.h"

int luv_new_udp (lua_State* L);
int luv_udp_init(lua_State* L);
int luv_udp_bind(lua_State* L);
int luv_udp_bind6(lua_State* L);
int luv_udp_getsockname(lua_State* L);
int luv_udp_send(lua_State* L);
int luv_udp_send6(lua_State* L);
int luv_udp_recv_start(lua_State* L);
int luv_udp_recv_stop(lua_State* L);

#endif
