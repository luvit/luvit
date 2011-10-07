#include <stdlib.h>
#include <assert.h>

#include "luv_pipe.h"

int luv_new_pipe (lua_State* L) {
  int before = lua_gettop(L);

  //uv_pipe_t* handle = (uv_pipe_t*)
  lua_newuserdata(L, sizeof(uv_pipe_t));

  // Set metatable for type
  luaL_getmetatable(L, "luv_pipe");
  lua_setmetatable(L, -2);

  // Create a local environment for storing stuff
  lua_newtable(L);
  lua_setfenv (L, -2);

  assert(lua_gettop(L) == before + 1);

  return 1;
}

int luv_pipe_open(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_pipe_open");
  return 0;
}

int luv_pipe_bind(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_pipe_bind");
  return 0;
}

int luv_pipe_connect(lua_State* L) {
  return luaL_error(L, "TODO: Implement luv_pipe_connect");
  return 0;
}


