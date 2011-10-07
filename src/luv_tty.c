#include <stdlib.h>
#include <assert.h>

#include "luv_tty.h"

int luv_new_tty (lua_State* L) {
  int before = lua_gettop(L);

  //uv_tty_t* handle = (uv_tty_t*)
  lua_newuserdata(L, sizeof(uv_tty_t));

  // Set metatable for type
  luaL_getmetatable(L, "luv_pipe");
  lua_setmetatable(L, -2);

  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  assert(lua_gettop(L) == before + 1);

  return 1;
}

int luv_tty_set_mode(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_tty_set_mode");
  return 0;
}

int luv_tty_get_winsize(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_tty_get_winsize");
  return 0;
}

