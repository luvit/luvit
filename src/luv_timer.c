#include <stdlib.h>
#include <assert.h>

#include "luv_tcp.h"

int luv_new_timer (lua_State* L) {
  int before = lua_gettop(L);

  //uv_tmer_t* handle = (uv_timer_t*)
  lua_newuserdata(L, sizeof(uv_timer_t));

  // Set metatable for type
  luaL_getmetatable(L, "luv_timer");
  lua_setmetatable(L, -2);

  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  assert(lua_gettop(L) == before + 1);

  return 1;
}

int luv_timer_start(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_timer_start");
  return 0;
}

int luv_timer_stop(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_timer_stop");
  return 0;
}

int luv_timer_again(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_timer_again");
  return 0;
}

int luv_timer_set_repeat(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_timer_set_repeat");
  return 0;
}

