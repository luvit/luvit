#ifndef LUV_TCP
#define LUV_TCP

#include "lua.h"
#include "lauxlib.h"
#include "uv.h"
#include "utils.h"
#include "luv_stream.h"

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

int luv_new_tcp (lua_State* L);
int luv_tcp_bind (lua_State* L);
int luv_tcp_bind6(lua_State* L);
int luv_tcp_nodelay(lua_State* L);
int luv_tcp_getsockname(lua_State* L);
int luv_tcp_getpeername(lua_State* L);
int luv_tcp_connect(lua_State* L);
int luv_tcp_connect6(lua_State* L);

#endif
