#include <stdlib.h>
#include <assert.h>

#include "luv_tcp.h"

int luv_new_udp (lua_State* L) {
  int before = lua_gettop(L);

  //uv_udp_t* handle = (uv_udp_t*)
  lua_newuserdata(L, sizeof(uv_udp_t));

  // Set metatable for type
  luaL_getmetatable(L, "luv_udp");
  lua_setmetatable(L, -2);

  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  assert(lua_gettop(L) == before + 1);

  return 1;
}

int luv_udp_init(lua_State* L) {
  error(L, "TODO: Implement luv_udp_init");
  return 0;
}

int luv_udp_bind(lua_State* L) {
  error(L, "TODO: Implement luv_udp_bind");
  return 0;
}

int luv_udp_bind6(lua_State* L) {
  error(L, "TODO: Implement luv_udp_bind6");
  return 0;
}

int luv_udp_getsockname(lua_State* L) {
  error(L, "TODO: Implement luv_udp_getsockname");
  return 0;
}

int luv_udp_send(lua_State* L) {
  error(L, "TODO: Implement luv_udp_send");
  return 0;
}

int luv_udp_send6(lua_State* L) {
  error(L, "TODO: Implement luv_udp_send6");
  return 0;
}

int luv_udp_recv_start(lua_State* L) {
  error(L, "TODO: Implement luv_udp_recv_start");
  return 0;
}

int luv_udp_recv_stop(lua_State* L) {
  error(L, "TODO: Implement luv_udp_recv_stop");
  return 0;
}

