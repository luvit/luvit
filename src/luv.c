
#include "luv.h"

/*static int uv_sin (lua_State *L) {*/
/*  lua_pushnumber(L, sin(luaL_checknumber(L, 1)));*/
/*  return 1;*/
/*}*/

static const luaL_reg uvlib[] = {
/*  {"sin", uv_sin},*/
  {NULL, NULL}
};

/*
** Open uv library
*/
LUALIB_API int luaopen_uv (lua_State *L) {
  luaL_register(L, "uv", uvlib);
  return 1;
}

