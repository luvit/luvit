#ifndef LUV_UDP
#define LUV_UDP

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_handle.h"

// Temporary hack: libuv should provide uv_inet_pton and uv_inet_ntop.
#if defined(__MINGW32__) || defined(_MSC_VER)
#   include <inet_net_pton.h>
#   include <inet_ntop.h>
# define uv_inet_pton ares_inet_pton
# define uv_inet_ntop ares_inet_ntop

#else // __POSIX__
# include <arpa/inet.h>
# define uv_inet_pton inet_pton
# define uv_inet_ntop inet_ntop
#endif


int luv_new_udp (lua_State* L);
int luv_udp_bind(lua_State* L);
int luv_udp_bind6(lua_State* L);
int luv_udp_set_membership(lua_State* L);
int luv_udp_getsockname(lua_State* L);
int luv_udp_send(lua_State* L);
int luv_udp_send6(lua_State* L);
int luv_udp_recv_start(lua_State* L);
int luv_udp_recv_stop(lua_State* L);

#endif
